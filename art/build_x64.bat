@echo off
color 0a
cd ..
title BUILDING GAME
lime build windows -release

setlocal
:PROMPT
SET /P AYS = Do you want run game? (y/n):
IF /I "%AYS%" NEQ "Y" GOTO END

cd export/release/windows/bin
"AlterEngine"
:END
endlocal
pause
exit