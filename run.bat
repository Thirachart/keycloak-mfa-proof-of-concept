@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
title Keycloak MFA PoC - Control Panel

:menu
cls
echo ========================================================
echo   Keycloak MFA PoC - Control Panel
echo ========================================================
echo.
echo   -- Run / Stop --
echo   [1] Start (keep existing data)
echo   [2] Start FRESH (wipe data, build, configure, Phase 1)
echo   [3] Stop (containers only, keep data)
echo   [4] Full Reset (stop AND wipe all data/volumes)
echo   [5] Rebuild images (after code changes) + restart
echo.
echo   -- Phase --
echo   [6] Switch to Phase 1 (no OTP)
echo   [7] Switch to Phase 2 (Email OTP required)
echo.
echo   -- Testing helpers --
echo   [8] Clear MFA trust for user "demo"
echo   [9] Clear MFA trust for a custom username
echo.
echo   -- Open in browser --
echo   [10] App            (http://localhost:8000)
echo   [11] Mailpit         (http://localhost:18025)
echo   [12] Keycloak Admin  (http://localhost:18080/admin)
echo.
echo   -- Diagnostics --
echo   [13] Container status
echo   [14] Keycloak logs (last 100 lines)
echo.
echo   [0] Exit
echo.
set /p choice="Select an option: "

if "%choice%"=="1" goto start_keep
if "%choice%"=="2" goto start_fresh
if "%choice%"=="3" goto stop_keep
if "%choice%"=="4" goto full_reset
if "%choice%"=="5" goto rebuild
if "%choice%"=="6" goto phase1
if "%choice%"=="7" goto phase2
if "%choice%"=="8" goto clear_trust_demo
if "%choice%"=="9" goto clear_trust_custom
if "%choice%"=="10" goto open_app
if "%choice%"=="11" goto open_mailpit
if "%choice%"=="12" goto open_admin
if "%choice%"=="13" goto status
if "%choice%"=="14" goto logs
if "%choice%"=="0" goto end
goto menu

:start_keep
echo.
echo Starting containers (existing data kept)...
docker compose up -d
call :wait_for_keycloak
echo.
echo Ready. App: http://localhost:8000
pause
goto menu

:start_fresh
echo.
echo This will DELETE all current data (users, realm changes, MFA trust, sent mail).
set /p confirm="Type YES to continue: "
if /i not "%confirm%"=="YES" goto menu
echo.
echo [1/6] Stopping and removing containers + volumes...
docker compose down -v
echo.
echo [2/6] Building images...
docker compose build
if errorlevel 1 goto build_failed
echo.
echo [3/6] Starting containers...
docker compose up -d
call :wait_for_keycloak
echo.
echo [4/6] Configuring authentication flows...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\configure-auth-flows.ps1"
echo.
echo [5/6] Configuring lab external IdP...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\configure-lab-idp.ps1"
echo.
echo [6/6] Setting Phase 1...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\phase1.ps1"
echo.
echo Done. App: http://localhost:8000
pause
goto menu

:stop_keep
echo.
echo Stopping containers (data kept)...
docker compose down
echo Done.
pause
goto menu

:full_reset
echo.
echo This will DELETE all current data (users, realm changes, MFA trust, sent mail).
set /p confirm="Type YES to continue: "
if /i not "%confirm%"=="YES" goto menu
echo.
echo Stopping and removing containers + volumes...
docker compose down -v
echo Done. Use [2] Start FRESH to bring the project back up from a clean state.
pause
goto menu

:rebuild
echo.
echo Rebuilding images and restarting...
docker compose build
if errorlevel 1 goto build_failed
docker compose up -d
call :wait_for_keycloak
echo Done.
pause
goto menu

:phase1
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\phase1.ps1"
pause
goto menu

:phase2
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\phase2.ps1"
pause
goto menu

:clear_trust_demo
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\clear-mfa-trust.ps1" -Username demo
pause
goto menu

:clear_trust_custom
echo.
set /p uname="Username: "
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\clear-mfa-trust.ps1" -Username "%uname%"
pause
goto menu

:open_app
start "" "http://localhost:8000"
goto menu

:open_mailpit
start "" "http://localhost:18025"
goto menu

:open_admin
start "" "http://localhost:18080/admin"
goto menu

:status
echo.
docker compose ps
echo.
pause
goto menu

:logs
echo.
docker compose logs keycloak --tail 100
echo.
pause
goto menu

:build_failed
echo.
echo Build failed. Check the output above.
pause
goto menu

:wait_for_keycloak
echo Waiting for Keycloak to become ready...
set /a tries=0
:wait_loop
set /a tries+=1
curl -s -o nul -w "%%{http_code}" http://localhost:18080/realms/master > "%TEMP%\kc_status.txt" 2>nul
set /p kc_status=<"%TEMP%\kc_status.txt"
if "%kc_status%"=="200" (
    echo Keycloak is ready.
    goto :eof
)
if %tries% GEQ 40 (
    echo Timed out waiting for Keycloak. Check "docker compose logs keycloak".
    goto :eof
)
timeout /t 3 >nul
goto wait_loop

:end
endlocal
exit /b 0
