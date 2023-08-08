package utils;

import flixel.util.FlxSave;
import openfl.geom.Rectangle;
import openfl.net.FileReference;
#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end

typedef FileSaveContext = {
	var content:String;
	var format:String;
	var fileDefaultName:String;
}

class CoolUtil {
	public static function saveFile(settings:FileSaveContext) {
		new FileReference().save(settings.content, settings.fileDefaultName + '.' + settings.format);
	}

	inline public static function quantize(f:Float, snap:Float) {
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		return (m / snap);
	}

	inline public static function capitalize(text:String) {
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();
	}

	inline public static function coolTextFile(path:String):Array<String> {
		#if sys
		if (FileSystem.exists(path)) return listFromString(File.getContent(path));
		#else
		if (Assets.exists(path)) return listFromString(Assets.getText(path));
		#end
		return [];
	}
	inline public static function listFromString(string:String):Array<String> {
		final daList = string.trim().split('\n');
		return [for(i in 0...daList.length) daList[i].trim()];
	}

	inline public static function dominantColor(sprite:FlxSprite):Int{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth) {
			for(row in 0...sprite.frameHeight) {
			  	var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
			  	if(colorOfThisPixel != 0) {
					if(countByColor.exists(colorOfThisPixel))
					    countByColor[colorOfThisPixel]++;
					else if(countByColor[colorOfThisPixel] != 13520687 - (2 * 13520687))
						countByColor[colorOfThisPixel] = 1;
			  	}
			}
		}
		var maxCount = 0;
		var maxKey:Int = 0;//after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for (key in countByColor.keys()) {
			if (countByColor[key] >= maxCount) {
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		return maxKey;
	}

	inline public static function numberArray(max:Int, ?min = 0):Array<Int> {
		return [for (i in min...max) i];
	}

	public static function GenerateLetterRank(accuracy:Float) { // generate a letter rankings
		var ranking:String = "N/A";
		var wifeConditions:Array<Dynamic> = [
			[accuracy >= 99.9935, "P"],
			[accuracy >= 99.980, "S+:"],
			[accuracy >= 99.970, "S+."],
			[accuracy >= 99.955, "S+"],
			[accuracy >= 99.90, "SS:"],
			[accuracy >= 99.80, "SS."],
			[accuracy >= 99.70, "SS"],
			[accuracy >= 99, "S:"],
			[accuracy >= 96.50, "S."],
			[accuracy >= 93, "S"],
			[accuracy >= 90, "A:"],
			[accuracy >= 85, "A."],
			[accuracy >= 80, "A"],
			[accuracy >= 70, "B"],
			[accuracy >= 60, "C"],
			[accuracy >= 50, "D"],
			[accuracy >= 20, "E"],
			[accuracy > 10, "F"],
		];

		for (i in 0...wifeConditions.length) {
			if (wifeConditions[i][0]) {
				ranking = wifeConditions[i][1];
				break;
			}
		}

		if (accuracy == 0) ranking = "N/A";
		return ranking;
	}

	inline public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site, "&"]);
		#else
		FlxG.openURL(site);
		#end
	}

	public static function makeSelectorGraphic(panel:FlxSprite, w:Int, h:Int, color:FlxColor, cornerSize:Float)
	{
		panel.makeGraphic(w, h, color);
		panel.pixels.fillRect(new Rectangle(0, 190, panel.width, 5), 0x0);
		
		// Why did i do this? Because i'm a lmao stupid, of course
		// also i wanted to understand better how fillRect works so i did this shit lol???
		panel.pixels.fillRect(new Rectangle(0, 0, cornerSize, cornerSize), 0x0);												//top left
		drawCircleCornerOnSelector(panel, false, false, color, cornerSize);
		panel.pixels.fillRect(new Rectangle(panel.width - cornerSize, 0, cornerSize, cornerSize), 0x0);						 	//top right
		drawCircleCornerOnSelector(panel, true, false, color, cornerSize);
		panel.pixels.fillRect(new Rectangle(0, panel.height - cornerSize, cornerSize, cornerSize), 0x0);						//bottom left
		drawCircleCornerOnSelector(panel, false, true, color, cornerSize);
		panel.pixels.fillRect(new Rectangle(panel.width - cornerSize, panel.height - cornerSize, cornerSize, cornerSize), 0x0); //bottom right
		drawCircleCornerOnSelector(panel, true, true, color, cornerSize);
	}

	static function drawCircleCornerOnSelector(panel:FlxSprite, flipX:Bool, flipY:Bool, color:FlxColor, cornerSize:Float)
	{
		var antiX:Float = panel.width - cornerSize;
		var antiY:Float = flipY ? (panel.height - 1) : 0;
		if(flipY) antiY -= 2;
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 1), Std.int(Math.abs(antiY - 8)), 10, 3), color);
		if(flipY) antiY++;
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 2), Std.int(Math.abs(antiY - 6)),  9, 2), color);
		if(flipY) antiY++;
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 3), Std.int(Math.abs(antiY - 5)),  8, 1), color);
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 4), Std.int(Math.abs(antiY - 4)),  7, 1), color);
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 5), Std.int(Math.abs(antiY - 3)),  6, 1), color);
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 6), Std.int(Math.abs(antiY - 2)),  5, 1), color);
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 8), Std.int(Math.abs(antiY - 1)),  3, 1), color);
	}

	public static function getRandomizedText(max:Int):String {
        var temp_str:String = "";
        for (i in 0...max)
            temp_str += String.fromCharCode(FlxG.random.int(65, 122));
        return temp_str;
    }

	@:access(flixel.util.FlxSave.validate)
	public static function getSavePath(folder:String = 'altertoriel'):String {
		return FlxG.stage.application.meta.get('company') + '/' + FlxSave.validate(FlxG.stage.application.meta.get('file'));
	}

	public static function removeDuplicates(string:Array<String>):Array<String> {
		var tempArray:Array<String> = new Array<String>();
		var lastSeen:String = null;
		string.sort(function(str1:String, str2:String) {
		  	return (str1 == str2) ? 0 : (str1 > str2) ? 1 : -1; 
		});
		for (str in string) {
		  	if (str != lastSeen) tempArray.push(str);
		  	lastSeen = str;
		}
		return tempArray;
	}

	inline public static function dynamicArray<T>(v:T, len:Int):Array<T> {
		return [for (_ in 0...len) v];
	}

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

	inline public static function colorFromString(color:String):FlxColor {
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	public static function formatTime(sec:Float):String {
		var hoursRemaining:Int = Math.floor(sec / 3600);
		var minutesRemaining:Int = Math.floor(sec / 60) % 60;
		var minutesRemainingShit:String = Std.string(minutesRemaining);
		var secondsRemaining:String = Std.string(sec % 60);

		if (secondsRemaining.length < 2) secondsRemaining = '0${secondsRemaining}';
		if (minutesRemainingShit.length < 2) minutesRemainingShit = '0${minutesRemaining}'; 

		if(sec <= 3600000)
			return flixel.util.FlxStringUtil.formatTime(sec);
		else if(sec >= 3600000)
			return '$hoursRemaining:$minutesRemainingShit:$secondsRemaining';
		return '';
	}

	public static function callErrBox(title:String, context:String) {
        #if hl
		var flags:haxe.EnumFlags<hl.UI.DialogFlags> = new haxe.EnumFlags<hl.UI.DialogFlags>();
		flags.set(IsError);
		hl.UI.dialog(title, context, flags);
		#else
		lime.app.Application.current.window.alert(context, title);
		#end
    }
}
