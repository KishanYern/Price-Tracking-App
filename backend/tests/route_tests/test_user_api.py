import pytest
import uuid
from app.schemas.user import UserOut

DELETE_USER_SUCCESS_MESSAGE = {"message": "User deleted successfully"}
INVALID_CREDENTIALS_ERROR = {"detail": "Invalid credentials"}
EMAIL_ALREADY_REGISTERED_MESSAGE = {"detail": "Email already registered"}

def test_create_user(test_client):
    """
    Test the create_user endpoint.
    """
    user_data = {
        "email": f"test_user_{uuid.uuid4()}@example.com",
        "password": "securepassword123"
    }
    response = test_client.post("/users/create", json=user_data)

    # Validate the response
    assert response.status_code == 201
    user = response.json()
    validated_user = UserOut(**user)
    assert validated_user.id is not None
    assert validated_user.email == user_data["email"]

def test_get_all_users(test_client):
    """
    Test the get_all_users endpoint.
    """
    response = test_client.get("/users/")
    assert response.status_code == 200
    users = response.json()

    # Validate that the response is a list of UserOut schemas
    # Validate that the response is a list of users with required fields
    assert isinstance(users, list)
    for user in users:
        assert "id" in user and user["id"] is not None
        assert "email" in user and user["email"] is not None
        validated_user = UserOut(**user)
        assert isinstance(validated_user, UserOut)
        assert validated_user.id is not None
        assert validated_user.email is not None

def test_get_user(test_client):
    """
    Test the get_user endpoint. 
    First we create a user, then attempt to retrieve that user_id
    """
    user_data = {
        "email": f"test_user_{uuid.uuid4()}@example.com",
        "password": "securepassword123"
    }

    # First we create a user
    create_user_response = test_client.post("/users/create", json=user_data)
    assert create_user_response.status_code == 201
    created_user = create_user_response.json()
    user_id = created_user['id']

    # Now we retrieve the user by ID
    get_user_response = test_client.get(f"/users/{user_id}")
    assert get_user_response.status_code == 200
    user = get_user_response.json()

    # Validate the retrieved user
    validated_user = UserOut(**user)
    assert isinstance(validated_user, UserOut)
    assert validated_user.id is not None
    assert validated_user.email is not None
    assert validated_user.id == user_id
    assert validated_user.email == user_data["email"]

def test_update_user(test_client):
    """
    Test the update_user endpoint.
    First we create a user, then update that user's email and password.
    """
    user_data = {
        "email": f"test_user_{uuid.uuid4()}@example.com",
        "password": "securepassword123"
    }

    # Create a user
    create_user_response = test_client.post("/users/create", json=user_data)
    assert create_user_response.status_code == 201
    created_user = create_user_response.json()
    user_id = created_user['id']

    # Update the user's email and password
    updated_data = {
        "email": f"updated_user_{uuid.uuid4()}@example.com",
        "password": "newsecurepassword"
    }
    update_response = test_client.put(f"/users/{user_id}", json=updated_data)
    assert update_response.status_code == 200
    updated_user = update_response.json()

    # Validate the updated user
    validated_user = UserOut(**updated_user)
    assert isinstance(validated_user, UserOut)
    assert validated_user.id == user_id
    assert validated_user.email == updated_data["email"]

def test_delete_user(test_client):
    """
    Test the delete_user endpoint.
    First we create a user, then delete that user by ID.
    """
    user_data = {
        "email": f"test_user_{uuid.uuid4()}@example.com",
        "password": "securepassword123"
    }

    # Create a user
    create_user_response = test_client.post("/users/create", json=user_data)
    assert create_user_response.status_code == 201
    created_user = create_user_response.json()
    user_id = created_user['id']

    # Delete the user
    delete_response = test_client.delete(f"/users/{user_id}")
    assert delete_response.status_code == 200
    assert delete_response.json() == DELETE_USER_SUCCESS_MESSAGE

    # Attempt to retrieve the deleted user
    get_user_response = test_client.get(f"/users/{user_id}")
    assert get_user_response.status_code == 404

    # Validate the error message
    error_detail = get_user_response.json().get("detail", "")
    assert "user" in error_detail and "ID" in error_detail
    assert get_user_response.status_code == 404
    assert get_user_response.json() == {"detail": "There is no user with this ID"}

def test_create_user_with_existing_email(test_client):
    """
    Test creating a user with an email that already exists.
    """
    user_data = {
        "email": f"test_user_{uuid.uuid4()}@example.com",
        "password": "securepassword123"
    }

    # Create the first user
    create_user_response = test_client.post("/users/create", json=user_data)
    assert create_user_response.status_code == 201

    # Attempt to create a second user with the same email
    duplicate_response = test_client.post("/users/create", json=user_data)
    assert duplicate_response.status_code == 400
    assert duplicate_response.json() == EMAIL_ALREADY_REGISTERED_MESSAGE
    assert duplicate_response.json() == {"detail": "Email already registered"}

def test_login_user(test_client):
    """
    Test the login_user endpoint.
    First we create a user, then attempt to log in with that user's credentials.
    """
    user_data = {
        "email": f"test_user_{uuid.uuid4()}@example.com",
        "password": "securepassword123"
    }

    # Create a user
    create_user_response = test_client.post("/users/create", json=user_data)
    assert create_user_response.status_code == 201
    created_user = create_user_response.json()

    # Log in with the user's credentials
    login_response = test_client.post("/users/login", json={
        "email": user_data["email"],
        "password": user_data["password"]
    })
    assert login_response.status_code == 200
    logged_in_user = login_response.json()

    # Validate the logged-in user
    validated_user = UserOut(**logged_in_user)
    assert isinstance(validated_user, UserOut)
    assert validated_user.id == created_user['id']
    assert validated_user.email == user_data["email"]

    # Try to log in with incorrect credentials
    incorrect_login_response = test_client.post("/users/login", json={
        "email": user_data["email"],
        "password": "wrongpassword"
    })
    assert incorrect_login_response.status_code == 400
    assert incorrect_login_response.json() == INVALID_CREDENTIALS_ERROR
    assert incorrect_login_response.status_code == 400
    assert incorrect_login_response.json() == {'detail': 'Invalid credentials'}

