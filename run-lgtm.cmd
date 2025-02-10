@echo off

powershell -ExecutionPolicy ByPass -NoProfile -Command "& '%~run-lgtm.ps1'"
exit /b %ERRORLEVEL%