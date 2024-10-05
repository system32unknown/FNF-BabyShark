#!/bin/sh
# SETUP FOR MAC AND LINUX SYSTEMS!!!
# REMINDER THAT YOU NEED HAXE INSTALLED PRIOR TO USING THIS
# https://haxe.org/download
cd ..
echo Making the main haxelib and setuping folder in same time..
mkdir ~/haxelib && haxelib setup ~/haxelib
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib install lime
haxelib git flixel https://github.com/system32unknown/flixel-alter
haxelib git flixel-addons https://github.com/system32unknown/flixel-addons
haxelib install flixel-tools
haxelib git hscript-improved https://github.com/FNF-CNE-Devs/hscript-improved custom-classes
haxelib install hxcpp-debug-server
haxelib git flxanimate https://github.com/ShadowMario/flxanimate dev
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis
haxelib git grig.audio https://gitlab.com/haxe-grig/grig.audio.git

haxelib install tjson
haxelib install hxdiscord_rpc --quiet
haxelib install hxvlc --quiet
haxelib install parallaxlt
haxelib git openfl https://github.com/system32unknown/openfl

echo Finished!