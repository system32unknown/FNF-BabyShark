package utils;

import flixel.FlxBasic;
import flixel.addons.display.FlxBackdrop;
import openfl.net.FileReference;

class CoolUtil {
	public static function saveFile(content:String, format:String, filedefault:String, save:Bool = true) {
		var fileRef:FileReference = new FileReference();
		if (save) fileRef.save(content, '$filedefault.$format');
		else fileRef.load();
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
		if(openfl.utils.Assets.exists(path)) daList = openfl.utils.Assets.getText(path);
		#end
		return daList == null ? [] : listFromString(daList);
	}
	
	inline public static function listFromString(string:String):Array<String> {
		final daList = string.trim().split('\n');
		return [for(i in 0...daList.length) daList[i].trim()];
	}

	public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site, "&"]);
		#else
		FlxG.openURL(site);
		#end
	}

	inline public static function openFolder(folder:String, absolute:Bool = false) {
		#if sys
		if(!absolute) folder = Sys.getCwd() + '$folder';

		folder = folder.replace('/', '\\');
		if(folder.endsWith('/')) folder.substr(0, folder.length - 1);
		Sys.command(#if windows 'explorer.exe' #else '/usr/bin/xdg-open' #end, [folder]);
		#else FlxG.error("Platform is not supported for CoolUtil.openFolder"); #end
	}

	public static function getRandomizedText(max:Int):String {
        var temp_str:String = "";
        for (_ in 0...max)
            temp_str += String.fromCharCode(FlxG.random.int(65, 122));
        return temp_str;
    }

	inline public static function sortByID(i:Int, basic1:FlxBasic, basic2:FlxBasic):Int {
		return basic1.ID > basic2.ID ? -i : basic2.ID > basic1.ID ? i : 0;
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

    public static function getColor(value:Dynamic, ?defValue:Array<Int>):FlxColor {
        if (value == null) return FlxColor.WHITE;
        if (value is Int) return value;
        if (value is String) return colorFromString(value);
        if (value is Array) return colorFromArray(value, defValue);
        return FlxColor.WHITE;
    }

	inline public static function colorFromArray(colors:Array<Int>, ?defColors:Array<Int>) {
		colors = fixRGBColorArray(colors, defColors);
		return FlxColor.fromRGB(colors[0], colors[1], colors[2], colors[3]);
	}

	inline public static function fixRGBColorArray(colors:Array<Int>, ?defColors:Array<Int>) {
		// helper function used on characters n such
		final endResult:Array<Int> = (defColors != null && defColors.length > 2) ? defColors : [255, 255, 255, 255]; // Red, Green, Blue, Alpha
		for (i in 0...endResult.length) if (colors[i] > -1) endResult[i] = colors[i];
		return endResult;
	}

	inline public static function colorFromString(color:String):FlxColor {
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	inline public static function callErrBox(title:String, context:String) {
        utils.system.NativeUtil.showMessageBox(title, context, utils.system.PlatformUtil.MessageBoxIcon.MSG_ERROR);
    }

	inline public static function createBackDrop(cellW:Int, cellH:Int, w:Int, h:Int, alt:Bool, color1:FlxColor, color2:FlxColor):FlxBackdrop {
		return new FlxBackdrop(flixel.addons.display.FlxGridOverlay.createGrid(cellW, cellH, w, h, alt, color1, color2));
	}

	// formatTime but epic
	public static function formatTime(time:Float):String {
		var secs:String = '' + Math.floor(time) % 60;
		var mins:String = '' + Math.floor(time / 60) % 60;
		var hour:String = '' + Math.floor(time / 3600) % 24;

		if (secs.length < 2) secs = '0$secs';

		var formattedtime:String = '$mins:$secs';
		if (hour != "0") {
			if (mins.length < 2) mins = '0$mins';
			formattedtime = '$hour:$mins:$secs';
		}
		return formattedtime;
	}
}