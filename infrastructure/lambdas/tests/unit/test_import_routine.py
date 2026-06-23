import json

from import_routine import handler
from conftest import auth_event, seed_routine


def test_import_routine(dynamodb_table, fake_redis):
    rid = seed_routine(dynamodb_table)
    resp = handler(
        auth_event(method="POST", path="/v1/routines/{id}/import", path_parameters={"id": rid}),
        None,
    )
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body["routine"]["routineId"] == rid
    routine = dynamodb_table.get_item(Key={"PK": f"ROUTINE#{rid}", "SK": "METADATA"})["Item"]
    assert routine["importCount"] == 3


def test_import_routine_idempotent(dynamodb_table, fake_redis):
    rid = seed_routine(dynamodb_table)
    handler(
        auth_event(method="POST", path="/v1/routines/{id}/import", path_parameters={"id": rid}),
        None,
    )
    resp = handler(
        auth_event(method="POST", path="/v1/routines/{id}/import", path_parameters={"id": rid}),
        None,
    )
    assert resp["statusCode"] == 200
    assert json.loads(resp["body"]).get("alreadyImported") is True
