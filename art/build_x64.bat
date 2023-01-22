@echo off
color 0a
cd ..
title BUILDING GAME
lime build windows -release

setlocal
:PROMPT
SET /P AYS = Do you want run game? (Y/N)?
IF /I "%AYS%" NEQ "Y" GOTO END

cd export/release/windows/bin
"Baby Shark's Funkin"
:END
endlocal