FROM golang:1.26@sha256:46d487a9216d9d3563ae7be4ee0f6a4aa9a3f6befdf62c384fd5118a7e254c4d

WORKDIR /app

COPY go.mod ./

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
