package utils;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import openfl.geom.Rectangle;
#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end

class CoolUtil
{
	inline public static function quantize(f:Float, snap:Float) {
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		return (m / snap);
	}

	public static function coolTextFile(path:String):Array<String> {
		#if sys
		if(FileSystem.exists(path)) return [for (i in File.getContent(path).trim().split('\n')) i.trim()];
		#else
		if(Assets.exists(path)) return [for (i in Assets.getText(path).trim().split('\n')) i.trim()];
		#end
		return [];
	}
	public static function listFromString(string:String):Array<String> {
		final daList = string.trim().split('\n');
		return [for(i in 0...daList.length) daList[i].trim()];
	}

	public static function dominantColor(sprite:flixel.FlxSprite):Int{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth) {
			for(row in 0...sprite.frameHeight) {
			  	var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
			  	if(colorOfThisPixel != 0) {
					if(countByColor.exists(colorOfThisPixel)) {
					    countByColor[colorOfThisPixel] =  countByColor[colorOfThisPixel] + 1;
					} else if(countByColor[colorOfThisPixel] != 13520687 - (2 * 13520687)) {
						countByColor[colorOfThisPixel] = 1;
					}
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

	//uhhhh does this even work at all? i'm starting to doubt
	inline public static function precacheSound(sound:String, ?library:String = null):Void {
		Paths.sound(sound, library);
	}
	inline public static function precacheMusic(sound:String, ?library:String = null):Void {
		Paths.music(sound, library);
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
		#if windows
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
		if(flipY) antiY += 1;
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 2), Std.int(Math.abs(antiY - 6)),  9, 2), color);
		if(flipY) antiY += 1;
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
		return #if (flixel < "5.0.0") folder #else FlxG.stage.application.meta.get('company')
			+ '/'
			+ FlxSave.validate(FlxG.stage.application.meta.get('file')) #end;
	}

	public static function getMacroAbstractClass(className:String)
		return Type.resolveClass('${className}_HSC');

	public static function removeDuplicates(string:Array<String>):Array<String> {
		var tempArray:Array<String> = new Array<String>();
		var lastSeen:String = null;
		string.sort(function(str1:String, str2:String) {
		  	return (str1 == str2) ? 0 : (str1 > str2) ? 1 : -1; 
		});
		for (str in string) {
		  	if (str != lastSeen) {
				tempArray.push(str);
		  	}
		  	lastSeen = str;
		}
		return tempArray;
	}

	public static function dynamicArray<T>(v:T, len:Int):Array<T> {
		return [for (_ in 0...len) v];
	}
}
