#!/usr/bin/env pwsh

param (
    [Parameter(Mandatory = $false, Position = 0)] [string]  $ReleaseTag = "latest",
    [Parameter(Mandatory = $false, Position = 1)] [boolean] $UseLocalImage = $false,
    [Parameter(Mandatory = $false)] [switch] $DryRun
)

$supportedContainerRuntime = 'podman', 'docker', 'wslc'
$containers = 'grafana', 'prometheus', 'loki'
$image = "docker.io/grafana/otel-lgtm:${ReleaseTag}"

# prefilled pwd var to avoid repeated calls in build string.moved to top init section or logic
$path = (Get-Location).Path

if ($env:CONTAINER_RUNTIME_OVERRIDE) {
    $validRuntimes = 'docker', 'podman', 'wslc'
    # 'container' is the Apple Container CLI; on Windows, container.exe is a
    # wslc alias, so only allow it on macOS.
    if ($IsMacOS) {
        $validRuntimes += 'container'
    }
    if ($validRuntimes -notcontains $env:CONTAINER_RUNTIME_OVERRIDE) {
        if ($env:CONTAINER_RUNTIME_OVERRIDE -eq 'container') {
            Write-Error "Invalid runtime: container. On Windows, use 'wslc' instead (container.exe is a wslc alias)."
        } else {
            Write-Error "Invalid runtime: $($env:CONTAINER_RUNTIME_OVERRIDE) (must be docker, podman, or wslc)"
        }
        return
    }
    $containerCommand = (Get-Command $env:CONTAINER_RUNTIME_OVERRIDE -ErrorAction SilentlyContinue).Source
    if ($null -eq $containerCommand) {
        Write-Error "Runtime '$($env:CONTAINER_RUNTIME_OVERRIDE)' specified in CONTAINER_RUNTIME_OVERRIDE was not found on PATH."
        return
    }
} else {
    $containerCommand = $supportedContainerRuntime | ForEach-Object {
        (Get-Command $_ -ErrorAction SilentlyContinue).Source
    } | Select-Object -first 1
}

if ($null -eq $containerCommand) {
    Write-Error "Unable to find a suitable container runtime such as Docker, Podman, or WSL containers (wslc). Exiting."
    return
}

# Compute once: is the resolved runtime wslc?
$commandLeaf = Split-Path -Leaf $containerCommand
$isWslc = [IO.Path]::GetFileNameWithoutExtension($commandLeaf) -eq 'wslc'

$containers | ForEach-Object {
    $null = New-Item -ItemType Directory -Path "$path/container/$_" -Force
}

if (-Not (Test-Path -Path ".env")) {
    New-Item -ItemType File -Path ".env" -Force | Out-Null
}

if ($UseLocalImage) {
    if ([IO.Path]::GetFileNameWithoutExtension($commandLeaf) -eq 'podman') {
        $image = "localhost/grafana/otel-lgtm:${ReleaseTag}"
    }
    else {
        $image = "grafana/otel-lgtm:${ReleaseTag}"
    }
}
else {
    $image = "docker.io/grafana/otel-lgtm:${ReleaseTag}"
    if (-Not $DryRun) {
        & $containerCommand image pull $image
    }
}

# Check if OBI is enabled (from environment or .env file)
$obiFlags = @()
$obiEnabled = $env:ENABLE_OBI -eq 'true'
if (-Not $obiEnabled -and (Test-Path -Path ".env")) {
    $obiEnabled = (Get-Content ".env" | Select-String -Pattern '^ENABLE_OBI=true$' -Quiet)
}
if ($obiEnabled) {
    if ($isWslc) {
        Write-Error "Error: OBI eBPF auto-instrumentation requires --pid=host --privileged, which WSL containers (wslc) does not support. Use Docker or Podman for OBI."
        return
    }
    Write-Output "OBI eBPF auto-instrumentation enabled. Adding --pid=host --privileged flags."
    $obiFlags = @('--pid=host', '--privileged')
    # Forward OBI-specific env vars into the container (they are not in .env by default).
    # General OTLP vars (OTEL_EXPORTER_OTLP_ENDPOINT, etc.) are forwarded via --env-file .env.
    $obiFlags += '-e', 'ENABLE_OBI=true'
    Get-ChildItem env: |
        Where-Object { $_.Name -match '^(OBI_TARGET|OTEL_EBPF_|ENABLE_LOGS_OBI)' } |
        ForEach-Object {
            $obiFlags += '-e', "$($_.Name)=$($_.Value)"
        }
}

# Allocate TTY only if stdin is interactive
$ttyFlag = @()
if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    $ttyFlag = @('-t', '-i')
}

$runCommand = @(
    'run'
    '--name', 'lgtm'
)

if (-not $isWslc) {
    $runCommand += '--init'
}

# Append OBI-related flags (if any) so each flag is a separate argument
if ($obiFlags.Count -gt 0) {
    $runCommand += $obiFlags
}

# Append the remaining fixed arguments
$runCommand += @(
    '-p', '3000:3000'
    '-p', '3200:3200'
    '-p', '4040:4040'
    '-p', '4317:4317'
    '-p', '4318:4318'
    '-p', '9090:9090'
    '-e', "OTEL_COLLECTOR_DEBUG_EXPORTER=$($env:OTEL_COLLECTOR_DEBUG_EXPORTER)"
    '--rm'
)

$runCommand += $ttyFlag

$runCommand += @(
    '-v', "${path}/container/grafana:/data/grafana"
    '-v', "${path}/container/prometheus:/data/prometheus"
    '-v', "${path}/container/loki:/data/loki"
    '-e', "GF_PATHS_DATA=/data/grafana"
    '--env-file', '.env'
    ${image}
)

if ($DryRun) {
    Write-Output "runtime=$(Split-Path -Leaf $containerCommand)"
    Write-Output "image=$image"
    foreach ($arg in $runCommand) {
        Write-Output "arg=$arg"
    }
    return
}

& $containerCommand @runCommand
