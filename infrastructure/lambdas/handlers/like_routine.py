"""POST /routines/{id}/like — like a routine."""

from __future__ import annotations

import logging
import os
import re
import uuid
from datetime import datetime, timezone
from typing import Any

import boto3

from shared import auth, dynamo, redis_client, response

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

UUID_RE = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$",
    re.I,
)
_sns_client = None
_cf_client = None


def _sns():
    global _sns_client
    if _sns_client is None:
        _sns_client = boto3.client("sns")
    return _sns_client


def _cloudfront():
    global _cf_client
    if _cf_client is None:
        _cf_client = boto3.client("cloudfront")
    return _cf_client


def _current_like_count(routine: dict[str, Any], routine_id: str) -> int:
    base = int(routine.get("likeCount", 0))
    pending = redis_client.get_redis().get(f"like:{routine_id}")
    return base + (int(pending) if pending else 0)


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

        now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        like_item = {
            "PK": f"USER#{sub}",
            "SK": f"LIKE#{routine_id}",
            "EntityType": "Like",
            "routineId": routine_id,
            "likedAt": now,
        }
        try:
            dynamo.get_table().put_item(
                Item=dynamo.to_dynamo(like_item),
                ConditionExpression="attribute_not_exists(SK)",
            )
            created = True
        except Exception as exc:
            if dynamo.is_conditional_check_failed(exc):
                created = False
            else:
                raise

        if not created:
            like_count = _current_like_count(routine, routine_id)
            return response.error(
                409, "ALREADY_LIKED", "You have already liked this routine.", request_id=request_id
            )

        like_count = redis_client.incr_like(routine_id) + int(routine.get("likeCount", 0))
        redis_client.cache_delete(f"routine:{routine_id}")
        topic = os.environ.get("SNS_LIKE_TOPIC_ARN")
        if topic and routine.get("authorSub") != sub:
            try:
                _sns().publish(
                    TopicArn=topic,
                    Message=f"Someone liked your routine {routine.get('name')}",
                    Subject="Routine liked",
                )
            except Exception:
                logger.warning("SNS publish failed", exc_info=True)
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
        logger.exception("like_routine failed requestId=%s sub=%s", request_id, sub)
        return response.error(500, "INTERNAL_ERROR", "Failed to like routine.", request_id=request_id)
