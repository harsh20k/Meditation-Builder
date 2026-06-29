"""POST /routines/{id}/import — import a community routine."""

from __future__ import annotations

import json
import logging
import re
from datetime import datetime, timezone
from typing import Any

from shared import auth, dynamo, response

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

UUID_RE = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$",
    re.I,
)


def _routine_payload(item: dict[str, Any]) -> dict[str, Any]:
    tags = item.get("tags") or []
    if isinstance(tags, set):
        tags = sorted(tags)
    audio = item.get("audioAssetKeys") or []
    if isinstance(audio, set):
        audio = sorted(audio)
    blocks = item.get("blocks")
    if isinstance(blocks, str):
        blocks = json.loads(blocks)
    return {
        "routineId": item["routineId"],
        "name": item.get("name", ""),
        "blocks": blocks or [],
        "tags": tags,
        "durationSeconds": int(item.get("durationSeconds", 0)),
        "audioAssetKeys": audio,
    }


def handler(event: dict[str, Any], context: object) -> dict[str, Any]:
    request_id = response.get_request_id(event)
    sub, err_resp = auth.authenticate(event, request_id)
    if err_resp:
        return err_resp

    try:
        routine_id = (event.get("pathParameters") or {}).get("id", "")
        if not UUID_RE.match(routine_id):
            return response.error(400, "INVALID_ID", "Invalid routine id.", request_id=request_id)

        routine = dynamo.get_item(f"ROUTINE#{routine_id}", "METADATA")
        if not routine or not routine.get("isPublic"):
            return response.error(
                404, "ROUTINE_NOT_FOUND", "No routine with the given id.", request_id=request_id
            )

        existing = dynamo.get_item(f"USER#{sub}", f"IMPORT#{routine_id}")
        now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        already_imported = existing is not None

        if not already_imported:
            import_item = {
                "PK": f"USER#{sub}",
                "SK": f"IMPORT#{routine_id}",
                "EntityType": "ImportRecord",
                "routineId": routine_id,
                "importedAt": now,
            }
            try:
                dynamo.get_table().put_item(
                    Item=dynamo.to_dynamo(import_item),
                    ConditionExpression="attribute_not_exists(SK)",
                )
                dynamo.get_table().update_item(
                    Key={"PK": f"ROUTINE#{routine_id}", "SK": "METADATA"},
                    UpdateExpression="ADD importCount :one",
                    ExpressionAttributeValues={":one": 1},
                )
            except Exception as exc:
                if not dynamo.is_conditional_check_failed(exc):
                    raise
                already_imported = True
                now = existing.get("importedAt", now) if existing else now

        body = {
            "routineId": routine_id,
            "routine": _routine_payload(routine),
            "importedAt": existing.get("importedAt", now) if existing else now,
        }
        if already_imported:
            body["alreadyImported"] = True
        return response.success(200, body, request_id=request_id)
    except Exception:
        logger.exception("import_routine failed requestId=%s sub=%s", request_id, sub)
        return response.error(
            500, "INTERNAL_ERROR", "Failed to import routine.", request_id=request_id
        )
