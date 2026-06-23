"""Cognito JWT claim extraction from API Gateway authorizer context."""

from __future__ import annotations

from typing import Any


def get_claims(event: dict[str, Any]) -> dict[str, Any]:
    ctx = event.get("requestContext") or {}
    authorizer = ctx.get("authorizer") or {}
    claims = authorizer.get("claims") or authorizer.get("jwt", {}).get("claims") or {}
    return claims if isinstance(claims, dict) else {}


def get_sub(event: dict[str, Any]) -> str | None:
    claims = get_claims(event)
    sub = claims.get("sub")
    return str(sub) if sub else None


def get_display_name(event: dict[str, Any]) -> str | None:
    claims = get_claims(event)
    for key in ("name", "preferred_username", "email"):
        value = claims.get(key)
        if value:
            return str(value)
    return None


def is_authenticated(event: dict[str, Any]) -> bool:
    return get_sub(event) is not None
