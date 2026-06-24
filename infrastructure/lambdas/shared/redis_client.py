"""Lazy Redis client reused across warm Lambda invocations."""

from __future__ import annotations

import json
import os
from typing import Any

import redis

_client: redis.Redis | None = None


def get_redis() -> redis.Redis:
    global _client
    if _client is None:
        host = os.environ.get("REDIS_ENDPOINT") or os.environ.get("REDIS_HOST", "localhost")
        port = int(os.environ.get("REDIS_PORT", "6379"))
        _client = redis.Redis(
            host=host,
            port=port,
            decode_responses=True,
            socket_connect_timeout=2,
            socket_timeout=2,
        )
    return _client


def reset_redis() -> None:
    global _client
    _client = None


def cache_get(key: str) -> Any | None:
    raw = get_redis().get(key)
    if raw is None:
        return None
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return raw


def cache_set(key: str, value: Any, ttl_seconds: int) -> None:
    def _default(obj: Any) -> Any:
        if isinstance(obj, set):
            return sorted(obj)  # DynamoDB StringSets arrive as Python sets
        return str(obj)
    get_redis().setex(key, ttl_seconds, json.dumps(value, default=_default))


def cache_delete(key: str) -> None:
    get_redis().delete(key)


def pending_like_delta(routine_id: str) -> int:
    raw = get_redis().get(f"like:{routine_id}")
    return int(raw) if raw else 0


def effective_like_count(routine_id: str, base: int) -> int:
    """DynamoDB likeCount plus unflushed Redis increments."""
    return base + pending_like_delta(routine_id)


def incr_like(routine_id: str) -> int:
    return int(get_redis().incr(f"like:{routine_id}"))


def decr_like(routine_id: str) -> int:
    value = int(get_redis().decr(f"like:{routine_id}"))
    if value < 0:
        get_redis().set(f"like:{routine_id}", 0)
        return 0
    return value


def scan_like_keys() -> list[tuple[str, int]]:
    client = get_redis()
    keys: list[str] = []
    cursor = 0
    while True:
        cursor, batch = client.scan(cursor=cursor, match="like:*", count=100)
        keys.extend(batch)
        if cursor == 0:
            break
    results: list[tuple[str, int]] = []
    for key in keys:
        raw = client.get(key)
        if raw is not None:
            results.append((key, int(raw)))
    return results
