import pytest
from django.urls import reverse
from core.models import User
from unittest.mock import patch
import json


@pytest.mark.django_db
class TestUserAPI:
    @pytest.fixture(autouse=True)
    def setup_auth(self, user):
        # Patch the authenticate method to always return our test user
        # Note: We patch the instance method, not the class method
        def authenticate(self, request, token):
            request.user = user
            return user

        patcher = patch("core.views.BearerAuth.authenticate", new=authenticate)
        patcher.start()
        self.user = user
        yield
        patcher.stop()

    def test_get_user(self, authenticated_client):
        response = authenticated_client.get(reverse("api-1.0.0:get_user"))
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == self.user.email

    def test_update_user(self, authenticated_client):
        data = {"first_name": "Test", "last_name": "User"}
        response = authenticated_client.patch(
            reverse("api-1.0.0:update_user"), data=json.dumps(data), content_type="application/json"
        )
        assert response.status_code == 200
        self.user.refresh_from_db()
        assert self.user.first_name == "Test"
        assert self.user.last_name == "User"

    def test_delete_user(self, authenticated_client):
        response = authenticated_client.delete(reverse("api-1.0.0:delete_user"))
        assert response.status_code == 200
        assert not User.objects.filter(id=self.user.id).exists()
