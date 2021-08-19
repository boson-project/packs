.PHONY: go typescript

all: go typescript

go:
	pack buildpack package --path go docker.io/bosonproject/boson-go-buildpack

typescript:
	pack buildpack package --path typescript docker.io/bosonproject/boson-typescript-buildpack

push:
	docker push docker.io/bosonproject/boson-go-buildpack
	docker push docker.io/bosonproject/boson-typescript-buildpack
