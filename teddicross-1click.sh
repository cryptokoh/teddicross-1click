#!/bin/bash

# One-click installer for TediCross with Docker
echo "==============================="
echo "TediCross Docker Installer"
echo "==============================="

# Prompt to update and upgrade the system
read -p "Would you like to update and upgrade the system packages? (y/n): " UPDATE_CHOICE
if [[ "$UPDATE_CHOICE" == "y" || "$UPDATE_CHOICE" == "Y" ]]; then
    echo "Updating and upgrading system packages..."
    sudo apt update && sudo apt upgrade -y
else
    echo "Skipping system update and upgrade."
fi

# Install required dependencies
echo "Installing required dependencies..."
sudo apt install -y curl git docker.io docker-compose

# Check for Node.js installation and install if missing
if ! command -v node &> /dev/null; then
    echo "Node.js is not installed. Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
else
    echo "Node.js is already installed."
fi

# Check for Docker and Docker Compose
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing Docker..."
    sudo apt install -y docker.io
else
    echo "Docker is already installed."
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Installing Docker Compose..."
    sudo apt install -y docker-compose
else
    echo "Docker Compose is already installed."
fi

# Start Docker and enable it at boot
echo "Starting and enabling Docker..."
sudo systemctl start docker
sudo systemctl enable docker

# Pull the TediCross repository
echo "Cloning the TediCross repository..."
if [ ! -d "TediCross" ]; then
    git clone https://github.com/TediCross/TediCross.git
else
    echo "TediCross repository already exists, skipping clone."
fi

cd TediCross || exit

# Prompt for user input
echo "Enter the required keys for TediCross:"
read -p "Telegram Bot API Key: " TELEGRAM_TOKEN
read -p "Discord Bot Token: " DISCORD_TOKEN
read -p "Discord Server ID: " DISCORD_SERVER_ID
read -p "Discord Channel ID: " DISCORD_CHANNEL_ID

# Create settings.yaml file
echo "Creating settings.yaml file..."
cat >settings.yaml <<EOL
telegram:
  token: "$TELEGRAM_TOKEN"

discord:
  token: "$DISCORD_TOKEN"
  guild: "$DISCORD_SERVER_ID"
  channel: "$DISCORD_CHANNEL_ID"

debug:
  enabled: false
EOL

# Create Dockerfile
echo "Creating Dockerfile..."
cat >Dockerfile <<EOL
FROM node:18-alpine
WORKDIR /app
COPY . .
RUN npm install --omit=dev
CMD ["npm", "start"]
EOL

# Create docker-compose.yml file
echo "Creating docker-compose.yml file..."
cat >docker-compose.yml <<EOL
version: '3.8'
services:
  tedicross:
    build: .
    volumes:
      - ./settings.yaml:/app/settings.yaml
    restart: unless-stopped
EOL

# Build and start the Docker container
echo "Building and starting the TediCross Docker container..."
sudo docker-compose up --build -d

# Provide feedback to the user
echo "==============================="
echo "TediCross is now running in Docker!"
echo "Telegram Bot API: $TELEGRAM_TOKEN"
echo "Discord Bot Token: $DISCORD_TOKEN"
echo "Discord Server ID: $DISCORD_SERVER_ID"
echo "Discord Channel ID: $DISCORD_CHANNEL_ID"
echo "==============================="
echo "To stop the bot, run: sudo docker-compose down"
echo "To restart the bot, run: sudo docker-compose up -d"
