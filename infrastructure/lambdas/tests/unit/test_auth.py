from unittest.mock import patch

import pytest
from jose import JWTError

from shared import auth


def test_optional_sub_from_authorizer():
    event = {"requestContext": {"authorizer": {"claims": {"sub": "user-1"}}}}
    sub, invalid = auth.optional_sub(event)
    assert sub == "user-1"
    assert invalid is False


def test_optional_sub_no_auth():
    sub, invalid = auth.optional_sub({})
    assert sub is None
    assert invalid is False


def test_optional_sub_invalid_bearer():
    event = {"headers": {"Authorization": "Bearer bad-token"}}
    with patch.object(auth, "_verify_cognito_token", side_effect=JWTError("bad")):
        sub, invalid = auth.optional_sub(event)
    assert sub is None
    assert invalid is True


def test_get_sub_from_bearer():
    event = {"headers": {"authorization": "Bearer good-token"}}
    with patch.object(auth, "_verify_cognito_token", return_value={"sub": "user-2"}):
        assert auth.get_sub(event) == "user-2"
