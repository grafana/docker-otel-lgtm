@echo off

set "releasetag=%~1"
set "local=%~2"
if "%releasetag%"=="" set "releasetag=latest"
if "%localimg%"=="" set "localimg=false"

powershell -ExecutionPolicy ByPass -NoProfile -Command "& '%~dp0\run-lgtm.ps1' -release_tag '%releasetag%' -use_local_image '%localimg%'"
exit /b %ERRORLEVEL%
