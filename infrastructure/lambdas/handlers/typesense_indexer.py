"""DynamoDB Streams → Typesense indexer for Routine entities."""

from __future__ import annotations

import logging
from typing import Any

from shared import dynamo, typesense_client

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def _deserialize_image(image: dict[str, Any] | None) -> dict[str, Any] | None:
    if not image:
        return None
    from boto3.dynamodb.types import TypeDeserializer

    deserializer = TypeDeserializer()
    return {k: deserializer.deserialize(v) for k, v in image.items()}


def _is_routine(item: dict[str, Any] | None) -> bool:
    return bool(item and item.get("EntityType") == "Routine")


def handler(event: dict[str, Any], context: object) -> dict[str, Any]:
    processed = 0
    for record in event.get("Records", []):
        event_name = record.get("eventName")
        new_image = _deserialize_image(record.get("dynamodb", {}).get("NewImage"))
        old_image = _deserialize_image(record.get("dynamodb", {}).get("OldImage"))

        try:
            if event_name in ("INSERT", "MODIFY") and _is_routine(new_image):
                python_item = dynamo.to_python(new_image)
                if python_item.get("isPublic"):
                    typesense_client.upsert_routine(python_item)
                    dynamo.update_item(
                        f"ROUTINE#{python_item['routineId']}",
                        "METADATA",
                        updates={"typesenseSynced": True},
                    )
            elif event_name == "REMOVE" and _is_routine(old_image):
                routine_id = old_image.get("routineId")
                if routine_id:
                    typesense_client.delete_routine(str(routine_id))
            processed += 1
        except Exception:
            logger.exception("typesense_indexer failed event=%s", event_name)
            raise
    return {"processed": processed}
