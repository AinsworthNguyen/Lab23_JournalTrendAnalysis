<#
.SYNOPSIS
    Runs Flutter unit tests with coverage, and executes SonarQube Scanner analysis.
.PARAMETER HostUrl
    SonarQube server URL (default: http://localhost:9000).
.PARAMETER Token
    SonarQube authentication token.
#>
param (
    [string]$HostUrl = "http://localhost:9000",
    [string]$Token = ""
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " 1. Running Flutter Tests with Coverage... " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

flutter test --coverage

if (-not (Test-Path "coverage/lcov.info")) {
    Write-Host "Warning: coverage/lcov.info was not generated." -ForegroundColor Yellow
} else {
    Write-Host "Test coverage report generated successfully at coverage/lcov.info" -ForegroundColor Green
}

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host " 2. Running SonarQube Scanner...           " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$sonarArgs = @("-Dsonar.host.url=$HostUrl")

if ($Token -ne "") {
    $sonarArgs += "-Dsonar.login=$Token"
    $sonarArgs += "-Dsonar.token=$Token"
} elseif ($env:SONAR_TOKEN) {
    $sonarArgs += "-Dsonar.login=$env:SONAR_TOKEN"
    $sonarArgs += "-Dsonar.token=$env:SONAR_TOKEN"
}

sonar-scanner @sonarArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nSonarQube Analysis finished!" -ForegroundColor Green
} else {
    Write-Host "`nSonarScanner execution exited with code $LASTEXITCODE" -ForegroundColor Yellow
}
