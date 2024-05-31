package utils;

import flixel.FlxBasic;
import flixel.addons.display.FlxBackdrop;

class CoolUtil {
	inline public static function capitalize(text:String):String {
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();
	}

	inline public static function coolTextFile(path:String):Array<String> {
		var daList:String = null;
		#if (sys && MODS_ALLOWED)
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

	public static function getRNGTxt(max:Int, ?includespace:Bool, ?chance:Int = 50):String {
        var temp_str:String = "";
        for (_ in 0...max) {
            temp_str += String.fromCharCode(FlxG.random.int(65, 122));
			if (includespace && FlxG.random.bool(chance)) temp_str += "\n";
		}
        return temp_str;
    }

	inline public static function sortByID(i:Int, basic1:FlxBasic, basic2:FlxBasic):Int {
		return basic1.ID > basic2.ID ? -i : basic2.ID > basic1.ID ? i : 0;
	}

	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String {
		return '${FlxG.stage.application.meta.get('company')}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
	}

	public static function removeDupString(string:Array<String>):Array<String> {
		var tempArray:Array<String> = [];
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

	inline public static function colorFromArray(colors:Array<Int>, ?defColors:Array<Int>):FlxColor {
		colors = fixRGBColorArray(colors, defColors);
		return FlxColor.fromRGB(colors[0], colors[1], colors[2], colors[3]);
	}

	inline public static function fixRGBColorArray(colors:Array<Int>, ?defColors:Array<Int>):Array<Int> {
		// helper function used on characters n such
		final endResult:Array<Int> = (defColors != null && defColors.length > 2) ? defColors : [255, 255, 255, 255]; // Red, Green, Blue, Alpha
		for (i in 0...endResult.length) if (colors[i] > -1) endResult[i] = colors[i];
		return endResult;
	}

	inline public static function colorFromString(color:String):FlxColor {
		var hideChars:EReg = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	inline public static function createBackDrop(cellW:Int, cellH:Int, w:Int, h:Int, alt:Bool, color1:FlxColor, color2:FlxColor):FlxBackdrop {
		return new FlxBackdrop(flixel.addons.display.FlxGridOverlay.createGrid(cellW, cellH, w, h, alt, color1, color2));
	}

	// formatTime but epic
	public static function formatTime(time:Float, precision:Int = 0):String {
		var secs:String = '' + Math.floor(time) % 60;
		var mins:String = '' + Math.floor(time / 60) % 60;
		var hour:String = '' + Math.floor(time / 3600) % 24;
		var days:String = '' + Math.floor(time / 86400) % 7;
		var weeks:String = '' + Math.floor(time / (86400 * 7));

		if (secs.length < 2) secs = '0$secs';

		var formattedtime:String = '$mins:$secs';
		if (hour != "0" && days == '0') {
			if (mins.length < 2) mins = '0$mins';
			formattedtime = '$hour:$mins:$secs';
		}

		if (days != "0" && weeks == '0') formattedtime = days + 'd ' + hour + 'h ' + mins + "m " + secs + 's';
		if (weeks != "0") formattedtime = weeks + 'w ' + days + 'd ' + hour + 'h ' + mins + "m " + secs + 's';

		if (precision > 0) {
			var secondsForMS:Float = time % 60;
			var seconds:Int = Std.int((secondsForMS - Std.int(secondsForMS)) * Math.pow(10, precision));
			formattedtime += ".";
			if (precision > 1 && Std.string(seconds).length < precision) {
				for (_ in 0...precision - Std.string(seconds).length) formattedtime += '0';
			}
			formattedtime += seconds;
		}
		return formattedtime;
	}
}