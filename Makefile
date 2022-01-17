PACK_CMD?=pack

GIT_TAG := $(shell git tag --points-at HEAD)
VERSION_TAG := $(shell [ -z $(GIT_TAG) ] && echo 'tip' || echo $(GIT_TAG) )

.PHONY: builders buildpacks publish test

all: buildpacks builders

buildpacks:
	./hack/make.sh buildpacks $(VERSION_TAG)

builders:
	./hack/make.sh builders $(VERSION_TAG)

publish: all
	./hack/make.sh publish $(VERSION_TAG)

test: all
	VERSION_TAG=$(VERSION_TAG) go test -v ./test/...
