from ninja.security import HttpBearer
from django.conf import settings
from uuid import uuid4
from django.contrib.auth import get_user_model

User = get_user_model()

try:
    from clerk_backend_api import Clerk
    from clerk_backend_api.jwks_helpers import AuthenticateRequestOptions
    CLERK_AVAILABLE = True
except ImportError:
    CLERK_AVAILABLE = False


def decode_jwt(token):
    """Decode JWT token - implement your own logic here if not using Clerk"""
    if CLERK_AVAILABLE:
        # This is a placeholder - Clerk's actual JWT decoding happens in authenticate
        return {"sub": token}
    return {"sub": token}  # Implement your own JWT decoding here


class ClerkAuth(HttpBearer):
    def authenticate(self, request, token):
        if not CLERK_AVAILABLE:
            return None

        if not (settings.CLERK_SECRET_KEY and settings.CLERK_JWT_KEY):
            return None

        sdk = Clerk(bearer_auth=settings.CLERK_SECRET_KEY)
        request_state = sdk.authenticate_request(request, AuthenticateRequestOptions(jwt_key=settings.CLERK_JWT_KEY))

        if request_state.is_signed_in:
            clerk_id = decode_jwt(token)["sub"]
            user, created = User.objects.get_or_create(
                clerk_id=clerk_id,
                defaults={
                    "id": str(uuid4()),
                    "email": f"{clerk_id}@temporary.com",
                },
            )

            if created:
                # Only fetch and update email if this is a new user
                clerk_user = sdk.users.get(user_id=clerk_id)
                email = sdk.email_addresses.get(email_address_id=clerk_user.primary_email_address_id).email_address
                user.email = email
                user.save()

            request.user = user
            return token
        return None 