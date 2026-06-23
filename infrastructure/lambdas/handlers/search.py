"""GET /search — full-text search via Typesense."""

from __future__ import annotations

import logging
from typing import Any

from shared import response, typesense_client

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

SORT_MAP = {
    "_text_match": "_text_match:desc",
    "likeCount:desc": "likeCount:desc",
    "publishedAt:desc": "publishedAt:desc",
}


def _format_hit(hit: dict[str, Any]) -> dict[str, Any]:
    doc = hit.get("document") or {}
    highlights = {}
    for field, snippets in (hit.get("highlight") or {}).items():
        if snippets:
            highlights[field] = snippets[0].get("snippet") or snippets[0]
    tags = doc.get("tags") or []
    return {
        "routineId": doc.get("id"),
        "name": doc.get("name", ""),
        "description": doc.get("description", ""),
        "tags": tags,
        "durationSeconds": int(doc.get("durationSeconds", 0)),
        "authorName": doc.get("authorName", ""),
        "likeCount": int(doc.get("likeCount", 0)),
        "highlights": highlights,
    }


def handler(event: dict[str, Any], context: object) -> dict[str, Any]:
    request_id = response.get_request_id(event)
    try:
        qs = event.get("queryStringParameters") or {}
        query = (qs.get("q") or "").strip()
        if not query or len(query) > 200:
            return response.error(
                400,
                "MISSING_QUERY" if not query else "INVALID_PARAMETER",
                "Search query must be 1-200 characters.",
                request_id=request_id,
            )

        page_size = min(int(qs.get("pageSize", 20)), 50)
        page = max(int(qs.get("page", 1)), 1)
        sort = qs.get("sort", "_text_match")
        if sort not in SORT_MAP:
            return response.error(
                400, "INVALID_PARAMETER", f"Unknown sort value: {sort}", request_id=request_id
            )
        tag = qs.get("tag")
        min_duration = int(qs["minDuration"]) if qs.get("minDuration") else None
        max_duration = int(qs["maxDuration"]) if qs.get("maxDuration") else None

        try:
            result = typesense_client.search_routines(
                query=query,
                tag=tag.lower() if tag else None,
                min_duration=min_duration,
                max_duration=max_duration,
                sort_by=SORT_MAP[sort],
                page=page,
                page_size=page_size,
            )
        except Exception as exc:
            logger.warning("Typesense unavailable: %s", exc)
            return response.error(
                503,
                "SEARCH_UNAVAILABLE",
                "Search is temporarily unavailable. Try browsing routines instead.",
                request_id=request_id,
            )

        hits = [_format_hit(h) for h in result.get("hits", [])]
        return response.success(
            200,
            {
                "results": hits,
                "found": int(result.get("found", 0)),
                "page": page,
                "pageSize": page_size,
            },
            request_id=request_id,
        )
    except ValueError:
        return response.error(
            400, "INVALID_PARAMETER", "Invalid numeric query parameter.", request_id=request_id
        )
    except Exception:
        logger.exception("search failed requestId=%s", request_id)
        return response.error(500, "INTERNAL_ERROR", "Search failed.", request_id=request_id)
