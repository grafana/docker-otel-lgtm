FROM golang:1.26@sha256:983a0823d3dab83604654972fe6bbda13142a7c57f987804fbdddb9d47dad9ec

WORKDIR /app

COPY go.mod ./

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
