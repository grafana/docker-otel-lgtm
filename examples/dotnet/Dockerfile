FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:10.0@sha256:ed034a8bf0b24ded0cbbac07e17825d8e9ebfe21e308191d0f7421eaf5ad4664 AS build
ARG TARGETARCH
ARG CONFIGURATION=Release

COPY . /source
WORKDIR /source

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
    dotnet publish "rolldice.csproj" --arch "${TARGETARCH}" --configuration "${CONFIGURATION}" --output /app /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0@sha256:1fa23fc4872d95fd71c2833ebe65d7e84a43b2d51a31d119516852f13d9505a7 AS final
WORKDIR /app
EXPOSE 8083

ENV ASPNETCORE_HTTP_PORTS=8083

COPY --from=build /app .
ENTRYPOINT ["dotnet", "rolldice.dll"]
