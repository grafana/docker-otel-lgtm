FROM golang:1.26@sha256:792443b89f65105abba56b9bd5e97f680a80074ac62fc844a584212f8c8102c3

WORKDIR /app

COPY go.mod ./

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
