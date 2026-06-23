from like_flush import handler
from conftest import seed_routine


def test_like_flush_applies_redis_delta(dynamodb_table, fake_redis):
    rid = seed_routine(dynamodb_table)
    fake_redis.set(f"like:{rid}", 3)
    resp = handler({}, None)
    assert resp["flushed"] == 1
    item = dynamodb_table.get_item(Key={"PK": f"ROUTINE#{rid}", "SK": "METADATA"})["Item"]
    assert int(item["likeCount"]) == 8
    assert fake_redis.get(f"like:{rid}") is None
