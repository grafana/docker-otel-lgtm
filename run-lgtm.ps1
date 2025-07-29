$release_tag = "latest"

$supportedContainerRuntime = 'podman', 'docker'
$containers = 'grafana', 'prometheus', 'loki'
$image = "docker.io/grafana/otel-lgtm:$release_tag"

# prefilled pwd var to avoid repeted calls in build string.moved to top init section or logic
$path = (Get-Location).Path

$containerCommand = $supportedContainerRuntime | ForEach-Object {
    (Get-Command $_ -ErrorAction SilentlyContinue).Source
} | Select-Object -first 1

if ($null -eq $containerCommand) {
    Write-Error "Please install Podman or docker"
    return
}

$containers | ForEach-Object {
    $null = New-Item -ItemType Directory -Path "$path/container/$_" -Force
}

& $containerCommand pull $image

$runCommand = @(
    'run'
    '--name', 'lgtm',
    '-p', '3000:3000'
    '-p', '4317:4317'
    '-p', '4318:4318'
    '--rm'
    '-ti',
    '-v', "${path}/container/grafana:/data/grafana"
    '-v', "${path}/container/prometheus:/data/prometheus"
    '-v', "${path}/container/loki:/data/loki"
    '-e', "GF_PATHS_DATA=/data/grafana"
    $image
)

& $containerCommand @runCommand
