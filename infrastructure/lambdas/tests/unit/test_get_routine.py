import json

from get_routine import handler
from conftest import auth_event, seed_routine


def test_get_routine_detail_with_like_flags(dynamodb_table, fake_redis):
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
        auth_event(path="/v1/routines/{id}", path_parameters={"id": rid}),
        None,
    )
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body["isLikedByMe"] is True
    assert body["blocks"][0]["type"] == "timer"


def test_get_routine_not_found(dynamodb_table, fake_redis):
    resp = handler(
        auth_event(
            path="/v1/routines/{id}",
            path_parameters={"id": "00000000-0000-4000-8000-000000000001"},
        ),
        None,
    )
    assert resp["statusCode"] == 404
