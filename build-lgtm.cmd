@echo off

SET release_tag=latest
if not "%~1"=="" (
	SET release_tag=%1
)

WHERE /Q podman
if not ERRORLEVEL 1 (
	goto use_podman
)

WHERE /Q docker
if not ERRORLEVEL 1 (
	goto use_docker
)

:no_executable_found
echo Please install Podman or docker
goto:EOF

:use_podman
podman buildx build -f docker/Dockerfile docker --tag grafana/otel-lgtm:%release_tag%
goto:EOF

:use_docker
docker buildx build -f docker/Dockerfile docker --tag grafana/otel-lgtm:%release_tag%
goto:EOF
