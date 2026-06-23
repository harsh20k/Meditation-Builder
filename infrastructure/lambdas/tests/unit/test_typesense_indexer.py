from unittest.mock import patch

from typesense_indexer import handler
from conftest import seed_routine


def test_typesense_indexer_upserts_on_modify(dynamodb_table, fake_redis):
    rid = seed_routine(dynamodb_table)
    record = {
        "eventName": "MODIFY",
        "dynamodb": {
            "NewImage": {
                "PK": {"S": f"ROUTINE#{rid}"},
                "SK": {"S": "METADATA"},
                "EntityType": {"S": "Routine"},
                "routineId": {"S": rid},
                "name": {"S": "Morning Focus"},
                "description": {"S": "Focus"},
                "tags": {"SS": ["focus"]},
                "durationSeconds": {"N": "600"},
                "authorName": {"S": "Jane"},
                "likeCount": {"N": "5"},
                "importCount": {"N": "2"},
                "publishedAt": {"S": "2026-06-20T14:00:00Z"},
                "isPublic": {"BOOL": True},
            }
        },
    }
    with patch("typesense_indexer.typesense_client.upsert_routine") as upsert:
        resp = handler({"Records": [record]}, None)
    assert resp["processed"] == 1
    upsert.assert_called_once()
