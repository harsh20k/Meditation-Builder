"""POST /uploads/audio — presigned S3 PUT URL for custom block music."""

from __future__ import annotations

import json
import logging
import os
import uuid
from typing import Any

import boto3

from shared import auth, response

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

PRESIGN_EXPIRY_SECONDS = 900

ALLOWED_CONTENT_TYPES = {
    "m4a": "audio/m4a",
    "mp4": "audio/mp4",
    "mp3": "audio/mpeg",
    "mpeg": "audio/mpeg",
    "wav": "audio/wav",
    "aiff": "audio/aiff",
    "aif": "audio/aiff",
}

_s3_client = None


def _s3():
    global _s3_client
    if _s3_client is None:
        _s3_client = boto3.client("s3")
    return _s3_client


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
        body = json.loads(raw)

        ext = (body.get("fileExtension") or "m4a").lower().lstrip(".")
        content_type = body.get("contentType") or ALLOWED_CONTENT_TYPES.get(ext)
        if not content_type or content_type not in ALLOWED_CONTENT_TYPES.values():
            return response.error(
                400,
                "INVALID_BODY",
                "Unsupported audio type. Allowed: m4a, mp4, mp3, wav, aiff.",
                request_id=request_id,
            )

        bucket = os.environ.get("AUDIO_BUCKET")
        if not bucket:
            return response.error(
                500, "INTERNAL_ERROR", "Audio storage not configured.", request_id=request_id
            )

        asset_key = f"audio/{sub}/{uuid.uuid4()}.{ext}"
        upload_url = _s3().generate_presigned_url(
            "put_object",
            Params={
                "Bucket": bucket,
                "Key": asset_key,
                "ContentType": content_type,
            },
            ExpiresIn=PRESIGN_EXPIRY_SECONDS,
        )

        return response.success(
            200,
            {
                "assetKey": asset_key,
                "uploadUrl": upload_url,
                "expiresIn": PRESIGN_EXPIRY_SECONDS,
            },
            request_id=request_id,
        )
    except json.JSONDecodeError:
        return response.error(400, "INVALID_BODY", "Invalid JSON body.", request_id=request_id)
    except Exception:
        logger.exception("presign_audio_upload failed requestId=%s sub=%s", request_id, sub)
        return response.error(
            500, "INTERNAL_ERROR", "Failed to create upload URL.", request_id=request_id
        )
