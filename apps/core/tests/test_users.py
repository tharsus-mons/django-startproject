import pytest
from django.urls import reverse
from core.models import User


@pytest.mark.django_db
class TestUserAPI:
    def test_get_user(self, authenticated_client, user):
        response = authenticated_client.get(reverse("api-1.0.0:get_user"))
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == user.email

    def test_update_user(self, authenticated_client, user):
        data = {"first_name": "Test", "last_name": "User"}
        response = authenticated_client.patch(reverse("api-1.0.0:update_user"), data)
        assert response.status_code == 200
        user.refresh_from_db()
        assert user.first_name == "Test"
        assert user.last_name == "User"

    def test_delete_user(self, authenticated_client, user):
        response = authenticated_client.delete(reverse("api-1.0.0:delete_user"))
        assert response.status_code == 200
        assert not User.objects.filter(id=user.id).exists()
