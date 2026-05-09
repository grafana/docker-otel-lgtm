FROM golang:1.26@sha256:2981696eed011d747340d7252620932677929cce7d2d539602f56a8d7e9b660b

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
