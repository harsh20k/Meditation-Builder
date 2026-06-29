"""GET /recommendations — personalized routine recommendations."""

from __future__ import annotations

import logging
import math
from collections import Counter
from datetime import datetime, timedelta, timezone
from typing import Any

from shared import auth, dynamo, redis_client, response

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

CACHE_TTL = 3600


def _aggregate_tags(activities: list[dict[str, Any]]) -> Counter[str]:
    counter: Counter[str] = Counter()
    for activity in activities:
        tags = activity.get("tagsEngaged") or []
        if isinstance(tags, set):
            tags = list(tags)
        for tag in tags:
            counter[str(tag).lower()] += 1
    return counter


def _score_routine(routine: dict[str, Any], tag_weights: Counter[str]) -> float:
    tags = routine.get("tags") or []
    if isinstance(tags, set):
        tags = list(tags)
    if not tags or not tag_weights:
        return float(routine.get("likeCount", 0)) / 100.0
    overlap = sum(tag_weights.get(str(t).lower(), 0) for t in tags)
    max_possible = sum(tag_weights.values()) or 1
    popularity = math.log1p(int(routine.get("likeCount", 0))) / 10.0
    return min(1.0, (overlap / max_possible) * 0.8 + popularity * 0.2)


def _summarize(routine: dict[str, Any], score: float) -> dict[str, Any]:
    tags = routine.get("tags") or []
    if isinstance(tags, set):
        tags = sorted(tags)
    return {
        "routineId": routine["routineId"],
        "name": routine.get("name", ""),
        "description": routine.get("description", ""),
        "tags": tags,
        "durationSeconds": int(routine.get("durationSeconds", 0)),
        "authorName": routine.get("authorName", ""),
        "likeCount": int(routine.get("likeCount", 0)),
        "importCount": int(routine.get("importCount", 0)),
        "score": round(score, 2),
    }


def _fallback_routines(limit: int) -> list[dict[str, Any]]:
    items, _ = dynamo.query_gsi1(limit=limit, scan_forward=False)
    return [_summarize(i, 0.5) for i in items]


def handler(event: dict[str, Any], context: object) -> dict[str, Any]:
    request_id = response.get_request_id(event)
    sub, err_resp = auth.authenticate(event, request_id)
    if err_resp:
        return err_resp

    try:
        qs = event.get("queryStringParameters") or {}
        limit = min(int(qs.get("limit", 10)), 20)
        cache_key = f"recommendations:{sub}"
        cached = redis_client.cache_get(cache_key)
        now = datetime.now(timezone.utc)

        if cached:
            cached_at = datetime.fromisoformat(cached["cachedAt"].replace("Z", "+00:00"))
            expires_at = cached_at + timedelta(seconds=CACHE_TTL)
            if now < expires_at:
                cached["cacheHit"] = True
                return response.success(200, cached, request_id=request_id)

        activities = dynamo.query_user_activity(sub, limit=50)
        tag_weights = _aggregate_tags(activities)
        browse_items, _ = dynamo.query_gsi1(limit=50, scan_forward=False)

        scored = [
            (item, _score_routine(item, tag_weights))
            for item in browse_items
            if item.get("authorSub") != sub
        ]
        scored.sort(key=lambda pair: pair[1], reverse=True)
        recommendations = [_summarize(item, score) for item, score in scored[:limit]]

        if not recommendations:
            recommendations = _fallback_routines(limit)

        cached_at = now.strftime("%Y-%m-%dT%H:%M:%SZ")
        expires_at = (now + timedelta(seconds=CACHE_TTL)).strftime("%Y-%m-%dT%H:%M:%SZ")
        body = {
            "recommendations": recommendations,
            "cacheHit": False,
            "cachedAt": cached_at,
            "expiresAt": expires_at,
        }
        redis_client.cache_set(cache_key, body, CACHE_TTL)
        return response.success(200, body, request_id=request_id)
    except Exception:
        logger.exception("get_recommendations failed requestId=%s sub=%s", request_id, sub)
        try:
            limit = min(int((event.get("queryStringParameters") or {}).get("limit", 10)), 20)
            fallback = _fallback_routines(limit)
            return response.success(
                200,
                {"recommendations": fallback, "cacheHit": False, "fallback": True},
                request_id=request_id,
            )
        except Exception:
            return response.error(
                500, "INTERNAL_ERROR", "Failed to compute recommendations.", request_id=request_id
            )
