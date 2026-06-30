"""POST /routines — publish a routine to the community library."""

from __future__ import annotations

import json
import logging
import os
import uuid
from datetime import datetime, timezone
from typing import Any

import boto3

from shared import auth, dynamo, response

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

VALID_BLOCK_TYPES = {"timer", "bell", "music"}
_sqs_client = None
_cf_client = None
_s3_client = None


def _sqs():
    global _sqs_client
    if _sqs_client is None:
        _sqs_client = boto3.client("sqs")
    return _sqs_client


def _cloudfront():
    global _cf_client
    if _cf_client is None:
        _cf_client = boto3.client("cloudfront")
    return _cf_client


def _s3():
    global _s3_client
    if _s3_client is None:
        _s3_client = boto3.client("s3")
    return _s3_client


def _validate_body(body: dict[str, Any], sub: str) -> str | None:
    name = body.get("name")
    if not name or not isinstance(name, str) or not (1 <= len(name) <= 100):
        return "name must be 1-100 characters"
    blocks = body.get("blocks")
    if not isinstance(blocks, list) or not (1 <= len(blocks) <= 50):
        return "blocks must contain 1-50 items"
    for block in blocks:
        if not isinstance(block, dict):
            return "each block must be an object"
        if not block.get("blockId") or not block.get("type"):
            return "blockId and type are required"
        if block["type"] not in VALID_BLOCK_TYPES:
            return f"invalid block type: {block['type']}"
        if block["type"] in ("timer", "music") and block.get("durationSeconds", 0) < 1:
            return "timer/music blocks require durationSeconds >= 1"
        if block["type"] == "bell" and not block.get("soundKey"):
            return "bell blocks require soundKey"
        if block["type"] == "music" and not block.get("musicAssetKey"):
            return "music blocks require musicAssetKey"
    duration = body.get("durationSeconds")
    if not isinstance(duration, int) or duration < 1:
        return "durationSeconds must be >= 1"
    audio_keys = body.get("audioAssetKeys") or []
    if not isinstance(audio_keys, list) or len(audio_keys) > 10:
        return "audioAssetKeys max 10 items"
    audio_key_set = set(audio_keys)
    prefix = f"audio/{sub}/"
    for key in audio_keys:
        if not isinstance(key, str) or not key.startswith(prefix):
            return "audioAssetKeys must belong to the authenticated user"
    for block in blocks:
        if block.get("type") == "music":
            music_key = block.get("musicAssetKey")
            if music_key not in audio_key_set:
                return "music blocks require musicAssetKey in audioAssetKeys"
    desc = body.get("userDescription") or ""
    if len(desc) > 500:
        return "userDescription max 500 characters"
    return None


def _verify_audio_objects(audio_keys: list[str]) -> str | None:
    bucket = os.environ.get("AUDIO_BUCKET")
    if not bucket or not audio_keys:
        return None
    for key in audio_keys:
        try:
            _s3().head_object(Bucket=bucket, Key=key)
        except Exception:
            return f"audio asset not found: {key}"
    return None


def _invalidate_cloudfront() -> None:
    dist_id = os.environ.get("CLOUDFRONT_DISTRIBUTION_ID")
    if not dist_id:
        return
    _cloudfront().create_invalidation(
        DistributionId=dist_id,
        InvalidationBatch={
            "Paths": {"Quantity": 1, "Items": ["/v1/routines*"]},
            "CallerReference": str(uuid.uuid4()),
        },
    )


def handler(event: dict[str, Any], context: object) -> dict[str, Any]:
    request_id = response.get_request_id(event)
    sub, err_resp = auth.authenticate(event, request_id)
    if err_resp:
        return err_resp

    try:
        raw = event.get("body") or "{}"
        if event.get("isBase64Encoded"):
            import base64

            raw = base64.b64decode(raw).decode()
        if len(raw) > 102400:
            return response.error(
                413, "PAYLOAD_TOO_LARGE", "Request body exceeds 100KB.", request_id=request_id
            )
        body = json.loads(raw)
        err = _validate_body(body, sub)
        if err:
            return response.error(400, "INVALID_BODY", err, request_id=request_id)

        audio_keys = body.get("audioAssetKeys") or []
        err = _verify_audio_objects(audio_keys)
        if err:
            return response.error(400, "INVALID_BODY", err, request_id=request_id)

        # Check for duplicate name under the same author (GSI2-author-routines)
        existing_resp = dynamo.get_table().query(
            IndexName="GSI2-author-routines",
            KeyConditionExpression="GSI2PK = :gsi2pk",
            FilterExpression="#nm = :name",
            ExpressionAttributeNames={"#nm": "name"},
            ExpressionAttributeValues={":gsi2pk": f"USER#{sub}", ":name": body["name"]},
            Limit=1,
        )
        if existing_resp.get("Items"):
            return response.error(
                409, "ALREADY_EXISTS", "A routine with this name already exists.", request_id=request_id
            )

        routine_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        author_name = auth.get_display_name(event) or "Community Member"

        routine_item = {
            "PK": f"ROUTINE#{routine_id}",
            "SK": "METADATA",
            "EntityType": "Routine",
            "routineId": routine_id,
            "authorSub": sub,
            "authorName": author_name,
            "name": body["name"],
            "description": body.get("userDescription") or "",
            "durationSeconds": body["durationSeconds"],
            "blocks": json.dumps(body["blocks"]),
            "likeCount": 0,
            "importCount": 0,
            "publishedAt": now,
            "updatedAt": now,
            "isPublic": True,
            "typesenseSynced": False,
            "GSI1PK": "PUBLIC",
            "GSI2PK": f"USER#{sub}",
            "taggingStatus": "pending",
        }
        audio_keys = body.get("audioAssetKeys") or []
        if audio_keys:
            routine_item["audioAssetKeys"] = set(audio_keys)

        dynamo.put_item(routine_item)

        queue_url = os.environ.get("SQS_TAGGING_QUEUE_URL")
        if queue_url:
            _sqs().send_message(
                QueueUrl=queue_url,
                MessageBody=json.dumps({"routineId": routine_id, "blocks": body["blocks"], "userDescription": body.get("userDescription", "")}),
            )

        try:
            _invalidate_cloudfront()
        except Exception:
            logger.warning("CloudFront invalidation failed", exc_info=True)

        return response.success(
            201,
            {
                "routineId": routine_id,
                "name": body["name"],
                "publishedAt": now,
                "taggingStatus": "pending",
            },
            request_id=request_id,
        )
    except json.JSONDecodeError:
        return response.error(400, "INVALID_BODY", "Invalid JSON body.", request_id=request_id)
    except Exception:
        logger.exception("post_routine failed requestId=%s sub=%s", request_id, sub)
        return response.error(
            500, "INTERNAL_ERROR", "Failed to publish routine.", request_id=request_id
        )
