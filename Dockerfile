ARG GOLANG_VERSION
FROM golang:${GOLANG_VERSION} as builder

WORKDIR /project

# Install app dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy golang source code from the host
COPY ./ ./
RUN make build

ARG TARGETARCH
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-${TARGETARCH} /tini
RUN chmod +x /tini

# STEP 2 Build a small image
FROM debian:buster-slim

WORKDIR /project
COPY --from=builder /tini /
COPY --from=builder /project/bin/cmd/app ./

ENTRYPOINT ["/tini", "--", "/project/app"]