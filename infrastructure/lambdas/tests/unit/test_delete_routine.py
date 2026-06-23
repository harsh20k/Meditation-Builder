import json

from delete_routine import handler
from conftest import auth_event, seed_routine


def test_delete_routine_by_owner(dynamodb_table, fake_redis):
    rid = seed_routine(dynamodb_table, author_sub="user-sub-1")
    resp = handler(
        auth_event(method="DELETE", path="/v1/routines/{id}", path_parameters={"id": rid}),
        None,
    )
    assert resp["statusCode"] == 204
    item = dynamodb_table.get_item(Key={"PK": f"ROUTINE#{rid}", "SK": "METADATA"}).get("Item")
    assert item is None


def test_delete_routine_forbidden(dynamodb_table, fake_redis):
    rid = seed_routine(dynamodb_table, author_sub="other-user")
    resp = handler(
        auth_event(method="DELETE", path="/v1/routines/{id}", path_parameters={"id": rid}),
        None,
    )
    assert resp["statusCode"] == 403
    assert json.loads(resp["body"])["error"] == "FORBIDDEN"
