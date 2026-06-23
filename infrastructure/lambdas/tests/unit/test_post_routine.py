import json

from post_routine import handler
from conftest import auth_event


def test_post_routine_creates_item(dynamodb_table, fake_redis):
    body = {
        "name": "Evening Calm",
        "blocks": [{"blockId": "b1", "type": "timer", "durationSeconds": 300}],
        "durationSeconds": 300,
    }
    resp = handler(auth_event(method="POST", path="/v1/routines", body=body), None)
    assert resp["statusCode"] == 201
    payload = json.loads(resp["body"])
    assert payload["taggingStatus"] == "pending"
    assert payload["routineId"]


def test_post_routine_requires_auth(dynamodb_table, fake_redis):
    resp = handler(
        auth_event(method="POST", path="/v1/routines", body={"name": "x"}, sub=None),
        None,
    )
    assert resp["statusCode"] == 401
