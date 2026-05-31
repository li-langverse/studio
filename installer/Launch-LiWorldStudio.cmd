@echo off
setlocal
set "ROOT=%~dp0"
set "PROFILE=%~1"
if "%PROFILE%"=="" set "PROFILE=game"
set "PRESENT=0"
if /I "%~2"=="present" set "PRESENT=1"
for /f "delims=" %%I in ('wsl wslpath -u "%ROOT%"') do set "WSL_ROOT=%%I"
if "%PRESENT%"=="1" (
  wsl bash -lc "cd '%WSL_ROOT%' && export STUDIO_DEMO_PROFILE=%PROFILE% STUDIO_DEMO_FRAMES=3 LIG_HOST_PRESENT=1 STUDIO_SHELL_PRESENT_HOST_BIN='%WSL_ROOT%/studio_shell_present_host' && ./li-studio-demo.exe"
) else (
  wsl bash -lc "cd '%WSL_ROOT%' && export STUDIO_DEMO_PROFILE=%PROFILE% STUDIO_DEMO_FRAMES=3 && ./li-studio-demo.exe"
)
exit /b %ERRORLEVEL%
