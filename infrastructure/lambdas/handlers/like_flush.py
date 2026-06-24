"""EventBridge scheduled flush of Redis like counters to DynamoDB."""

from __future__ import annotations

import logging
from typing import Any

from shared import dynamo, redis_client

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def handler(event: dict[str, Any], context: object) -> dict[str, Any]:
    flushed = 0
    client = redis_client.get_redis()
    for key, delta in redis_client.scan_like_keys():
        if delta == 0:
            client.delete(key)
            continue
        routine_id = key.split(":", 1)[1]
        try:
            dynamo.get_table().update_item(
                Key={"PK": f"ROUTINE#{routine_id}", "SK": "METADATA"},
                UpdateExpression="ADD likeCount :delta",
                ExpressionAttributeValues={":delta": delta},
                ConditionExpression="attribute_exists(PK)",
            )
            client.delete(key)
            redis_client.cache_delete(f"routine:{routine_id}")
            flushed += 1
        except Exception:
            logger.exception("like_flush failed for %s", routine_id)
    return {"flushed": flushed}
