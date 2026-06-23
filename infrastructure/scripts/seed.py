#!/usr/bin/env python3
"""Seed or teardown DynamoDB, Typesense, and Cognito test data."""

from __future__ import annotations

import argparse
import json
import os
import secrets
import string
import sys
import uuid
from datetime import datetime, timezone

import boto3
import requests

DEFAULT_COUNT = 20
TAG_POOL = ["focus", "sleep", "calm", "morning", "evening", "breath", "energy"]
TEST_USERS = [
    {"username": "testuser1@mb.test", "email": "testuser1@mb.test", "ssm_key": "user1-password"},
    {"username": "testuser2@mb.test", "email": "testuser2@mb.test", "ssm_key": "user2-password"},
]


def _now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _table_name(env: str) -> str:
    return os.environ.get("DYNAMODB_TABLE_NAME", f"mb-{env}-community")


def _typesense_base(env: str) -> str:
    host = os.environ.get("TYPESENSE_HOST", f"typesense.{env}.meditationbuilder.internal")
    port = os.environ.get("TYPESENSE_PORT", "8108")
    protocol = os.environ.get("TYPESENSE_PROTOCOL", "http")
    return f"{protocol}://{host}:{port}"


def _typesense_headers() -> dict[str, str]:
    return {
        "X-TYPESENSE-API-KEY": os.environ.get("TYPESENSE_API_KEY", ""),
        "Content-Type": "application/json",
    }


def _routine_item(env: str, idx: int, author: dict[str, str]) -> dict:
    routine_id = str(uuid.uuid4())
    published_at = _now()
    tags = TAG_POOL[idx % len(TAG_POOL) : idx % len(TAG_POOL) + 2]
    name = f"Seed Routine {idx + 1}"
    return {
        "PK": f"ROUTINE#{routine_id}",
        "SK": "METADATA",
        "EntityType": "Routine",
        "routineId": routine_id,
        "authorSub": author["sub"],
        "authorName": author["displayName"],
        "name": name,
        "description": f"Seeded routine {idx + 1} for {env} testing.",
        "tags": set(tags),
        "durationSeconds": 300 + (idx * 60),
        "blocks": json.dumps(
            [
                {"blockId": "b1", "type": "timer", "durationSeconds": 180, "label": "Breath"},
                {"blockId": "b2", "type": "bell", "soundKey": "singing_bowl_c", "label": "Bell"},
            ]
        ),
        "audioAssetKeys": set(),
        "likeCount": idx,
        "importCount": max(0, idx // 4),
        "publishedAt": published_at,
        "updatedAt": published_at,
        "isPublic": True,
        "typesenseSynced": True,
        "GSI1PK": "PUBLIC",
        "GSI2PK": f"USER#{author['sub']}",
        "seeded": True,
        "taggingStatus": "complete",
    }


def _tag_items(routine: dict) -> list[dict]:
    items = []
    for tag in routine["tags"]:
        items.append(
            {
                "PK": f"TAG#{tag}",
                "SK": f"{routine['publishedAt']}#{routine['routineId']}",
                "EntityType": "RoutineTagIndex",
                "routineId": routine["routineId"],
                "name": routine["name"],
                "authorName": routine["authorName"],
                "durationSeconds": routine["durationSeconds"],
                "likeCount": routine["likeCount"],
                "seeded": True,
            }
        )
    return items


def _user_item(user: dict[str, str]) -> dict:
    return {
        "PK": f"USER#{user['sub']}",
        "SK": "PROFILE",
        "EntityType": "User",
        "sub": user["sub"],
        "displayName": user["displayName"],
        "publishCount": 0,
        "importCount": 0,
        "joinedAt": _now(),
        "seeded": True,
    }


def _typesense_doc(routine: dict) -> dict:
    dt = datetime.fromisoformat(routine["publishedAt"].replace("Z", "+00:00"))
    return {
        "id": routine["routineId"],
        "name": routine["name"],
        "description": routine["description"],
        "tags": list(routine["tags"]),
        "durationSeconds": int(routine["durationSeconds"]),
        "authorName": routine["authorName"],
        "likeCount": int(routine["likeCount"]),
        "importCount": int(routine["importCount"]),
        "publishedAt": int(dt.timestamp()),
    }


def _random_password(length: int = 16) -> str:
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
    return "".join(secrets.choice(alphabet) for _ in range(length))


def ensure_cognito_users(env: str, users: list[dict[str, str]]) -> None:
    pool_id = os.environ["COGNITO_USER_POOL_ID"]
    client = boto3.client("cognito-idp")
    ssm = boto3.client("ssm")
    for spec in TEST_USERS:
        password = _random_password()
        try:
            resp = client.admin_create_user(
                UserPoolId=pool_id,
                Username=spec["username"],
                UserAttributes=[
                    {"Name": "email", "Value": spec["email"]},
                    {"Name": "email_verified", "Value": "true"},
                ],
                MessageAction="SUPPRESS",
            )
            sub = next(a["Value"] for a in resp["User"]["Attributes"] if a["Name"] == "sub")
        except client.exceptions.UsernameExistsException:
            resp = client.admin_get_user(UserPoolId=pool_id, Username=spec["username"])
            sub = next(a["Value"] for a in resp["UserAttributes"] if a["Name"] == "sub")
            password = ssm.get_parameter(Name=f"/mb/{env}/test/{spec['ssm_key']}", WithDecryption=True)[
                "Parameter"
            ]["Value"]
        else:
            client.admin_set_user_password(
                UserPoolId=pool_id,
                Username=spec["username"],
                Password=password,
                Permanent=True,
            )
            ssm.put_parameter(
                Name=f"/mb/{env}/test/{spec['ssm_key']}",
                Value=password,
                Type="SecureString",
                Overwrite=True,
            )
        users.append(
            {
                "sub": sub,
                "username": spec["username"],
                "displayName": spec["username"].split("@")[0].title(),
            }
        )


def seed(env: str, count: int) -> list[str]:
    table = boto3.resource("dynamodb").Table(_table_name(env))
    users: list[dict[str, str]] = []
    if os.environ.get("COGNITO_USER_POOL_ID"):
        ensure_cognito_users(env, users)
    else:
        users = [
            {"sub": "seed-user-1", "username": "testuser1@mb.test", "displayName": "Test User 1"},
            {"sub": "seed-user-2", "username": "testuser2@mb.test", "displayName": "Test User 2"},
        ]

    routine_ids: list[str] = []
    for user in users:
        table.put_item(Item=_user_item(user))

    for idx in range(count):
        author = users[idx % len(users)]
        routine = _routine_item(env, idx, author)
        table.put_item(Item=routine)
        for tag_item in _tag_items(routine):
            table.put_item(Item=tag_item)
        routine_ids.append(routine["routineId"])

        base = _typesense_base(env)
        if os.environ.get("TYPESENSE_API_KEY"):
            requests.post(
                f"{base}/collections/routines/documents",
                headers=_typesense_headers(),
                json=_typesense_doc(routine),
                timeout=10,
            )

    # 5 likes across routines
    for i, rid in enumerate(routine_ids[:5]):
        liker = users[(i + 1) % len(users)]
        table.put_item(
            Item={
                "PK": f"USER#{liker['sub']}",
                "SK": f"LIKE#{rid}",
                "EntityType": "Like",
                "routineId": rid,
                "likedAt": _now(),
                "seeded": True,
            }
        )

    # 3 imports
    for i, rid in enumerate(routine_ids[:3]):
        importer = users[i % len(users)]
        table.put_item(
            Item={
                "PK": f"USER#{importer['sub']}",
                "SK": f"IMPORT#{rid}",
                "EntityType": "ImportRecord",
                "routineId": rid,
                "importedAt": _now(),
                "seeded": True,
            }
        )

    print(json.dumps({"seededRoutineIds": routine_ids, "users": users}, indent=2))
    return routine_ids


def teardown(env: str) -> None:
    table = boto3.resource("dynamodb").Table(_table_name(env))
    scan_kwargs = {"FilterExpression": "attribute_exists(seeded) AND seeded = :true", "ExpressionAttributeValues": {":true": True}}
    deleted = 0
    while True:
        resp = table.scan(**scan_kwargs)
        for item in resp.get("Items", []):
            table.delete_item(Key={"PK": item["PK"], "SK": item["SK"]})
            deleted += 1
            if item.get("EntityType") == "Routine":
                rid = item.get("routineId")
                base = _typesense_base(env)
                if rid and os.environ.get("TYPESENSE_API_KEY"):
                    try:
                        requests.delete(
                            f"{base}/collections/routines/documents/{rid}",
                            headers=_typesense_headers(),
                            timeout=10,
                        )
                    except requests.RequestException:
                        pass
        if "LastEvaluatedKey" not in resp:
            break
        scan_kwargs["ExclusiveStartKey"] = resp["LastEvaluatedKey"]
    print(json.dumps({"deleted": deleted}))


def main() -> int:
    parser = argparse.ArgumentParser(description="Seed or teardown Meditation Builder test data")
    parser.add_argument("--env", default="staging", choices=["staging", "production"])
    parser.add_argument("--count", type=int, default=DEFAULT_COUNT)
    parser.add_argument("--teardown", action="store_true")
    args = parser.parse_args()
    if args.teardown:
        teardown(args.env)
    else:
        seed(args.env, args.count)
    return 0


if __name__ == "__main__":
    sys.exit(main())
