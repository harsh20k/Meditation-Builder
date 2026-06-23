from unittest.mock import patch

from bedrock_tagger import handler
from conftest import seed_routine


def test_bedrock_tagger_updates_routine(dynamodb_table, fake_redis):
    rid = seed_routine(dynamodb_table)
    event = {
        "Records": [
            {
                "messageId": "m1",
                "body": '{"routineId": "%s", "blocks": [], "userDescription": "calm"}' % rid,
            }
        ]
    }
    with patch(
        "bedrock_tagger._invoke_bedrock",
        return_value=(["calm", "sleep"], "A calming routine."),
    ):
        resp = handler(event, None)
    assert resp["batchItemFailures"] == []
    item = dynamodb_table.get_item(Key={"PK": f"ROUTINE#{rid}", "SK": "METADATA"})["Item"]
    assert item["taggingStatus"] == "complete"
    assert "calm" in item["tags"]
