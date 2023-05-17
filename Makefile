# Heroku
# make heroku-login
# make heroku-push

APP_NAME=chatgpt-retrieval-plugin
IMG ?= docker.io/apecloud/$(APP_NAME)
VERSION ?= 0.1.0

export GOPROXY = https://goproxy.cn
export GONOPROXY = github.com/apecloud
export GONOSUMDB = github.com/apecloud
export GOPRIVATE = github.com/apecloud

BUILDX_PLATFORMS ?= linux/amd64,linux/arm64
BUILDX_OUTPUT_TYPE ?= docker
BUILDX_ARGS ?= --sbom=false --provenance=false

HEROKU_APP = <your app name> 

heroku-push:
	docker buildx build --platform linux/amd64 -t ${HEROKU_APP} .
	docker tag ${HEROKU_APP} registry.heroku.com/${HEROKU_APP}/web
	docker push registry.heroku.com/${HEROKU_APP}/web
	heroku container:release web -a ${HEROKU_APP}

heroku-login:
	heroku container:login

TAG_LATEST ?= false
BUILDX_ENABLED ?= true
ifneq ($(BUILDX_ENABLED), false)
	ifeq ($(shell docker buildx inspect 2>/dev/null | awk '/Status/ { print $$2 }'), running)
		BUILDX_ENABLED ?= true
	else
		BUILDX_ENABLED ?= false
	endif
endif


.PHONY: build-image
build-image:
ifneq ($(BUILDX_ENABLED), true)
	docker build . -t ${IMG}:${VERSION} -f Dockerfile -t ${IMG}:latest
else
ifeq ($(TAG_LATEST), true)
	docker buildx build . -f Dockerfile $(DOCKER_BUILD_ARGS) --platform $(BUILDX_PLATFORMS) -t ${IMG}:latest $(BUILDX_ARGS)
else
	docker buildx build . -f Dockerfile $(DOCKER_BUILD_ARGS) --platform $(BUILDX_PLATFORMS) -t ${IMG}:${VERSION} $(BUILDX_ARGS)
endif
endif

.PHONY: push-image
push-image:
ifneq ($(BUILDX_ENABLED), true)
ifeq ($(TAG_LATEST), true)
	docker push ${IMG}:latest
else
	docker push ${IMG}:${VERSION}
endif
else
ifeq ($(TAG_LATEST), true)
	docker buildx build . -f Dockerfile $(DOCKER_BUILD_ARGS) --platform $(BUILDX_PLATFORMS) -t ${IMG}:latest --push $(BUILDX_ARGS)
else
	docker buildx build . -f Dockerfile $(DOCKER_BUILD_ARGS) --platform $(BUILDX_PLATFORMS) -t ${IMG}:${VERSION} --push $(BUILDX_ARGS)
endif
endif

