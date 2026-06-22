FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:10.0@sha256:548d93f8a18a1acbe6cc127bc4f47281430d34a9e35c18afa80a8d6741c2adc3 AS build
ARG TARGETARCH
ARG CONFIGURATION=Release

COPY . /source
WORKDIR /source

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
    dotnet publish "rolldice.csproj" --arch "${TARGETARCH}" --configuration "${CONFIGURATION}" --output /app /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0@sha256:ddcf70ad1ab963a4fcd41fbd722a6b660e404e87567cfbd46fd2809c21b02088 AS final
WORKDIR /app
EXPOSE 8083

ENV ASPNETCORE_HTTP_PORTS=8083

COPY --from=build /app .
ENTRYPOINT ["dotnet", "rolldice.dll"]
