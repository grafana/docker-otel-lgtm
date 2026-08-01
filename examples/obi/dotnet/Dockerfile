FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:10.0@sha256:72dd743782f2ae7e5476fd64f6a460045e3998dc862218b80e6944cba79a01b0 AS build
ARG TARGETARCH
ARG CONFIGURATION=Release

COPY . /source
WORKDIR /source

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
    dotnet publish "rolldice.csproj" --arch "${TARGETARCH}" --configuration "${CONFIGURATION}" --output /app /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0@sha256:f1126d438ccc359f51cc6d4701a8deae513856cf10f5fe645d29ea6403dcac6b AS final
WORKDIR /app
EXPOSE 8083

ENV ASPNETCORE_HTTP_PORTS=8083

COPY --from=build /app .
ENTRYPOINT ["dotnet", "rolldice.dll"]
