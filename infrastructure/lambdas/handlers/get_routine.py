"""GET /routines/{id} — retrieve full routine detail."""

from __future__ import annotations

import json
import logging
import re
from typing import Any

from shared import auth, dynamo, redis_client, response

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

UUID_RE = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$",
    re.I,
)


def _parse_blocks(raw: Any) -> list[dict[str, Any]]:
    if isinstance(raw, str):
        return json.loads(raw)
    return raw or []


def _to_response(item: dict[str, Any], *, sub: str | None) -> dict[str, Any]:
    tags = item.get("tags") or []
    if isinstance(tags, set):
        tags = sorted(tags)
    audio = item.get("audioAssetKeys") or []
    if isinstance(audio, set):
        audio = sorted(audio)
    payload = {
        "routineId": item["routineId"],
        "name": item.get("name", ""),
        "description": item.get("description", ""),
        "tags": tags,
        "durationSeconds": int(item.get("durationSeconds", 0)),
        "blocks": _parse_blocks(item.get("blocks")),
        "authorName": item.get("authorName", ""),
        "authorSub": item.get("authorSub", ""),
        "likeCount": int(item.get("likeCount", 0)),
        "importCount": int(item.get("importCount", 0)),
        "audioAssetKeys": audio,
        "publishedAt": item.get("publishedAt"),
        "updatedAt": item.get("updatedAt"),
        "isLikedByMe": None,
        "isImportedByMe": None,
    }
    if sub:
        like = dynamo.get_item(f"USER#{sub}", f"LIKE#{item['routineId']}")
        imp = dynamo.get_item(f"USER#{sub}", f"IMPORT#{item['routineId']}")
        payload["isLikedByMe"] = like is not None
        payload["isImportedByMe"] = imp is not None
    return payload


def handler(event: dict[str, Any], context: object) -> dict[str, Any]:
    request_id = response.get_request_id(event)
    sub = auth.get_sub(event)
    try:
        routine_id = (event.get("pathParameters") or {}).get("id", "")
        if not UUID_RE.match(routine_id):
            return response.error(400, "INVALID_ID", "Invalid routine id.", request_id=request_id)

        cache_key = f"routine:{routine_id}"
        cached = redis_client.cache_get(cache_key)
        item = cached
        if not item:
            item = dynamo.get_item(f"ROUTINE#{routine_id}", "METADATA")
            if item and item.get("isPublic"):
                redis_client.cache_set(cache_key, item, 300)

        if not item or not item.get("isPublic"):
            return response.error(
                404, "ROUTINE_NOT_FOUND", "No routine with the given id.", request_id=request_id
            )

        body = _to_response(item, sub=sub)
        return response.success(
            200,
            body,
            request_id=request_id,
            headers={"Cache-Control": "max-age=300, s-maxage=300"},
        )
    except Exception:
        logger.exception("get_routine failed requestId=%s", request_id)
        return response.error(
            500, "INTERNAL_ERROR", "Failed to fetch routine.", request_id=request_id
        )
