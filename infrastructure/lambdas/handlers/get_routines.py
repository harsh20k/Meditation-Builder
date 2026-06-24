"""GET /routines — browse public community routines."""

from __future__ import annotations

import hashlib
import json
import logging
from typing import Any

from boto3.dynamodb.conditions import Attr

from shared import auth, dynamo, redis_client, response

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def _routine_summary(item: dict[str, Any]) -> dict[str, Any]:
    tags = item.get("tags") or []
    if isinstance(tags, set):
        tags = sorted(tags)
    routine_id = item["routineId"]
    return {
        "routineId": routine_id,
        "name": item.get("name", ""),
        "description": item.get("description", ""),
        "tags": tags,
        "durationSeconds": int(item.get("durationSeconds", 0)),
        "authorName": item.get("authorName", ""),
        "likeCount": redis_client.effective_like_count(
            routine_id, int(item.get("likeCount", 0))
        ),
        "importCount": int(item.get("importCount", 0)),
        "publishedAt": item.get("publishedAt"),
    }


def _apply_pending_likes(body: dict[str, Any]) -> dict[str, Any]:
    """Patch browse payloads so cached pages reflect unflushed like deltas."""
    for routine in body.get("routines", []):
        routine_id = routine["routineId"]
        routine["likeCount"] = redis_client.effective_like_count(
            routine_id, int(routine.get("likeCount", 0))
        )
    return body


def _cache_key(params: dict[str, Any]) -> str:
    raw = json.dumps(params, sort_keys=True)
    return f"browse:{hashlib.sha256(raw.encode()).hexdigest()}"


def handler(event: dict[str, Any], context: object) -> dict[str, Any]:
    request_id = response.get_request_id(event)
    try:
        qs = event.get("queryStringParameters") or {}
        page_size = min(int(qs.get("pageSize", 20)), 50)
        if page_size < 1:
            return response.error(
                400, "INVALID_PARAMETER", "pageSize must be >= 1", request_id=request_id
            )
        sort = qs.get("sort", "newest")
        if sort not in ("newest", "popular"):
            return response.error(
                400, "INVALID_PARAMETER", f"Unknown sort value: {sort}", request_id=request_id
            )
        tag = qs.get("tag")
        min_duration = int(qs["minDuration"]) if qs.get("minDuration") else None
        max_duration = int(qs["maxDuration"]) if qs.get("maxDuration") else None
        next_token = qs.get("nextToken")

        cache_params = {
            "pageSize": page_size,
            "sort": sort,
            "tag": tag,
            "minDuration": min_duration,
            "maxDuration": max_duration,
            "nextToken": next_token,
        }
        cache_key = _cache_key(cache_params)
        if not next_token:
            cached = redis_client.cache_get(cache_key)
            if cached:
                return response.success(
                    200,
                    _apply_pending_likes(cached),
                    request_id=request_id,
                    headers={"Cache-Control": "max-age=30, s-maxage=30"},
                )

        exclusive_start_key = None
        if next_token:
            try:
                exclusive_start_key = dynamo.decode_token(next_token)
            except ValueError:
                return response.error(
                    400, "INVALID_PARAMETER", "Invalid nextToken", request_id=request_id
                )

        filter_expr = None
        if min_duration is not None or max_duration is not None:
            parts = []
            if min_duration is not None:
                parts.append(Attr("durationSeconds").gte(min_duration))
            if max_duration is not None:
                parts.append(Attr("durationSeconds").lte(max_duration))
            filter_expr = parts[0]
            for part in parts[1:]:
                filter_expr = filter_expr & part

        if tag:
            items, last_key = dynamo.query_tag(
                tag.lower(),
                limit=page_size,
                exclusive_start_key=exclusive_start_key,
            )
        else:
            items, last_key = dynamo.query_gsi1(
                limit=page_size,
                exclusive_start_key=exclusive_start_key,
                scan_forward=False,
                filter_expression=filter_expr,
            )

        routines = [_routine_summary(i) for i in items]
        if sort == "popular":
            routines.sort(key=lambda r: r["likeCount"], reverse=True)

        body = {
            "routines": routines,
            "nextToken": dynamo.encode_token(last_key),
            "count": len(routines),
        }
        if not next_token:
            redis_client.cache_set(cache_key, body, 60)

        return response.success(
            200,
            _apply_pending_likes(body),
            request_id=request_id,
            headers={"Cache-Control": "max-age=30, s-maxage=30"},
        )
    except Exception:
        logger.exception("get_routines failed requestId=%s sub=%s", request_id, auth.get_sub(event))
        return response.error(
            500, "INTERNAL_ERROR", "Unexpected error fetching routines.", request_id=request_id
        )
