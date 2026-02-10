param (
    [Parameter(Mandatory = $false, Position = 0)] [string]  $ReleaseTag = "latest",
    [Parameter(Mandatory = $false, Position = 1)] [boolean] $UseLocalImage = $false
)

$supportedContainerRuntime = 'podman', 'docker'
$containers = 'grafana', 'prometheus', 'loki'
$image = "docker.io/grafana/otel-lgtm:${ReleaseTag}"

# prefilled pwd var to avoid repeated calls in build string.moved to top init section or logic
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

# Check if Beyla is enabled (from environment or .env file)
$beylaFlags = @()
$beylaEnabled = $env:ENABLE_BEYLA -eq 'true'
if (-Not $beylaEnabled -and (Test-Path -Path ".env")) {
    $beylaEnabled = (Get-Content ".env" | Select-String -Pattern '^ENABLE_BEYLA=true$' -Quiet)
}
if ($beylaEnabled) {
    Write-Output "Beyla eBPF auto-instrumentation enabled. Adding --pid=host --privileged flags."
    $beylaFlags = @('--pid=host', '--privileged')
    # Forward Beyla-related env vars into the container (they are not in .env by default)
    $beylaFlags += '-e', 'ENABLE_BEYLA=true'
    Get-ChildItem env: |
        Where-Object { $_.Name -match '^(BEYLA_|ENABLE_LOGS_BEYLA)' } |
        ForEach-Object {
            $beylaFlags += '-e', "$($_.Name)=$($_.Value)"
        }
}

$runCommand = @(
    'container', 'run'
    '--name', 'lgtm'
)

# Append Beyla-related flags (if any) so each flag is a separate argument
if ($beylaFlags.Count -gt 0) {
    $runCommand += $beylaFlags
}

# Append the remaining fixed arguments
$runCommand += @(
    '-p', '3000:3000'
    '-p', '4040:4040'
    '-p', '4317:4317'
    '-p', '4318:4318'
    '-p', '9090:9090'
    '--rm'
    '-ti'
    '-v', "${path}/container/grafana:/data/grafana"
    '-v', "${path}/container/prometheus:/data/prometheus"
    '-v', "${path}/container/loki:/data/loki"
    '-e', "GF_PATHS_DATA=/data/grafana"
    '--env-file', '.env'
    ${image}
)

& $containerCommand @runCommand
