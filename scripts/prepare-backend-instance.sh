#!/usr/bin/env bash
set -euo pipefail

# Run on the BACKEND EC2 instance only.
sudo mkdir -p /opt/pricepulse
sudo touch /opt/pricepulse/backend.env
sudo chown root:root /opt/pricepulse/backend.env
sudo chmod 600 /opt/pricepulse/backend.env

echo "Created /opt/pricepulse/backend.env"
echo "Now copy your current backend production environment values into it."
echo "Required values include DATABASE_URL, SECRET_KEY, ALGORITHM,"
echo "ACCESS_TOKEN_EXPIRE_MINUTES, ALLOWED_CORS_ORIGINS, FRONTEND_DOMAIN,"
echo "and any proxy credentials used by PricePulse."
