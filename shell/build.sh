#!/usr/bin/env bash
set -e

IMAGE_NAME="aiyf:latest"

echo "🚧 Building $IMAGE_NAME..."
docker build -f Dockerfile -t "$IMAGE_NAME" .

echo "✅ Build complete."

