import pytest
from django.contrib.auth import get_user_model
from uuid import uuid4
from django.test import Client

User = get_user_model()


@pytest.fixture
def user():
    return User.objects.create(id=str(uuid4()), email="test@example.com")


@pytest.fixture
def authenticated_client():
    return Client(headers={"authorization": "Bearer dummy-token"})
