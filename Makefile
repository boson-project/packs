PACK_CMD?=pack

GIT_TAG := $(shell git tag --points-at HEAD)
VERSION_TAG := $(shell [ -z $(GIT_TAG) ] && echo 'tip' || echo $(GIT_TAG) )

.PHONY: buildpacks publish test

all: buildpacks

buildpacks:
	./hack/make.sh buildpacks $(VERSION_TAG)

publish:
	./hack/make.sh publish $(VERSION_TAG)

test: buildpacks
	# The tests in make.sh cover the base boson-function-buildpack image
	./hack/make.sh test $(VERSION_TAG)
	# The go tests integration with kn-plugin-func
	VERSION_TAG=$(VERSION_TAG) go test -v ./test/...