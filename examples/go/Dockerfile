FROM golang:1.26@sha256:d47ca13cd596f3a338c1be5f79af628f42bedcf89455266211a9ab4f95da2828

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
