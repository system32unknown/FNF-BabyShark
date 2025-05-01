@echo off
cd ..
title BUILDING GAME
haxelib run lime build windows -release

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