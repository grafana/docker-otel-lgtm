FROM golang:1.26@sha256:8f4cb3b8d3fd8c3e6eccfde0fcf54e8cea74fbb04cea961a92ee1a913d22cb17

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
