"""Cognito JWT claim extraction from API Gateway authorizer context."""

from __future__ import annotations

import json
import os
import urllib.error
import urllib.request
from typing import Any, Literal

from jose import JWTError, jwk, jwt

AuthFailure = Literal["invalid", "missing"]

_jwks_cache: dict[str, list[dict[str, Any]]] = {}


def get_claims(event: dict[str, Any]) -> dict[str, Any]:
    ctx = event.get("requestContext") or {}
    authorizer = ctx.get("authorizer") or {}
    claims = authorizer.get("claims") or authorizer.get("jwt", {}).get("claims") or {}
    return claims if isinstance(claims, dict) else {}


def _header(event: dict[str, Any], name: str) -> str | None:
    headers = event.get("headers") or {}
    for key, value in headers.items():
        if key.lower() == name.lower():
            return value
    multi = event.get("multiValueHeaders") or {}
    for key, values in multi.items():
        if key.lower() == name.lower() and values:
            return values[0]
    return None


def _bearer_token(event: dict[str, Any]) -> str | None:
    auth = _header(event, "Authorization")
    if not auth:
        return None
    prefix = "bearer "
    if auth.lower().startswith(prefix):
        token = auth[len(prefix) :].strip()
        return token or None
    return None


def _cognito_config() -> tuple[str, str, str]:
    pool_id = os.environ.get("COGNITO_USER_POOL_ID", "")
    client_id = os.environ.get("COGNITO_APP_CLIENT_ID", "")
    region = os.environ.get("AWS_REGION") or os.environ.get("AWS_DEFAULT_REGION", "us-east-1")
    if not pool_id or not client_id:
        raise JWTError("Cognito is not configured for optional auth")
    return pool_id, client_id, region


def _jwks(pool_id: str, region: str) -> list[dict[str, Any]]:
    cache_key = f"{region}:{pool_id}"
    if cache_key not in _jwks_cache:
        url = f"https://cognito-idp.{region}.amazonaws.com/{pool_id}/.well-known/jwks.json"
        try:
            with urllib.request.urlopen(url, timeout=5) as resp:
                _jwks_cache[cache_key] = json.loads(resp.read())["keys"]
        except (urllib.error.URLError, TimeoutError, KeyError, json.JSONDecodeError) as exc:
            raise JWTError(f"Failed to load JWKS: {exc}") from exc
    return _jwks_cache[cache_key]


def _verify_cognito_token(token: str) -> dict[str, Any]:
    pool_id, client_id, region = _cognito_config()
    issuer = f"https://cognito-idp.{region}.amazonaws.com/{pool_id}"
    kid = jwt.get_unverified_header(token).get("kid")
    key_data = next((k for k in _jwks(pool_id, region) if k.get("kid") == kid), None)
    if not key_data:
        raise JWTError("Unknown signing key")

    claims = jwt.decode(
        token,
        jwk.construct(key_data),
        algorithms=["RS256"],
        issuer=issuer,
        options={"verify_aud": False, "verify_at_hash": False},
    )
    token_use = claims.get("token_use")
    if token_use == "access":
        if claims.get("client_id") != client_id:
            raise JWTError("Invalid client_id")
    elif token_use == "id":
        if claims.get("aud") != client_id:
            raise JWTError("Invalid audience")
    else:
        raise JWTError("Invalid token_use")
    return claims


def _claims_from_bearer(event: dict[str, Any]) -> dict[str, Any] | None:
    token = _bearer_token(event)
    if not token:
        return None
    return _verify_cognito_token(token)


def optional_sub(event: dict[str, Any]) -> tuple[str | None, bool]:
    """Return caller sub and whether a Bearer token was present but invalid."""
    claims = get_claims(event)
    sub = claims.get("sub")
    if sub:
        return str(sub), False

    token = _bearer_token(event)
    if not token:
        return None, False

    try:
        verified = _verify_cognito_token(token)
    except JWTError:
        return None, True
    verified_sub = verified.get("sub")
    return (str(verified_sub), False) if verified_sub else (None, True)


def require_sub(event: dict[str, Any]) -> tuple[str | None, AuthFailure | None]:
    """Return caller sub or an auth failure reason for protected routes."""
    sub, invalid = optional_sub(event)
    if invalid:
        return None, "invalid"
    if not sub:
        return None, "missing"
    return sub, None


def authenticate(event: dict[str, Any], request_id: str) -> tuple[str | None, dict[str, Any] | None]:
    """Validate required auth; return (sub, error_response)."""
    from shared import response

    sub, failure = require_sub(event)
    if failure == "invalid":
        return None, response.error(401, "UNAUTHORIZED", "Invalid token.", request_id=request_id)
    if failure == "missing":
        return None, response.error(
            401, "UNAUTHORIZED", "Authentication required.", request_id=request_id
        )
    return sub, None


def get_sub(event: dict[str, Any]) -> str | None:
    claims = get_claims(event)
    sub = claims.get("sub")
    if sub:
        return str(sub)

    try:
        bearer_claims = _claims_from_bearer(event)
    except JWTError:
        return None
    if not bearer_claims:
        return None
    bearer_sub = bearer_claims.get("sub")
    return str(bearer_sub) if bearer_sub else None


def get_display_name(event: dict[str, Any]) -> str | None:
    claims = get_claims(event)
    if not claims.get("sub"):
        try:
            bearer_claims = _claims_from_bearer(event)
            if bearer_claims:
                claims = bearer_claims
        except JWTError:
            pass
    for key in ("name", "preferred_username", "email"):
        value = claims.get(key)
        if value:
            return str(value)
    return None


def is_authenticated(event: dict[str, Any]) -> bool:
    return get_sub(event) is not None
