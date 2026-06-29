"""Typesense client wrapper for routines collection."""

from __future__ import annotations

import logging
import os
from datetime import datetime, timezone
from typing import Any

import boto3
import typesense

logger = logging.getLogger(__name__)

_client: typesense.Client | None = None
_collection_ready = False

ROUTINES_SCHEMA: dict[str, Any] = {
    "name": "routines",
    "fields": [
        {"name": "name", "type": "string"},
        {"name": "description", "type": "string"},
        {"name": "tags", "type": "string[]", "facet": True},
        {"name": "durationSeconds", "type": "int32", "facet": True},
        {"name": "authorName", "type": "string"},
        {"name": "likeCount", "type": "int32"},
        {"name": "importCount", "type": "int32"},
        {"name": "publishedAt", "type": "int64"},
    ],
    "default_sorting_field": "publishedAt",
}


def _resolve_api_key() -> str:
    direct = os.environ.get("TYPESENSE_API_KEY")
    if direct:
        return direct
    ssm_path = os.environ.get("TYPESENSE_API_KEY_SSM")
    if ssm_path:
        value = boto3.client("ssm").get_parameter(Name=ssm_path, WithDecryption=True)["Parameter"]["Value"]
        return str(value)
    return "test-key"


def get_client() -> typesense.Client:
    global _client
    if _client is None:
        host = os.environ.get("TYPESENSE_HOST", "localhost")
        port = os.environ.get("TYPESENSE_PORT", "8108")
        protocol = os.environ.get("TYPESENSE_PROTOCOL", "http")
        api_key = _resolve_api_key()
        _client = typesense.Client(
            {
                "nodes": [{"host": host, "port": port, "protocol": protocol}],
                "api_key": api_key,
                "connection_timeout_seconds": 3,
            }
        )
    return _client


def ensure_collection() -> None:
    global _collection_ready
    if _collection_ready:
        return
    client = get_client()
    try:
        client.collections["routines"].retrieve()
        _collection_ready = True
        return
    except typesense.exceptions.ObjectNotFound:
        pass
    client.collections.create(ROUTINES_SCHEMA)
    _collection_ready = True
    logger.info("Created Typesense collection: routines")


def reset_client() -> None:
    global _client, _collection_ready
    _client = None
    _collection_ready = False


def routine_to_document(item: dict[str, Any]) -> dict[str, Any]:
    published_at = item.get("publishedAt")
    if isinstance(published_at, str):
        dt = datetime.fromisoformat(published_at.replace("Z", "+00:00"))
        published_epoch = int(dt.timestamp())
    else:
        published_epoch = int(datetime.now(timezone.utc).timestamp())
    tags = item.get("tags") or []
    if isinstance(tags, set):
        tags = list(tags)
    return {
        "id": item["routineId"],
        "name": item.get("name", ""),
        "description": item.get("description", ""),
        "tags": tags,
        "durationSeconds": int(item.get("durationSeconds", 0)),
        "authorName": item.get("authorName", ""),
        "likeCount": int(item.get("likeCount", 0)),
        "importCount": int(item.get("importCount", 0)),
        "publishedAt": published_epoch,
    }


def upsert_routine(item: dict[str, Any]) -> None:
    ensure_collection()
    doc = routine_to_document(item)
    get_client().collections["routines"].documents.upsert(doc)


def delete_routine(routine_id: str) -> None:
    ensure_collection()
    get_client().collections["routines"].documents[routine_id].delete()


def search_routines(
    *,
    query: str,
    tag: str | None = None,
    min_duration: int | None = None,
    max_duration: int | None = None,
    sort_by: str = "_text_match:desc",
    page: int = 1,
    page_size: int = 20,
) -> dict[str, Any]:
    filters: list[str] = []
    if tag:
        filters.append(f"tags:=[{tag.lower()}]")
    if min_duration is not None:
        filters.append(f"durationSeconds:>={min_duration}")
    if max_duration is not None:
        filters.append(f"durationSeconds:<={max_duration}")
    params: dict[str, Any] = {
        "q": query,
        "query_by": "name,description,tags,authorName",
        "page": page,
        "per_page": page_size,
        "sort_by": sort_by,
        "highlight_full_fields": "name,description",
    }
    if filters:
        params["filter_by"] = " && ".join(filters)
    ensure_collection()
    return get_client().collections["routines"].documents.search(params)
