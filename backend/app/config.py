import os
from dotenv import load_dotenv

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES"))

ALLOWED_CORS_ORIGINS_STR = os.getenv(
    "ALLOWED_CORS_ORIGINS",
    "http://localhost:5173,http://localhost:3000,http://127.0.0.1:5173,http://127.0.0.1:3000"
)

ALLOWED_CORS_ORIGINS = [
    origin.strip() for origin in ALLOWED_CORS_ORIGINS_STR.split(',') if origin.strip()
]