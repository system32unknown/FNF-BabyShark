@echo off
color 0a
cd ..
echo BUILDING GAME
lime build windows -release
echo.
echo done.
pause
explorer.exe export\release\windows\bin