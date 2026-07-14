FROM golang:1.26@sha256:0f70d7d828acd8456022127f31975364e58d792999a7e92af6fc972e124bb6b0

WORKDIR /app

COPY go.mod ./

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
