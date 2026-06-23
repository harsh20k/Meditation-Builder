"""Pytest fixtures for Lambda unit tests."""

from __future__ import annotations

import json
import os
import sys
import uuid
from datetime import datetime, timezone

import boto3
import fakeredis
import pytest
from moto import mock_aws

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
HANDLERS = os.path.join(ROOT, "handlers")
SHARED = os.path.join(ROOT, "shared")
for path in (ROOT, HANDLERS, SHARED):
    if path not in sys.path:
        sys.path.insert(0, path)

TABLE_NAME = "mb-test-community"


@pytest.fixture(autouse=True)
def env_vars(monkeypatch):
    monkeypatch.setenv("DYNAMODB_TABLE_NAME", TABLE_NAME)
    monkeypatch.setenv("AWS_DEFAULT_REGION", "us-east-1")
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "testing")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "testing")
    monkeypatch.setenv("REDIS_HOST", "localhost")
    monkeypatch.setenv("REDIS_PORT", "6379")
    monkeypatch.setenv("TYPESENSE_HOST", "localhost")
    monkeypatch.setenv("TYPESENSE_API_KEY", "test-key")
    monkeypatch.setenv("SQS_TAGGING_QUEUE_URL", "https://sqs.us-east-1.amazonaws.com/123/tagging")
    monkeypatch.setenv("SNS_LIKE_TOPIC_ARN", "arn:aws:sns:us-east-1:123:likes")
    monkeypatch.setenv("CLOUDFRONT_DISTRIBUTION_ID", "E123456")


@pytest.fixture
def aws_mock(env_vars):
    with mock_aws():
        yield


@pytest.fixture
def dynamodb_table(aws_mock):
    from shared import dynamo

    dynamo.reset_table()
    resource = boto3.resource("dynamodb", region_name="us-east-1")
    resource.create_table(
        TableName=TABLE_NAME,
        KeySchema=[
            {"AttributeName": "PK", "KeyType": "HASH"},
            {"AttributeName": "SK", "KeyType": "RANGE"},
        ],
        AttributeDefinitions=[
            {"AttributeName": "PK", "AttributeType": "S"},
            {"AttributeName": "SK", "AttributeType": "S"},
            {"AttributeName": "GSI1PK", "AttributeType": "S"},
            {"AttributeName": "publishedAt", "AttributeType": "S"},
            {"AttributeName": "GSI2PK", "AttributeType": "S"},
        ],
        GlobalSecondaryIndexes=[
            {
                "IndexName": "GSI1-public-by-date",
                "KeySchema": [
                    {"AttributeName": "GSI1PK", "KeyType": "HASH"},
                    {"AttributeName": "publishedAt", "KeyType": "RANGE"},
                ],
                "Projection": {
                    "ProjectionType": "INCLUDE",
                    "NonKeyAttributes": [
                        "routineId",
                        "name",
                        "authorName",
                        "durationSeconds",
                        "tags",
                        "likeCount",
                        "importCount",
                    ],
                },
            },
            {
                "IndexName": "GSI2-author-routines",
                "KeySchema": [
                    {"AttributeName": "GSI2PK", "KeyType": "HASH"},
                    {"AttributeName": "publishedAt", "KeyType": "RANGE"},
                ],
                "Projection": {"ProjectionType": "ALL"},
            },
        ],
        BillingMode="PAY_PER_REQUEST",
    )
    sqs = boto3.client("sqs", region_name="us-east-1")
    sqs.create_queue(QueueName="tagging")
    sns = boto3.client("sns", region_name="us-east-1")
    sns.create_topic(Name="likes")
    cf = boto3.client("cloudfront", region_name="us-east-1")
    cf.create_distribution(
        DistributionConfig={
            "CallerReference": "test",
            "Origins": {
                "Quantity": 1,
                "Items": [
                    {
                        "Id": "api",
                        "DomainName": "example.com",
                        "CustomOriginConfig": {
                            "HTTPPort": 80,
                            "HTTPSPort": 443,
                            "OriginProtocolPolicy": "https-only",
                        },
                    }
                ],
            },
            "DefaultCacheBehavior": {
                "TargetOriginId": "api",
                "ViewerProtocolPolicy": "allow-all",
                "ForwardedValues": {"QueryString": True, "Cookies": {"Forward": "none"}},
                "MinTTL": 0,
            },
            "Comment": "test",
            "Enabled": True,
        }
    )
    yield resource.Table(TABLE_NAME)


@pytest.fixture
def fake_redis(monkeypatch):
    from shared import redis_client

    client = fakeredis.FakeRedis(decode_responses=True)
    monkeypatch.setattr(redis_client, "_client", client)
    yield client
    redis_client.reset_redis()


def auth_event(
    *,
    method: str = "GET",
    path: str = "/v1/routines",
    path_parameters: dict | None = None,
    query: dict | None = None,
    body: dict | None = None,
    sub: str | None = "user-sub-1",
) -> dict:
    event = {
        "httpMethod": method,
        "path": path,
        "pathParameters": path_parameters or {},
        "queryStringParameters": query,
        "headers": {"X-Request-Id": "req-test-1"},
        "requestContext": {"requestId": "req-test-1"},
    }
    if sub:
        event["requestContext"]["authorizer"] = {
            "claims": {"sub": sub, "name": "Test User"}
        }
    if body is not None:
        event["body"] = json.dumps(body)
    return event


def seed_routine(table, *, routine_id: str | None = None, author_sub: str = "author-1") -> str:
    rid = routine_id or str(uuid.uuid4())
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    table.put_item(
        Item={
            "PK": f"ROUTINE#{rid}",
            "SK": "METADATA",
            "EntityType": "Routine",
            "routineId": rid,
            "authorSub": author_sub,
            "authorName": "Jane D.",
            "name": "Morning Focus",
            "description": "A gentle focus routine.",
            "tags": {"focus", "morning"},
            "durationSeconds": 600,
            "blocks": json.dumps([{"blockId": "b1", "type": "timer", "durationSeconds": 300}]),
            "likeCount": 5,
            "importCount": 2,
            "publishedAt": now,
            "updatedAt": now,
            "isPublic": True,
            "GSI1PK": "PUBLIC",
            "GSI2PK": f"USER#{author_sub}",
        }
    )
    return rid
