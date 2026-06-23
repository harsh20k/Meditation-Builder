"""POST /activity — sync completed session activity."""

from __future__ import annotations

import base64
import json
import logging
from datetime import datetime, timedelta, timezone
from typing import Any

from shared import auth, dynamo, redis_client, response

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

VALID_BLOCK_TYPES = {"timer", "bell", "music"}


def _validate_body(body: dict[str, Any]) -> str | None:
    duration = body.get("sessionDurationSeconds")
    if not isinstance(duration, int) or duration < 1:
        return "sessionDurationSeconds must be >= 1"
    routines = body.get("routinesPlayed")
    if not isinstance(routines, list) or not (1 <= len(routines) <= 20):
        return "routinesPlayed must contain 1-20 routineIds"
    tags = body.get("tagsEngaged") or []
    if not isinstance(tags, list) or len(tags) > 20:
        return "tagsEngaged max 20 items"
    block_types = body.get("blockTypes") or []
    if not isinstance(block_types, list):
        return "blockTypes must be an array"
    for bt in block_types:
        if bt not in VALID_BLOCK_TYPES:
            return f"invalid block type: {bt}"
    return None


def handler(event: dict[str, Any], context: object) -> dict[str, Any]:
    request_id = response.get_request_id(event)
    sub = auth.get_sub(event)
    if not sub:
        return response.error(401, "UNAUTHORIZED", "Authentication required.", request_id=request_id)

    try:
        raw = event.get("body") or "{}"
        if event.get("isBase64Encoded"):
            raw = base64.b64decode(raw).decode()
        body = json.loads(raw)
        err = _validate_body(body)
        if err:
            return response.error(400, "INVALID_BODY", err, request_id=request_id)

        now = datetime.now(timezone.utc)
        created_at = now.strftime("%Y-%m-%dT%H:%M:%SZ")
        ttl = int((now + timedelta(days=60)).timestamp())

        item = {
            "PK": f"USER#{sub}",
            "SK": f"ACTIVITY#{created_at}",
            "EntityType": "UserActivity",
            "sessionDurationSeconds": body["sessionDurationSeconds"],
            "routinesPlayed": set(body["routinesPlayed"]),
            "tagsEngaged": set(t.lower() for t in (body.get("tagsEngaged") or [])),
            "blockTypes": set(body.get("blockTypes") or []),
            "createdAt": created_at,
            "ttl": ttl,
        }
        dynamo.put_item(item)
        redis_client.cache_delete(f"recommendations:{sub}")

        return response.success(202, {"accepted": True}, request_id=request_id)
    except json.JSONDecodeError:
        return response.error(400, "INVALID_BODY", "Invalid JSON body.", request_id=request_id)
    except Exception:
        logger.exception("post_activity failed requestId=%s sub=%s", request_id, sub)
        return response.error(
            500, "INTERNAL_ERROR", "Failed to record activity.", request_id=request_id
        )
