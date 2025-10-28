param (
    [Parameter(Mandatory = $false, Position = 0)] [string]  $ReleaseTag = "latest",
    [Parameter(Mandatory = $false, Position = 1)] [boolean] $UseLocalImage = $false
)

$supportedContainerRuntime = 'podman', 'docker'
$containers = 'grafana', 'prometheus', 'loki'
$image = "docker.io/grafana/otel-lgtm:${ReleaseTag}"

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

if ($UseLocalImage) {
    if ($containerCommand -eq 'podman') {
        $image = "localhost/grafana/otel-lgtm:${ReleaseTag}"
    } 
    else {
        $image = "grafana/otel-lgtm:${ReleaseTag}"
    }
}
else {
    $image = "docker.io/grafana/otel-lgtm:${ReleaseTag}"
    & $containerCommand image pull $image
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
    ${image}
)

& $containerCommand @runCommand
