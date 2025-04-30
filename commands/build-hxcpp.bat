@echo off
set "oldDir=%cd%"
for /f "delims=" %%A in ('haxelib libpath hxcpp') do set "HXCPP_PATH=%%A"
cd /d "%HXCPP_PATH%\tools\hxcpp"
haxe compile.hxml
cd /d "%oldDir%"