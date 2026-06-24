import json
from unittest.mock import patch

from search import handler
from conftest import auth_event


def test_search_missing_query():
    resp = handler(auth_event(path="/v1/search", sub=None), None)
    assert resp["statusCode"] == 400
    assert json.loads(resp["body"])["error"] == "MISSING_QUERY"


def test_search_returns_results():
    mock_result = {
        "found": 1,
        "hits": [
            {
                "document": {
                    "id": "00000000-0000-4000-8000-000000000099",
                    "name": "Morning Focus",
                    "description": "Focus",
                    "tags": ["focus"],
                    "durationSeconds": 600,
                    "authorName": "Jane",
                    "likeCount": 1,
                    "importCount": 2,
                },
                "highlight": {"name": [{"snippet": "<mark>Morning</mark> Focus"}]},
            }
        ],
    }
    with patch("search.typesense_client.search_routines", return_value=mock_result):
        resp = handler(auth_event(path="/v1/search", query={"q": "morning"}, sub=None), None)
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body["found"] == 1
    assert body["results"][0]["importCount"] == 2
    assert body["results"][0]["highlights"]["name"]


def test_search_highlight_dict_format():
    mock_result = {
        "found": 1,
        "hits": [
            {
                "document": {
                    "id": "00000000-0000-4000-8000-000000000099",
                    "name": "Morning Focus",
                    "description": "Focus",
                    "tags": ["morning"],
                    "durationSeconds": 600,
                    "authorName": "Jane",
                    "likeCount": 1,
                },
                "highlight": {"tags": {"matched_tokens": ["morning"]}},
            }
        ],
    }
    with patch("search.typesense_client.search_routines", return_value=mock_result):
        resp = handler(auth_event(path="/v1/search", query={"q": "morning"}, sub=None), None)
    assert resp["statusCode"] == 200
    assert json.loads(resp["body"])["results"][0]["highlights"]["tags"]
