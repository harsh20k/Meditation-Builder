import json

from post_activity import handler
from conftest import auth_event


def test_post_activity_accepted(dynamodb_table, fake_redis):
    body = {
        "sessionDurationSeconds": 900,
        "routinesPlayed": ["00000000-0000-4000-8000-000000000001"],
        "tagsEngaged": ["focus"],
        "blockTypes": ["timer"],
    }
    resp = handler(auth_event(method="POST", path="/v1/activity", body=body), None)
    assert resp["statusCode"] == 202
    assert json.loads(resp["body"])["accepted"] is True


def test_post_activity_invalid_body(dynamodb_table, fake_redis):
    resp = handler(
        auth_event(method="POST", path="/v1/activity", body={"sessionDurationSeconds": 0}),
        None,
    )
    assert resp["statusCode"] == 400
