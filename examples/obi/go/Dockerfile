FROM golang:1.26@sha256:b004b9c35c68c8bcf5420e5164423073a1de5f0c7d4b9121784780ceb7f9961f

WORKDIR /app

COPY go.mod ./

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
