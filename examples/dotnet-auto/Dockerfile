ARG OTEL_VERSION=1.12.0
ARG OTEL_DOTNET_AUTO_HOME="/otel-dotnet-auto"

FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:9.0 AS build
ARG TARGETARCH
ARG CONFIGURATION=Release

COPY . /source
WORKDIR /source

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
    dotnet publish "rolldice.csproj" --arch "${TARGETARCH}" --configuration "${CONFIGURATION}" --output /app /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS otel

ARG OTEL_VERSION
ARG OTEL_DOTNET_AUTO_HOME
ENV OTEL_DOTNET_AUTO_HOME=$OTEL_DOTNET_AUTO_HOME

ADD https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/releases/download/v${OTEL_VERSION}/otel-dotnet-auto-install.sh otel-dotnet-auto-install.sh
RUN chmod +x otel-dotnet-auto-install.sh
RUN mkdir $OTEL_DOTNET_AUTO_HOME
RUN apt-get update && apt-get install -y unzip && \
    sh otel-dotnet-auto-install.sh

FROM otel as final
WORKDIR /app
EXPOSE 8083

ENV ASPNETCORE_HTTP_PORTS=8083

ARG OTEL_VERSION
ARG OTEL_DOTNET_AUTO_HOME
ENV OTEL_DOTNET_AUTO_HOME=$OTEL_DOTNET_AUTO_HOME
RUN chmod +x /otel-dotnet-auto/instrument.sh

COPY --from=build /app .
ENTRYPOINT ["/otel-dotnet-auto/instrument.sh", "dotnet", "rolldice.dll"]
