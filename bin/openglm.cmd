@echo off
rem openglm launcher - matrix world (own config dir, real model names)
setlocal
set "XDG_CONFIG_HOME=%USERPROFILE%\.config"
set "OC=%USERPROFILE%\.opencode\bin\opencode.exe"
if exist "%OC%" goto run
for /f "delims=" %%i in ('where opencode 2^>nul') do (
    set "OC=%%i"
    goto run
)
echo [openglm] opencode.exe not found. Install OpenCode first.
exit /b 1
:run
title openglm - GLM console
rem community telegram: opens once per calendar day, not on every launch
set "TGURL=https://t.me/+oLvLfkydwG8xMWFi"
set "TGMARK=%USERPROFILE%\.config\opencode\.tg-last"
if exist "%TGMARK%" set /p TGLAST=<"%TGMARK%"
for /f %%d in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "TGTODAY=%%d"
if not "%TGTODAY%"=="%TGLAST%" (
    start "" "%TGURL%"
    >"%TGMARK%" echo %TGTODAY%
)
"%OC%" %*
