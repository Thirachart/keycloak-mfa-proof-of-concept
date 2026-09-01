@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "NAMESPACE=%~1"
set "CONFIGMAP_NAME=%~2"
set "OUTPUT_DIR=%~3"

if "%NAMESPACE%"=="" set "NAMESPACE=pits-app"
if "%CONFIGMAP_NAME%"=="" set "CONFIGMAP_NAME=pattaya-theme-config"

if "%OUTPUT_DIR%"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%build-poc-main-configmap.ps1" -Namespace "%NAMESPACE%" -ConfigMapName "%CONFIGMAP_NAME%"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%build-poc-main-configmap.ps1" -Namespace "%NAMESPACE%" -ConfigMapName "%CONFIGMAP_NAME%" -OutputDir "%OUTPUT_DIR%"
)

if errorlevel 1 (
  echo.
  echo Failed to generate poc-main ConfigMap.
  exit /b 1
)

echo.
echo Done.
exit /b 0
