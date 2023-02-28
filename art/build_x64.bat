@echo off
color 0a
cd ..
title BUILDING GAME
lime build windows -release

setlocal
:PROMPT
set /P AYS = Do you want run game? (y/n):
if /I "%AYS%" neq "y" goto END else exit

cd ..
cd export/release/windows/bin
"Baby Shark's Funkin"
:END
endlocal
exit