"""SQS-triggered Bedrock tagging for published routines."""

from __future__ import annotations

import json
import logging
import os
import re
from typing import Any

import boto3

from shared import dynamo, typesense_client

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

_bedrock = None
MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "anthropic.claude-3-haiku-20240307-v1:0")


def _bedrock():
    global _bedrock
    if _bedrock is None:
        _bedrock = boto3.client("bedrock-runtime")
    return _bedrock


def _parse_tags_response(text: str) -> tuple[list[str], str]:
    try:
        data = json.loads(text)
        tags = [str(t).lower() for t in data.get("tags", [])][:5]
        description = str(data.get("description", "")).strip()
        return tags, description
    except json.JSONDecodeError:
        tags = re.findall(r'"tags"\s*:\s*\[(.*?)\]', text, re.S)
        description = text.strip()[:500]
        fallback_tags = []
        if tags:
            fallback_tags = [
                t.strip().strip('"').lower()
                for t in tags[0].split(",")
                if t.strip()
            ][:5]
        return fallback_tags, description


def _invoke_bedrock(blocks: list[dict[str, Any]], user_description: str) -> tuple[list[str], str]:
    prompt = (
        "Generate JSON with keys tags (array of up to 5 lowercase meditation tags) "
        "and description (1-2 sentence summary) for this routine.\n"
        f"User description: {user_description}\n"
        f"Blocks: {json.dumps(blocks)}"
    )
    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 300,
        "messages": [{"role": "user", "content": prompt}],
    }
    resp = _bedrock().invoke_model(
        modelId=MODEL_ID,
        contentType="application/json",
        accept="application/json",
        body=json.dumps(body),
    )
    payload = json.loads(resp["body"].read())
    text = payload["content"][0]["text"]
    return _parse_tags_response(text)


def _write_tag_fanout(routine: dict[str, Any], tags: list[str]) -> None:
    published_at = routine["publishedAt"]
    routine_id = routine["routineId"]
    for tag in tags:
        dynamo.put_item(
            {
                "PK": f"TAG#{tag}",
                "SK": f"{published_at}#{routine_id}",
                "EntityType": "RoutineTagIndex",
                "routineId": routine_id,
                "name": routine.get("name", ""),
                "authorName": routine.get("authorName", ""),
                "durationSeconds": routine.get("durationSeconds", 0),
                "likeCount": routine.get("likeCount", 0),
            }
        )


def handler(event: dict[str, Any], context: object) -> dict[str, Any]:
    failures: list[dict[str, str]] = []
    for record in event.get("Records", []):
        message_id = record.get("messageId", "")
        try:
            body = json.loads(record["body"])
            routine_id = body["routineId"]
            routine = dynamo.get_item(f"ROUTINE#{routine_id}", "METADATA")
            if not routine:
                continue

            tags, description = _invoke_bedrock(
                body.get("blocks", []),
                body.get("userDescription", ""),
            )
            updated = dynamo.update_item(
                f"ROUTINE#{routine_id}",
                "METADATA",
                updates={
                    "tags": set(tags),
                    "description": description or routine.get("description", ""),
                    "taggingStatus": "complete",
                    "updatedAt": routine.get("updatedAt"),
                },
            )
            _write_tag_fanout({**routine, **updated, "tags": tags}, tags)
            try:
                typesense_client.upsert_routine({**routine, **updated, "tags": tags})
            except Exception:
                logger.warning("Typesense upsert failed for %s", routine_id, exc_info=True)
        except Exception:
            logger.exception("bedrock_tagger failed messageId=%s", message_id)
            failures.append({"itemIdentifier": message_id})
    return {"batchItemFailures": failures}
