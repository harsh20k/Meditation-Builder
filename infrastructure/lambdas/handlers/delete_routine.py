"""DELETE /routines/{id} — unpublish caller's routine."""

from __future__ import annotations

import logging
import os
import re
import uuid
from typing import Any

import boto3

from shared import auth, dynamo, response, typesense_client

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


def _invalidate(routine_id: str) -> None:
    dist_id = os.environ.get("CLOUDFRONT_DISTRIBUTION_ID")
    if not dist_id:
        return
    _cloudfront().create_invalidation(
        DistributionId=dist_id,
        InvalidationBatch={
            "Paths": {
                "Quantity": 2,
                "Items": [f"/v1/routines/{routine_id}", "/v1/routines*"],
            },
            "CallerReference": str(uuid.uuid4()),
        },
    )


def handler(event: dict[str, Any], context: object) -> dict[str, Any]:
    request_id = response.get_request_id(event)
    sub = auth.get_sub(event)
    if not sub:
        return response.error(401, "UNAUTHORIZED", "Authentication required.", request_id=request_id)

    try:
        routine_id = (event.get("pathParameters") or {}).get("id", "")
        if not UUID_RE.match(routine_id):
            return response.error(400, "INVALID_ID", "Invalid routine id.", request_id=request_id)

        item = dynamo.get_item(f"ROUTINE#{routine_id}", "METADATA")
        if not item or not item.get("isPublic"):
            return response.error(
                404, "ROUTINE_NOT_FOUND", "No routine with the given id.", request_id=request_id
            )
        if item.get("authorSub") != sub:
            return response.error(
                403, "FORBIDDEN", "You may only delete your own routines.", request_id=request_id
            )

        tag_items = dynamo.query_tag_indexes_for_routine(routine_id)
        transact: list[dict[str, Any]] = [
            {
                "Delete": {
                    "TableName": dynamo.get_table_name(),
                    "Key": {"PK": f"ROUTINE#{routine_id}", "SK": "METADATA"},
                }
            }
        ]
        for tag_item in tag_items[:5]:
            transact.append(
                {
                    "Delete": {
                        "TableName": dynamo.get_table_name(),
                        "Key": {"PK": tag_item["PK"], "SK": tag_item["SK"]},
                    }
                }
            )
        dynamo.transact_write(transact)

        try:
            typesense_client.delete_routine(routine_id)
        except Exception:
            logger.warning("Typesense delete failed for %s", routine_id, exc_info=True)

        try:
            _invalidate(routine_id)
        except Exception:
            logger.warning("CloudFront invalidation failed", exc_info=True)

        return response.success(204, None, request_id=request_id)
    except Exception:
        logger.exception("delete_routine failed requestId=%s sub=%s", request_id, sub)
        return response.error(
            500, "INTERNAL_ERROR", "Failed to delete routine.", request_id=request_id
        )
