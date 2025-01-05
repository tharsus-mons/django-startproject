from ninja import NinjaAPI, Schema
from django.contrib.auth import get_user_model
from django.conf import settings

User = get_user_model()

# Choose authentication based on settings
if getattr(settings, "USE_CLERK", False):
    from .auth import ClerkAuth

    api = NinjaAPI(auth=ClerkAuth())
else:
    from ninja.security import HttpBearer
    from django.contrib.auth.models import AnonymousUser

    class BearerAuth(HttpBearer):
        def authenticate(self, request, token):
            if token == "":
                return AnonymousUser()
            return None

    api = NinjaAPI(auth=BearerAuth())


class UserSchema(Schema):
    id: str = ""
    email: str = ""
    first_name: str = ""
    last_name: str = ""
    clerk_id: str = None


@api.get("/users/me/", response=UserSchema)
def get_user(request):
    return UserSchema(
        id=request.user.id,
        email=request.user.email,
        first_name=request.user.first_name,
        last_name=request.user.last_name,
        clerk_id=getattr(request.user, "clerk_id", None),
    )


@api.patch("/users/me/")
def update_user(request, data: UserSchema):
    user = request.user
    if data.first_name:
        user.first_name = data.first_name
    if data.last_name:
        user.last_name = data.last_name
    user.save()
    return {
        "id": user.id,
        "email": user.email,
        "first_name": user.first_name,
        "last_name": user.last_name,
        "clerk_id": getattr(user, "clerk_id", None),
    }


@api.delete("/users/me/")
def delete_user(request):
    request.user.delete()
    return {"success": True}
