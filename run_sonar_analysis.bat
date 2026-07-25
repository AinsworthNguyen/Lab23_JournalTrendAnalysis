@echo off
setlocal enabledelayedexpansion

:: Script to run Flutter tests with coverage, flutter analyze, and trigger SonarQube Scanner in Command Prompt (cmd.exe)

:: Param 1: SonarQube Host URL (Default: http://localhost:9000)
set "HOST_URL=%~1"
if "%HOST_URL%"=="" set "HOST_URL=http://localhost:9000"

:: Param 2: SonarQube Token (Default: SONAR_TOKEN environment variable)
set "TOKEN=%~2"
if "%TOKEN%"=="" if defined SONAR_TOKEN set "TOKEN=%SONAR_TOKEN%"

echo ==========================================
echo  1. Running Flutter Tests with Coverage...
echo ==========================================
call flutter test --coverage
if errorlevel 1 (
    echo Warning: Flutter test encountered an issue, but proceeding with scan...
)

echo.
echo ==========================================
echo  2. Running Official Flutter Analyzer...
echo ==========================================
call flutter analyze > flutter_analyze.txt

echo.
echo ==========================================
echo  3. Running SonarQube Scanner...
echo ==========================================

if not "%TOKEN%"=="" (
    call sonar-scanner -Dsonar.host.url="%HOST_URL%" -Dsonar.login="%TOKEN%" -Dsonar.token="%TOKEN%"
) else (
    call sonar-scanner -Dsonar.host.url="%HOST_URL%"
)

if errorlevel 1 (
    echo.
    echo SonarScanner finished with code %errorlevel%.
) else (
    echo.
    echo SonarQube Analysis completed successfully!
)

endlocal
