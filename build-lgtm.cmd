@echo off

SET release_tag=latest
if not "%~1"=="" (
	SET release_tag=%1
)

echo Building the Grafana OTEL-LGTM image with release %release_tag%...

WHERE /Q podman
if not ERRORLEVEL 1 (
	goto use_podman
)

WHERE /Q docker
if not ERRORLEVEL 1 (
	goto use_docker
)

WHERE /Q wslc
if not ERRORLEVEL 1 (
	goto use_wslc
)

:no_executable_found
echo Please install Podman, Docker, or WSL containers (wslc)
goto:EOF

:use_podman
podman buildx build -f docker/Dockerfile docker --tag grafana/otel-lgtm:%release_tag% --build-arg LGTM_VERSION=%release_tag%
goto:EOF

:use_docker
docker buildx build -f docker/Dockerfile docker --tag grafana/otel-lgtm:%release_tag% --build-arg LGTM_VERSION=%release_tag%
goto:EOF

:use_wslc
wslc build -f docker/Dockerfile docker --tag grafana/otel-lgtm:%release_tag% --build-arg LGTM_VERSION=%release_tag%
goto:EOF
