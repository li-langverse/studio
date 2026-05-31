@echo off
setlocal
set "ROOT=%~dp0.."
set "PROFILE=%~1"
if "%PROFILE%"=="" set "PROFILE=game"
set STUDIO_DEMO_PROFILE=%PROFILE%
set STUDIO_DEMO_FRAMES=3
if /I "%~2"=="present" set LIG_HOST_PRESENT=1
"%ROOT%li-studio-demo.exe"
exit /b %ERRORLEVEL%
