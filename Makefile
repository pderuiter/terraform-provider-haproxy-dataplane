.PHONY: fmt test build

fmt:
	gofmt -w $(shell find . -name '*.go' -not -path './vendor/*')

build:
	go build ./...

test:
	go test ./...
