@echo off

SET release_tag=latest
if not "%~1"=="" (
	SET release_tag=%1
)

mkdir "container/grafana"
mkdir "container/prometheus"
mkdir "container/loki"

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
podman run ^
	--name lgtm ^
	-p 3000:3000 ^
	-p 4317:4317 ^
	-p 4318:4318 ^
	--rm ^
	-ti ^
	-v %cd%/container/grafana:/data/grafana ^
	-v %cd%/container/prometheus:/data/prometheus ^
	-v %cd%/container/loki:/loki ^
	-e GF_PATHS_DATA=/data/grafana ^
	docker.io/grafana/otel-lgtm:%release_tag%
goto:EOF

:use_docker
docker run ^
	--name lgtm ^
	-p 3000:3000 ^
	-p 4317:4317 ^
	-p 4318:4318 ^
	--rm ^
	-ti ^
	-v %cd%/container/grafana:/data/grafana ^
	-v %cd%/container/prometheus:/data/prometheus ^
	-v %cd%/container/loki:/loki ^
	-e GF_PATHS_DATA=/data/grafana ^
	docker.io/grafana/otel-lgtm:%release_tag%
goto:EOF
