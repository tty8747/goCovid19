include .env

.DEFAULT_GOAL := all

# the same that .DEFAULT_GOAL for older version of make (<= 3.80)
# .PHONY: default
# default: clean;

.PHONY: all
all: build run

.PHONY: build
build:
	$(info -> build:)
	go mod tidy
	mkdir -p ./bin
	GOARCH=amd64 GOOS=linux go build -o ./bin/${BINARY_NAME}-linux ${PATH_TO_SOURCE}

.PHONY: run
run:
	$(info -> run:)
	./bin/${BINARY_NAME}-linux

.PHONY: clean
clean:
	$(info -> clean:)
	go clean
	rm ./bin/${BINARY_NAME}-linux

.PHONY: messages
messages:
	$(info test info message)
	$(warning test warning message)
	$(error test error message)
