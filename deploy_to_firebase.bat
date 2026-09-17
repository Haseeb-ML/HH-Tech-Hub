@echo off
set "PATH=%APPDATA%\npm;%LOCALAPPDATA%\Programs\nodejs;%PATH%"

echo ===================================================
echo   HH Tech Hub ERP - Deploy to Firebase Hosting
echo   Target Project: hh-tech-hub-3e615
echo ===================================================
echo.

echo Step 1: Checking Firebase Login...
call firebase.cmd login

echo.
echo Step 2: Deploying to Firebase Hosting...
call firebase.cmd deploy --only hosting --project hh-tech-hub-3e615

echo.
echo ===================================================
echo   Deployment Completed!
echo   Live URL: https://hh-tech-hub-3e615.web.app
echo ===================================================
pause
