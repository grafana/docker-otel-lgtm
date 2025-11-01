param (
    [string]$release_tag=$(if ($args.Length -ge 1 -and $args[0]) { $args[0] } else { 'latest' }),
    [string]$use_local_image=$(if ($args.Length -ge 1 -and $args[1]) { $args[1] } else { 'false' })
)

$supportedContainerRuntime = 'podman', 'docker'
$containers = 'grafana', 'prometheus', 'loki'
$image = "docker.io/grafana/otel-lgtm:$release_tag"

# prefilled pwd var to avoid repeted calls in build string.moved to top init section or logic
$path = (Get-Location).Path

$containerCommand = $supportedContainerRuntime | ForEach-Object {
    (Get-Command $_ -ErrorAction SilentlyContinue).Source
} | Select-Object -first 1

if ($null -eq $containerCommand) {
    Write-Error "Unable to find a suitable container runtime such as Docker or Podman. Exiting."
    return
}

$containers | ForEach-Object {
    $null = New-Item -ItemType Directory -Path "$path/container/$_" -Force
}

if (-Not (Test-Path -Path ".env")) {
    New-Item -ItemType File -Path ".env" -Force | Out-Null
}

if ($use_local_image -eq 'true') {
    if ($containerCommand -eq 'podman') {
        # Default address when building with Podman.
        $image = "localhost/grafana/otel-lgtm:latest"
    } else {
        $image = "grafana/otel-lgtm:latest"
    }
    else {
        $image = "docker.io/grafana/otel-lgtm:$release_tag"
        & $containerCommand image pull $image
    }
}

$runCommand = @(
    'container', 'run'
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
    '--env-file', '.env'
    $image
)

& $containerCommand @runCommand
