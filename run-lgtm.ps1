$release_tag = "latest"

# just a little helper to get rid of the tripple backtics. i tend to keep these on the top after args, before logic
filter Compress { [regex]::Replace($_, '[\s\r\n]+', ' ') }

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

# wrapping in " to avoid space-escaping, and add & for execute
$containerCommand = "& `"$containerCommand`""

$containers | ForEach-Object {
    $null = New-Item -ItemType Directory -Path "$path/container/$_" -Force
}

Invoke-Expression "$containerCommand pull $image"

$runCommand = @"
run
    --name lgtm
    -p 3000:3000
    -p 4317:4317
    -p 4318:4318
    --rm
    -ti
    -v "$path/container/grafana:/data/grafana"
    -v "$path/container/prometheus:/data/prometheus"
    -v "$path/container/loki:/loki"
    -e GF_PATHS_DATA=/data/grafana
    $image
"@ | Compress

Invoke-Expression "$containerCommand $runCommand"