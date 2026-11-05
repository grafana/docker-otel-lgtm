FROM golang:1.27@sha256:a386c44c1c90025ad5bc66feea3fef23052bef3bace3609f7e3e10e1f9314f45

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
