FROM golang:1.26@sha256:dd25c49df34a6ec745f1dd59593478d067679e8e8fb1e44b326d8b9e2d348777

WORKDIR /app

COPY go.mod ./

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
