package utils;

import flixel.FlxG;
#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end
import states.PlayState;

using StringTools;

class CoolUtil
{
	public static var defaultDifficulties:Array<String> = [
		'Easy',
		'Normal',
		'Hard'
	];
	public static var defaultDifficulty:String = 'Normal'; //The chart that has no suffix and starting difficulty on Freeplay/Story Mode

	public static var difficulties:Array<String> = [];
	public static var lowerDifficulties(get, null):Array<String>;
	static function get_lowerDifficulties():Array<String> {
		return [for (v in difficulties) v.toLowerCase()];
	}

	inline public static function quantize(f:Float, snap:Float){
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		return (m / snap);
	}
	
	public static function getDifficultyFilePath(num:Null<Int> = null)
	{
		if(num == null) num = PlayState.storyDifficulty;

		var fileSuffix:String = difficulties[num];
		if(fileSuffix != defaultDifficulty) {
			fileSuffix = '-' + fileSuffix;
		} else {
			fileSuffix = '';
		}
		return Paths.formatToSongPath(fileSuffix);
	}

	public static function difficultyString():String {
		return difficulties[PlayState.storyDifficulty].toUpperCase();
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];
		#if sys
		if(FileSystem.exists(path)) daList = File.getContent(path).trim().split('\n');
		#else
		if(Assets.exists(path)) daList = Assets.getText(path).trim().split('\n');
		#end

		return [for (i in 0...daList.length) daList[i].trim()];
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
			  	if(colorOfThisPixel != 0){
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
		countByColor[flixel.util.FlxColor.BLACK] = 0;
		for (key in countByColor.keys()) {
			if (countByColor[key] >= maxCount) {
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		return maxKey;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int> {
		return [for (i in min...max) i];
	}

	//uhhhh does this even work at all? i'm starting to doubt
	public static function precacheSound(sound:String, ?library:String = null):Void {
		Paths.sound(sound, library);
	}

	public static function precacheMusic(sound:String, ?library:String = null):Void {
		Paths.music(sound, library);
	}

	public static function GenerateLetterRank(accuracy:Float) { // generate a letter rankings
		var ranking:String = "N/A";
		var wifeConditions:Array<Dynamic> = [
			[accuracy >= 99.9935, "AAAAA"],
			[accuracy >= 99.980, "AAAA:"],
			[accuracy >= 99.970, "AAAA."],
			[accuracy >= 99.955, "AAAA"],
			[accuracy >= 99.90, "AAA:"],
			[accuracy >= 99.80, "AAA."],
			[accuracy >= 99.70, "AAA"],
			[accuracy >= 99, "AA:"],
			[accuracy >= 96.50, "AA."],
			[accuracy >= 93, "AA"],
			[accuracy >= 90, "A:"],
			[accuracy >= 85, "A."],
			[accuracy >= 80, "A"],
			[accuracy >= 70, "B"],
			[accuracy >= 60, "C"],
			[accuracy < 60, "D"]
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

	public static function adjustFPS(num:Float):Float {
		return FlxG.elapsed / (1 / 60) * num;
	}

	public static function getSpilttext(path:String):Array<String>
	{
		var firstArray:Array<String> = [];
		#if sys
		if(FileSystem.exists(path)) firstArray = File.getContent(path).trim().split('\n');
		#else
		if(Assets.exists(path)) firstArray = Assets.getText(path).trim().split('\n');
		#end

		return [for (i in 0...firstArray.length) firstArray[i].trim().replace("-", " ")];
	}

	public static function browserLoad(site:String) {
		#if windows
		FlxG.openURL(site);
		#end
	}
}
