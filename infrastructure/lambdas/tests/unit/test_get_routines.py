import json

from get_routines import handler
from conftest import auth_event, seed_routine


def test_get_routines_returns_published_routines(dynamodb_table, fake_redis):
    seed_routine(dynamodb_table)
    resp = handler(auth_event(sub=None), None)
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body["count"] == 1
    assert body["routines"][0]["name"] == "Morning Focus"


def test_get_routines_invalid_sort(dynamodb_table, fake_redis):
    resp = handler(auth_event(sub=None, query={"sort": "invalid"}), None)
    assert resp["statusCode"] == 400
    assert json.loads(resp["body"])["error"] == "INVALID_PARAMETER"
