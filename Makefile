.PHONY: help build-image build-image-multi push-image

IMAGE_NAME := excite13/ceph-daemon
TAG := tentacle
PLATFORMS := linux/amd64,linux/arm64

## help: prints this help message
help:
	@echo "Usage:"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'

## build-image: builds the Docker image for the local platform and loads it into docker
build-image:
	cd image && docker buildx build \
		-t $(IMAGE_NAME):$(TAG) \
		--load .

## build-image-multi: builds multi-architecture image (amd64 + arm64) without loading
build-image-multi:
	cd image && docker buildx build --platform $(PLATFORMS) \
		-t $(IMAGE_NAME):$(TAG) .

## push-image: builds and pushes multi-architecture Docker image to Docker Hub
push-image:
	cd image && docker buildx build --platform $(PLATFORMS) \
		-t $(IMAGE_NAME):$(TAG) \
		--push .
