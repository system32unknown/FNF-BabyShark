package utils;

import flixel.util.FlxSpriteUtil;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import openfl.net.FileReference;
#if (!sys && !MODS_ALLOWED) import openfl.utils.Assets; #end
import utils.system.PlatformUtil.MessageBoxIcon;
import utils.system.NativeUtil;

class CoolUtil {
	public static function saveFile(content:String, format:String, filedefault:String) {new FileReference().save(content, '$filedefault.$format');}
	inline public static function quantize(f:Float, snap:Float) {
		var m:Float = Math.fround(f * snap);
		return (m / snap);
	}

	inline public static function capitalize(text:String) {
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();
	}

	inline public static function coolTextFile(path:String):Array<String> {
		var daList:String = null;
		#if (sys && MODS_ALLOWED)
		var formatted:Array<String> = path.split(':'); //prevent "shared:", "preload:" and other library names on file path
		path = formatted[formatted.length - 1];
		if(FileSystem.exists(path)) daList = File.getContent(path);
		#else
		if(Assets.exists(path)) daList = Assets.getText(path);
		#end
		return daList != null ? listFromString(daList) : [];
	}
	inline public static function listFromString(string:String):Array<String> {
		final daList = string.trim().split('\n');
		return [for(i in 0...daList.length) daList[i].trim()];
	}

	inline public static function numberArray(max:Int, ?min = 0):Array<Int> return [for (i in min...max) i];

	inline public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site, "&"]);
		#else
		FlxG.openURL(site);
		#end
	}

	inline public static function openFolder(folder:String, absolute:Bool = false) {
		#if sys
			if(!absolute) folder =  Sys.getCwd() + '$folder';

			folder = folder.replace('/', '\\');
			if(folder.endsWith('/')) folder.substr(0, folder.length - 1);
			Sys.command(#if !linux 'explorer.exe' #else '/usr/bin/xdg-open' #end, [folder]);
		#else FlxG.error("Platform is not supported for CoolUtil.openFolder"); #end
	}

	public static function makeSelectorGraphic(panel:FlxSprite, w:Int, h:Int, color:FlxColor, cornerSize:Float) {
		panel.makeGraphic(w, h, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRectComplex(panel, 0, 0, w, h, cornerSize, cornerSize, cornerSize, cornerSize, color);
	}

	public static function getRandomizedText(max:Int):String {
        var temp_str:String = "";
        for (_ in 0...max)
            temp_str += String.fromCharCode(FlxG.random.int(65, 122));
        return temp_str;
    }

	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String {
		return '${FlxG.stage.application.meta.get('company')}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
	}

	public static function removeDuplicates(string:Array<String>):Array<String> {
		var tempArray:Array<String> = new Array<String>();
		var lastSeen:String = '';
		string.sort((a:String, b:String) -> return (a == b) ? 0 : (a > b) ? 1 : -1);
		for (str in string) {
		  	if (str != lastSeen) tempArray.push(str);
		  	lastSeen = str;
		}
		return tempArray;
	}

	inline public static function dynamicArray<T>(v:T, len:Int):Array<T> return [for (_ in 0...len) v];

	public static function getOptionDefVal(type:String, ?options:Array<String> = null):Dynamic {
		return switch(type) {
			case 'bool': false;
			case 'int' | 'float': 0;
			case 'percent': 1;
			case 'string':
				if(options.length > 0) options[0];
				else '';
			case 'func': '';
			default: null;
		}
	}

    public static function getColor(value:Dynamic):FlxColor {
        if (value == null) return FlxColor.WHITE;
        if (value is Int) return value;
        if (value is String) return colorFromString(value);

        if (value is Array) {
            var arr:Array<Float> = cast value;
            while (arr.length < 3) arr.push(0);
            return FlxColor.fromRGB(Std.int(arr[0]), Std.int(arr[1]), Std.int(arr[2]));
        }

        return FlxColor.WHITE;
    }

	inline public static function colorFromString(color:String):FlxColor {
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	public static function callErrBox(title:String, context:String) {
        #if hl
		var flags:haxe.EnumFlags<hl.UI.DialogFlags> = new haxe.EnumFlags<hl.UI.DialogFlags>();
		flags.set(IsError);
		hl.UI.dialog(title, context, flags);
		#else
		NativeUtil.showMessageBox(title, context, MessageBoxIcon.MSG_ERROR);
		#end
    }

	inline public static function createBackDrop(cellW:Int, cellH:Int, w:Int, h:Int, alt:Bool, color1:FlxColor, color2:FlxColor):FlxBackdrop {
		return new FlxBackdrop(FlxGridOverlay.createGrid(cellW, cellH, w, h, alt, color1, color2));
	}
}
