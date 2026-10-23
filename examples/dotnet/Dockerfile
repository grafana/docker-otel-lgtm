FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:10.0@sha256:747cbade5bfd918a175ac32f8f1d931edec2c7d0d5397a3de72eaef1ac1f66d2 AS build
ARG TARGETARCH
ARG CONFIGURATION=Release

COPY . /source
WORKDIR /source

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
    dotnet publish "rolldice.csproj" --arch "${TARGETARCH}" --configuration "${CONFIGURATION}" --output /app /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0@sha256:8af87eba5e7cdafb1514d7388be287365da97c132509e84dfe252ffd552398ca AS final
WORKDIR /app
EXPOSE 8083

ENV ASPNETCORE_HTTP_PORTS=8083

COPY --from=build /app .
ENTRYPOINT ["dotnet", "rolldice.dll"]
