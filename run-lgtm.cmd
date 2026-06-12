@echo off

set "releasetag=%~1"
set "localimg=%~2"
set "dryrun="

if "%releasetag%"=="" set "releasetag=latest"
if "%localimg%"=="" set "localimg=0"
if "%localimg%"=="false" set "localimg=0"
if "%localimg%"=="true" set "localimg=1"
if /I "%~3"=="--dry-run" set "dryrun=-DryRun"

powershell -ExecutionPolicy ByPass -NoProfile -Command "& '%~dp0\run-lgtm.ps1' -ReleaseTag '%releasetag%' -UseLocalImage %localimg% %dryrun%"
exit /b %ERRORLEVEL%
