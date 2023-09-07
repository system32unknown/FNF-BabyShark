@echo off
color 0a
cd ..
@echo on
echo Updating dependencies.
haxe -cp ./setup -D analyzer-optimize -main Main --interp
echo Finished!
pause