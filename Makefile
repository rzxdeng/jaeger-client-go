PACKAGES := $(shell glide novendor | grep -v ./thrift/...)

export GO15VENDOREXPERIMENT=1

GOTEST=go test -v
GOLINT=golint
GOVET=go vet
GOFMT=go fmt
XDOCK_YAML=crossdock/docker-compose.yml

.PHONY: test
test:
	$(GOTEST) $(PACKAGES)


.PHONY: fmt
fmt:
	$(GOFMT) $(PACKAGES)


.PHONY: lint
lint:
	$(foreach pkg, $(PACKAGES), $(GOLINT) $(pkg) | grep -v crossdock/thrift || true;)
	$(GOVET) $(PACKAGES)


.PHONY: install
install:
	glide --version || go get github.com/Masterminds/glide
	glide install


.PHONY: cover
cover:
	./scripts/cover.sh $(shell go list $(PACKAGES))
	go tool cover -html=cover.out -o cover.html


# This is not part of the regular test target because we don't want to slow it
# down.
.PHONY: test-examples
test-examples:
	make -C examples


.PHONY: bins
bins:
	CGO_ENABLED=0 GOOS=linux time go build -a -installsuffix cgo -o crossdock/crossdock ./crossdock


.PHONY: crossdock
crossdock: bins
	docker-compose -f $(XDOCK_YAML) kill go
	docker-compose -f $(XDOCK_YAML) rm -f go
	docker-compose -f $(XDOCK_YAML) build go
	docker-compose -f $(XDOCK_YAML) run crossdock


.PHONY: crossdock-fresh
crossdock-fresh: bins
	docker-compose -f $(XDOCK_YAML) kill
	docker-compose -f $(XDOCK_YAML) rm --force
	docker-compose -f $(XDOCK_YAML) pull
	docker-compose -f $(XDOCK_YAML) build
	docker-compose -f $(XDOCK_YAML) run crossdock


.PHONY: install_ci
install_ci: install
	go get github.com/wadey/gocovmerge
	go get github.com/mattn/goveralls
	go get golang.org/x/tools/cmd/cover


.PHONY: test_ci
test_ci:
	@./scripts/cover.sh $(shell go list $(PACKAGES))
