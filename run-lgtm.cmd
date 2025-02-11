@echo off

powershell -ExecutionPolicy ByPass -NoProfile -Command "& '%~dp0\run-lgtm.ps1'"
exit /b %ERRORLEVEL%
