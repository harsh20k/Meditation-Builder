import json

from get_recommendations import handler
from conftest import auth_event, seed_routine


def test_get_recommendations_returns_list(dynamodb_table, fake_redis):
    seed_routine(dynamodb_table, author_sub="author-2")
    resp = handler(auth_event(path="/v1/recommendations"), None)
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert "recommendations" in body
    assert len(body["recommendations"]) >= 1


def test_get_recommendations_requires_auth(dynamodb_table, fake_redis):
    resp = handler(auth_event(path="/v1/recommendations", sub=None), None)
    assert resp["statusCode"] == 401
