"""Standard API Gateway JSON response helpers."""

from __future__ import annotations

import json
import uuid
from typing import Any


def get_request_id(event: dict[str, Any]) -> str:
    headers = event.get("headers") or {}
    for key, value in headers.items():
        if key.lower() == "x-request-id" and value:
            return str(value)
    ctx = event.get("requestContext") or {}
    return str(ctx.get("requestId") or uuid.uuid4())


def success(
    status: int,
    body: dict[str, Any] | list[Any] | None = None,
    *,
    request_id: str,
    headers: dict[str, str] | None = None,
) -> dict[str, Any]:
    response_headers = {
        "Content-Type": "application/json",
        "X-Request-Id": request_id,
    }
    if headers:
        response_headers.update(headers)
    payload: dict[str, Any] = {
        "statusCode": status,
        "headers": response_headers,
    }
    if body is not None:
        payload["body"] = json.dumps(body, default=str)
    else:
        payload["body"] = ""
    return payload


def error(
    status: int,
    error_key: str,
    message: str,
    *,
    request_id: str,
    extra: dict[str, Any] | None = None,
) -> dict[str, Any]:
    body: dict[str, Any] = {
        "error": error_key,
        "message": message,
        "requestId": request_id,
    }
    if extra:
        body.update(extra)
    return success(status, body, request_id=request_id)
