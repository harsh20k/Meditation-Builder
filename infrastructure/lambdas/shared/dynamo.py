"""DynamoDB resource helpers for mb-{env}-community single-table design."""

from __future__ import annotations

import base64
import json
import os
from decimal import Decimal
from typing import Any

import boto3
from boto3.dynamodb.conditions import Attr, Key
from botocore.exceptions import ClientError

_table = None


def get_table_name() -> str:
    return os.environ.get("DYNAMODB_TABLE_NAME", "mb-staging-community")


def get_table():
    global _table
    if _table is None:
        resource = boto3.resource("dynamodb")
        _table = resource.Table(get_table_name())
    return _table


def reset_table() -> None:
    """Reset cached table — for tests."""
    global _table
    _table = None


def to_python(value: Any) -> Any:
    if isinstance(value, Decimal):
        if value % 1 == 0:
            return int(value)
        return float(value)
    if isinstance(value, list):
        return [to_python(v) for v in value]
    if isinstance(value, dict):
        return {k: to_python(v) for k, v in value.items()}
    if isinstance(value, set):
        return {to_python(v) for v in value}
    return value


def to_dynamo(value: Any) -> Any:
    if isinstance(value, float):
        return Decimal(str(value))
    if isinstance(value, list):
        return [to_dynamo(v) for v in value]
    if isinstance(value, dict):
        return {k: to_dynamo(v) for k, v in value.items()}
    return value


def sanitize_item(item: dict[str, Any]) -> dict[str, Any]:
    cleaned: dict[str, Any] = {}
    for key, value in item.items():
        if isinstance(value, (set, list, tuple)) and len(value) == 0:
            continue
        cleaned[key] = value
    return cleaned


def encode_token(key: dict[str, Any] | None) -> str | None:
    if not key:
        return None
    return base64.urlsafe_b64encode(json.dumps(key, default=str).encode()).decode()


def decode_token(token: str | None) -> dict[str, Any] | None:
    if not token:
        return None
    try:
        raw = base64.urlsafe_b64decode(token.encode())
        return json.loads(raw.decode())
    except (ValueError, json.JSONDecodeError):
        raise ValueError("invalid nextToken")


def get_item(pk: str, sk: str) -> dict[str, Any] | None:
    resp = get_table().get_item(Key={"PK": pk, "SK": sk})
    item = resp.get("Item")
    return to_python(item) if item else None


def put_item(item: dict[str, Any]) -> None:
    get_table().put_item(Item=to_dynamo(sanitize_item(item)))


def delete_item(pk: str, sk: str) -> None:
    get_table().delete_item(Key={"PK": pk, "SK": sk})


def update_item(
    pk: str,
    sk: str,
    *,
    updates: dict[str, Any],
    condition: str | None = None,
) -> dict[str, Any]:
    names: dict[str, str] = {}
    values: dict[str, Any] = {}
    parts: list[str] = []
    for idx, (field, value) in enumerate(updates.items()):
        nk, vk = f"#f{idx}", f":v{idx}"
        names[nk] = field
        values[vk] = to_dynamo(value)
        parts.append(f"{nk} = {vk}")
    kwargs: dict[str, Any] = {
        "Key": {"PK": pk, "SK": sk},
        "UpdateExpression": "SET " + ", ".join(parts),
        "ExpressionAttributeNames": names,
        "ExpressionAttributeValues": values,
        "ReturnValues": "ALL_NEW",
    }
    if condition:
        kwargs["ConditionExpression"] = condition
    resp = get_table().update_item(**kwargs)
    return to_python(resp.get("Attributes", {}))


def query_gsi1(
    *,
    limit: int,
    exclusive_start_key: dict[str, Any] | None = None,
    scan_forward: bool = False,
    filter_expression=None,
) -> tuple[list[dict[str, Any]], dict[str, Any] | None]:
    kwargs: dict[str, Any] = {
        "IndexName": "GSI1-public-by-date",
        "KeyConditionExpression": Key("GSI1PK").eq("PUBLIC"),
        "Limit": limit,
        "ScanIndexForward": scan_forward,
    }
    if exclusive_start_key:
        kwargs["ExclusiveStartKey"] = exclusive_start_key
    if filter_expression is not None:
        kwargs["FilterExpression"] = filter_expression
    resp = get_table().query(**kwargs)
    items = [to_python(i) for i in resp.get("Items", [])]
    return items, resp.get("LastEvaluatedKey")


def query_tag(
    tag: str,
    *,
    limit: int,
    exclusive_start_key: dict[str, Any] | None = None,
) -> tuple[list[dict[str, Any]], dict[str, Any] | None]:
    kwargs: dict[str, Any] = {
        "KeyConditionExpression": Key("PK").eq(f"TAG#{tag.lower()}"),
        "Limit": limit,
        "ScanIndexForward": False,
    }
    if exclusive_start_key:
        kwargs["ExclusiveStartKey"] = exclusive_start_key
    resp = get_table().query(**kwargs)
    items = [to_python(i) for i in resp.get("Items", [])]
    return items, resp.get("LastEvaluatedKey")


def query_user_activity(sub: str, *, limit: int = 50) -> list[dict[str, Any]]:
    resp = get_table().query(
        KeyConditionExpression=Key("PK").eq(f"USER#{sub}")
        & Key("SK").begins_with("ACTIVITY#"),
        ScanIndexForward=False,
        Limit=limit,
    )
    return [to_python(i) for i in resp.get("Items", [])]


def batch_get_routines(routine_ids: list[str]) -> list[dict[str, Any]]:
    if not routine_ids:
        return []
    keys = [{"PK": f"ROUTINE#{rid}", "SK": "METADATA"} for rid in routine_ids]
    resource = boto3.resource("dynamodb")
    resp = resource.batch_get_item(
        RequestItems={get_table_name(): {"Keys": keys}}
    )
    items = resp.get("Responses", {}).get(get_table_name(), [])
    return [to_python(i) for i in items]


def transact_write(items: list[dict[str, Any]]) -> None:
    get_table().meta.client.transact_write_items(TransactItems=items)


def query_tag_indexes_for_routine(routine_id: str) -> list[dict[str, Any]]:
    resp = get_table().scan(
        FilterExpression=Attr("EntityType").eq("RoutineTagIndex")
        & Attr("routineId").eq(routine_id),
    )
    return [to_python(i) for i in resp.get("Items", [])]


def is_conditional_check_failed(exc: Exception) -> bool:
    return (
        isinstance(exc, ClientError)
        and exc.response.get("Error", {}).get("Code") == "ConditionalCheckFailedException"
    )
