@echo off
color 0a
cd ..
title BUILDING GAME
lime build windows -release

if not "%ERRORLEVEL%" == "0" goto ERROR
goto OK

:ERROR
echo Failed Compiling Game.
goto QUIT

:OK
echo Done Compiling Game.
goto QUIT

:QUIT
pause
exit