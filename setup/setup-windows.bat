@echo off
color 0a
cd ..
@echo on
echo Installing dependencies.
haxelib install lime
haxelib install openfl
haxelib git flixel https://github.com/HaxeFlixel/flixel
haxelib git flixel-addons https://github.com/HaxeFlixel/flixel-addons
haxelib git flixel-ui https://github.com/HaxeFlixel/flixel-ui
haxelib install hxvlc
haxelib install tjson
haxelib git hscript-improved https://www.github.com/FNF-CNE-Devs/hscript-improved custom-classes
haxelib git flxanimate https://github.com/ShadowMario/flxanimate dev
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc
haxelib git hxcpp https://github.com/HaxeFoundation/hxcpp/
echo Finished!
pause