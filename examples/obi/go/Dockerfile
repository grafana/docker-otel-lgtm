FROM golang:1.26@sha256:595c7847cff97c9a9e76f015083c481d26078f961c9c8dca3923132f51fe12f1

WORKDIR /app

COPY go.mod ./

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
