# Nomad job for grafana/otel-lgtm (demo / testing only — not for production).
# Mirrors k8s/lgtm.yaml and run-lgtm.sh ports.
#
# Prerequisites:
#   - Nomad with Docker driver
#   - Optional: Consul for service discovery (service blocks below)
#
# Deploy:
#   nomad job run nomad/lgtm.nomad.hcl
#
# Access:
#   Grafana:      http://127.0.0.1:3000  (admin/admin)
#   OTLP gRPC:    127.0.0.1:4317
#   OTLP HTTP:    127.0.0.1:4318
#   Prometheus:   http://127.0.0.1:9090
#   Tempo:        http://127.0.0.1:3200
#   Pyroscope:    http://127.0.0.1:4040

variable "image" {
  type        = string
  default     = "docker.io/grafana/otel-lgtm:0.30.2"
  description = "otel-lgtm container image"
}

job "lgtm" {
  datacenters = ["dc1"]
  type        = "service"

  group "lgtm" {
    count = 1

    # Ephemeral disk for /data (similar to k8s emptyDir volumes).
    ephemeral_disk {
      size = 4096
    }

    network {
      port "grafana" {
        static = 3000
        to     = 3000
      }
      port "tempo" {
        static = 3200
        to     = 3200
      }
      port "pyroscope" {
        static = 4040
        to     = 4040
      }
      port "otel_grpc" {
        static = 4317
        to     = 4317
      }
      port "otel_http" {
        static = 4318
        to     = 4318
      }
      port "prometheus" {
        static = 9090
        to     = 9090
      }
    }

    task "lgtm" {
      driver = "docker"

      config {
        image = var.image
        ports = [
          "grafana",
          "tempo",
          "pyroscope",
          "otel_grpc",
          "otel_http",
          "prometheus",
        ]
      }

      env {
        GF_PATHS_DATA = "/data/grafana"
      }

      resources {
        cpu    = 1000
        memory = 2048
      }

      # Consul service registration (ignored if Consul is not available
      # when using Nomad native service discovery — switch provider if needed).
      service {
        name     = "lgtm-grafana"
        port     = "grafana"
        provider = "consul"
        check {
          type     = "http"
          path     = "/api/health"
          interval = "10s"
          timeout  = "2s"
        }
      }

      service {
        name     = "lgtm-otel-http"
        port     = "otel_http"
        provider = "consul"
      }

      service {
        name     = "lgtm-otel-grpc"
        port     = "otel_grpc"
        provider = "consul"
      }

      service {
        name     = "lgtm-prometheus"
        port     = "prometheus"
        provider = "consul"
      }
    }
  }
}
