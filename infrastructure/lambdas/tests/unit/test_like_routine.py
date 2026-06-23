import json

from like_routine import handler
from conftest import auth_event, seed_routine


def test_like_routine_increments_count(dynamodb_table, fake_redis):
    rid = seed_routine(dynamodb_table)
    resp = handler(
        auth_event(method="POST", path="/v1/routines/{id}/like", path_parameters={"id": rid}),
        None,
    )
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body["likeCount"] >= 6


def test_like_routine_idempotent(dynamodb_table, fake_redis):
    rid = seed_routine(dynamodb_table)
    handler(
        auth_event(method="POST", path="/v1/routines/{id}/like", path_parameters={"id": rid}),
        None,
    )
    resp = handler(
        auth_event(method="POST", path="/v1/routines/{id}/like", path_parameters={"id": rid}),
        None,
    )
    assert resp["statusCode"] == 200
