@echo off

set "releasetag=%~1"
set "local=%~2"

if "%releasetag%"=="" set "releasetag=latest"
if "%localimg%"=="" set "localimg=0"
if "%localimg%"=="false" set "localimg=0"
if "%localimg%"=="true" set "localimg=1"

powershell -ExecutionPolicy ByPass -NoProfile -Command "& '%~dp0\run-lgtm.ps1' -ReleaseTag '%releasetag%' -UseLocalImage %localimg%"
exit /b %ERRORLEVEL%
