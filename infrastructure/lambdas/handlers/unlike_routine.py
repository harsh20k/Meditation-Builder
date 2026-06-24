"""DELETE /routines/{id}/like — remove a like."""

from __future__ import annotations

import logging
import os
import re
import uuid
from typing import Any

import boto3

from shared import auth, dynamo, redis_client, response

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

UUID_RE = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$",
    re.I,
)
_cf_client = None


def _cloudfront():
    global _cf_client
    if _cf_client is None:
        _cf_client = boto3.client("cloudfront")
    return _cf_client


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

        like = dynamo.get_item(f"USER#{sub}", f"LIKE#{routine_id}")
        if not like:
            return response.error(
                404, "LIKE_NOT_FOUND", "You have not liked this routine.", request_id=request_id
            )

        dynamo.delete_item(f"USER#{sub}", f"LIKE#{routine_id}")
        pending = redis_client.decr_like(routine_id)
        like_count = int(routine.get("likeCount", 0)) + pending
        if like_count < 0:
            like_count = 0
        redis_client.cache_delete(f"routine:{routine_id}")

        dist_id = os.environ.get("CLOUDFRONT_DISTRIBUTION_ID")
        if dist_id:
            try:
                _cloudfront().create_invalidation(
                    DistributionId=dist_id,
                    InvalidationBatch={
                        "Paths": {"Quantity": 1, "Items": [f"/v1/routines/{routine_id}"]},
                        "CallerReference": str(uuid.uuid4()),
                    },
                )
            except Exception:
                logger.warning("CloudFront invalidation failed", exc_info=True)

        return response.success(200, {"likeCount": like_count}, request_id=request_id)
    except Exception:
        logger.exception("unlike_routine failed requestId=%s sub=%s", request_id, sub)
        return response.error(
            500, "INTERNAL_ERROR", "Failed to unlike routine.", request_id=request_id
        )
