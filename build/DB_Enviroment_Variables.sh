#!/bin/bash

# Script to create environment variables for database connection

# Define the file path
ENV_FILE="/etc/environment.d/DB_Environment_Variables.conf"

# Create the directory if it doesn't exist
mkdir -p /etc/environment.d

# Prompt for environment variable values
read -rp "Enter DB_PASS: " db_pass

# Set environment variable values
db_host="127.0.0.1"
db_name="attendance"
db_user="phpmyadmin"

# Write the environment variables to the file
echo "DB_HOST='$db_host'" > "$ENV_FILE"
echo "DB_NAME='$db_name'" >> "$ENV_FILE"
echo "DB_USER='$db_user'" >> "$ENV_FILE"
echo "DB_PASS='$db_pass'" >> "$ENV_FILE"

# Set appropriate permissions
chmod 600 "$ENV_FILE"

echo "Environment variables set up successfully."
