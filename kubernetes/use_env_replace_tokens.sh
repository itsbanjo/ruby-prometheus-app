#!/bin/bash

# Function to read a value from .env file
read_env() {
    local key=$1
    local value=$(grep "^$key:" .env | sed "s/^$key:\s*//")
    echo "$value"
}

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found!"
    exit 1
fi

# Read values from .env file
ELASTIC_APM_SECRET_TOKEN=$(read_env "ELASTIC_APM_SECRET_TOKEN")
ELASTIC_APM_SERVER_URL=$(read_env "ELASTIC_APM_SERVER_URL")

# Check if required variables are set
if [ -z "$ELASTIC_APM_SECRET_TOKEN" ]; then
    echo "Error: ELASTIC_APM_SECRET_TOKEN is not set or empty in .env file!"
    exit 1
fi

if [ -z "$ELASTIC_APM_SERVER_URL" ]; then
    echo "Error: ELASTIC_APM_SERVER_URL is not set or empty in .env file!"
    exit 1
fi

# Encode the APM token
ENCODED_TOKEN=$(echo -n "$ELASTIC_APM_SECRET_TOKEN" | base64)

# Update the Kubernetes YAML file
if [ -f kubernetes-deployment.yaml ]; then
    sed -i '' "s|ELASTIC_APM_SERVER_URL: \".*\"|ELASTIC_APM_SERVER_URL: \"$ELASTIC_APM_SERVER_URL\"|g" kubernetes-deployment.yaml
    sed -i '' "s|ELASTIC_APM_SECRET_TOKEN: .*|ELASTIC_APM_SECRET_TOKEN: $ENCODED_TOKEN|g" kubernetes-deployment.yaml
    echo "Kubernetes deployment file updated successfully!"
else
    echo "Error: kubernetes-deployment.yaml file not found!"
    exit 1
fi
