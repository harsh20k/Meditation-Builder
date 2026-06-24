import json
from unittest.mock import patch

from jose import JWTError

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


def test_get_routine_includes_pending_redis_likes(dynamodb_table, fake_redis):
    rid = seed_routine(dynamodb_table)
    fake_redis.set(f"like:{rid}", 2)
    resp = handler(
        auth_event(path="/v1/routines/{id}", path_parameters={"id": rid}),
        None,
    )
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body["likeCount"] == 7  # seed likeCount 5 + 2 pending


def test_get_routine_not_found(dynamodb_table, fake_redis):
    resp = handler(
        auth_event(
            path="/v1/routines/{id}",
            path_parameters={"id": "00000000-0000-4000-8000-000000000001"},
        ),
        None,
    )
    assert resp["statusCode"] == 404


def test_get_routine_invalid_bearer(dynamodb_table, fake_redis):
    rid = seed_routine(dynamodb_table)
    event = auth_event(path="/v1/routines/{id}", path_parameters={"id": rid}, sub=None)
    event["headers"]["Authorization"] = "Bearer invalid"
    with patch("get_routine.auth._verify_cognito_token", side_effect=JWTError("bad")):
        resp = handler(event, None)
    assert resp["statusCode"] == 401

