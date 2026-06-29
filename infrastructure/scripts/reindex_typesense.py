#!/usr/bin/env python3
"""Trigger Typesense re-index by bumping updatedAt on all public Routine items."""

from __future__ import annotations

import argparse
import os
from datetime import datetime, timezone

import boto3
from boto3.dynamodb.conditions import Attr


def _table_name(env: str) -> str:
    return os.environ.get("DYNAMODB_TABLE_NAME", f"mb-{env}-community")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--env", default="staging")
    args = parser.parse_args()

    table = boto3.resource("dynamodb").Table(_table_name(args.env))
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    updated = 0

    scan_kwargs: dict = {
        "FilterExpression": Attr("EntityType").eq("Routine") & Attr("isPublic").eq(True),
    }
    while True:
        resp = table.scan(**scan_kwargs)
        for item in resp.get("Items", []):
            table.update_item(
                Key={"PK": item["PK"], "SK": item["SK"]},
                UpdateExpression="SET updatedAt = :stamp",
                ExpressionAttributeValues={":stamp": stamp},
            )
            updated += 1
        token = resp.get("LastEvaluatedKey")
        if not token:
            break
        scan_kwargs["ExclusiveStartKey"] = token

    print(f"Triggered reindex for {updated} routines (updatedAt={stamp})")


if __name__ == "__main__":
    main()
