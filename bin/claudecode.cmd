@echo off
rem claudecode launcher - Claude Code look on the OpenCode engine (isolated config)
setlocal
set "XDG_CONFIG_HOME=%USERPROFILE%\.config\claudecode"
set "OC=%USERPROFILE%\.opencode\bin\opencode.exe"
if exist "%OC%" goto banner
echo [claudecode] engine not found. Run the openglm installer first.
pause
exit /b 1
:banner
title Claude Code
echo.
echo   \_\      /_/   \    /\   \  /
echo    \ \ /\ / /   __\ \  /   \ /
echo     \ V  V /   /_____\ \/    V
echo.
echo   Welcome to Claude Code
echo.
set /a TIPN=%RANDOM% %% 5
if %TIPN%==0 echo   tip: /opus switches to flagship CLAUDE OPUS 5.5
if %TIPN%==1 echo   tip: /sonnet gives you CLAUDE SONNET 5.5 for everyday tasks
if %TIPN%==2 echo   tip: /haiku is the fast CLAUDE HAIKU 4.5
if %TIPN%==3 echo   tip: /deep makes the model plan before coding
if %TIPN%==4 echo   tip: /skills lists everything the agent can do
echo.
echo     model ...... claude-opus-5-5
echo     commands ... /opus /sonnet /haiku /fable /deep /skills /tg
echo     skills ..... active
echo     quit ....... Ctrl+C twice
echo.
"%OC%" %*
