$release_tag = "latest"
$image = "docker.io/grafana/otel-lgtm:$release_tag"

$supportedContainerRuntime = @( , "podman", "docker" )

$containerCommand = $supportedContainerRuntime `
| ForEach-Object { (Get-Command $_ -ErrorAction SilentlyContinue).Source } `
| Select-Object -first 1

if ($null -eq $containerCommand) {
    Write-Error "Please install Podman or docker"
    return
}

# make sure to espace space in binary path
$containerCommand = $containerCommand -replace ' ', '` '

# Create the directories only if one of the supported container runtime is found
$null = New-Item -ItemType Directory -Path "./container/grafana" -Force
$null = New-Item -ItemType Directory -Path "./container/prometheus" -Force
$null = New-Item -ItemType Directory -Path "./container/loki" -Force

# Pull the image
$pullCommand = "pull $image"
Invoke-Expression "$containerCommand $pullCommand"

# Run the container
$runCommand = @"
run ```
    --name lgtm ```
    -p 3000:3000 ```
    -p 4317:4317 ```
    -p 4318:4318 ```
    --rm ```
    -ti ```
    -v $((Get-Location).Path)/container/grafana:/data/grafana ```
    -v $((Get-Location).Path)/container/prometheus:/data/prometheus ```
    -v $((Get-Location).Path)/container/loki:/loki ```
    -e GF_PATHS_DATA=/data/grafana ```
    $image
"@

Invoke-Expression "$containerCommand $runCommand"
