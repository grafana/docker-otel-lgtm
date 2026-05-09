FROM golang:1.26@sha256:257c1f60c465aa5d22b4d81f9ae73643a12f228a10165c658ec77bd6ff791f34

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
