FROM golang:1.15 AS builder

WORKDIR /go/src/github.com/ysoftdevs/secret-duplicator
COPY . .
RUN make build

FROM alpine:3.13.4 as base
COPY --from=builder /go/src/github.com/ysoftdevs/secret-duplicator/build/_output/bin/secret-duplicator /usr/local/bin/secret-duplicator

ENTRYPOINT ["secret-duplicator"]