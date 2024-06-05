@echo off
color 0a
cd ..
echo Installing dependencies.
haxelib install lime
haxelib install openfl
haxelib install hxvlc
haxelib install tjson
haxelib git flixel https://github.com/HaxeFlixel/flixel
haxelib git flixel-addons https://github.com/HaxeFlixel/flixel-addons
haxelib git hscript-improved https://www.github.com/FNF-CNE-Devs/hscript-improved
haxelib git flxanimate https://github.com/ShadowMario/flxanimate dev
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit
haxelib git hxdiscord_rpc https://github.com/FNF-CNE-Devs/hxdiscord_rpc
haxelib git hxcpp https://github.com/HaxeFoundation/hxcpp/
echo Finished!
pause