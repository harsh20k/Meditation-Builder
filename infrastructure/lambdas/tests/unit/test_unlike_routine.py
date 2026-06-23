import json

from unlike_routine import handler
from conftest import auth_event, seed_routine


def test_unlike_routine(dynamodb_table, fake_redis):
    rid = seed_routine(dynamodb_table)
    dynamodb_table.put_item(
        Item={
            "PK": "USER#user-sub-1",
            "SK": f"LIKE#{rid}",
            "EntityType": "Like",
            "routineId": rid,
        }
    )
    resp = handler(
        auth_event(method="DELETE", path="/v1/routines/{id}/like", path_parameters={"id": rid}),
        None,
    )
    assert resp["statusCode"] == 200
    assert "likeCount" in json.loads(resp["body"])


def test_unlike_not_found(dynamodb_table, fake_redis):
    rid = seed_routine(dynamodb_table)
    resp = handler(
        auth_event(method="DELETE", path="/v1/routines/{id}/like", path_parameters={"id": rid}),
        None,
    )
    assert resp["statusCode"] == 404
