#!/bin/bash

export VERSION=`cat version`

# Set up environment
docker version
docker buildx ls
docker buildx create --name sendy-docker-builder
docker buildx use sendy-docker-builder

echo "Building: Sendy Docker Container for Kubernetes"
docker buildx build --platform linux/amd64,linux/arm64 -t "jotcode/sendy-docker:${VERSION}" -t jotcode/sendy-docker:latest --push .

