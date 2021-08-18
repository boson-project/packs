.PHONY: go typescript

all: go typescript

go:
	pack buildpack package --path go docker.io/lanceball/boson-go

typescript:
	pack buildpack package --path typescript docker.io/lanceball/boson-typescript

push:
	docker push docker.io/lanceball/boson-go
	docker push docker.io/lanceball/boson-typescript
