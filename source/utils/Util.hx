package utils;

import haxe.Http;
import openfl.utils.Assets;
import flixel.addons.display.FlxBackdrop;

class Util {
	public static function checkForUpdates(url:String = null):Array<String> {
		if (url == null || url.length == 0)
			url = "https://raw.githubusercontent.com/system32unknown/FNF-BabyShark/main/CHANGELOG.md";

		var returnedData:Array<String> = [];
		var version:String = Main.engineVer;
		if (Settings.data.checkForUpdates) {
			trace('checking for updates...');
			var http:Http = new Http(url);

			http.onData = (data:String) -> {
				var verEndIdx:Int = data.indexOf(';');
				returnedData[0] = data.substring(0, verEndIdx);
				returnedData[1] = data.substring(verEndIdx + 1, data.length); // Extract the changelog after the version number

				var updateVersion:GameVersion = returnedData[0];
				trace('version online: $updateVersion, your version: $version');
				if (updateVersion != version) {
					trace('versions arent matching! please update.');
					http.onData = http.onError = null;
					http = null;
				}
			}
			http.onError = (error:String) -> Logs.trace('HTTP Error: $error', ERROR);
			http.request();
		}
		return returnedData;
	}

	inline public static function toBool(value:Dynamic):Null<Bool> {
		if (value is Int || value is Float) return (value >= 1);
		return null;
	}

	/**
	 * Plays a sound safely by checking if it exists or not.
	 *
	 * made to play some sounds in-game with no concerns as to whether it will crash or not.
	 *
	 * this is safer than calling Paths.sound due to an extra check
	 * @param sound					The sound stream (i.e: String, openfl.media.Sound, etc)
	 * @param volume				Sound's volume
	**/
	public static function playSoundSafe(sound:flixel.system.FlxAssets.FlxSoundAsset, volume:Float = 1.0) {
		if (sound != null) FlxG.sound.play(sound, volume);
	}

	public static function coolTextFile(path:String):Array<String> {
		var daList:String = null;
		#if (sys && MODS_ALLOWED)
		if (FileSystem.exists(path)) daList = File.getContent(path);
		#else
		if (Assets.exists(path)) daList = Assets.getText(path);
		#end
		return daList == null ? [] : listFromString(daList);
	}

	public static function listFromString(string:String):Array<String> {
		final daList:Array<String> = string.trim().split('\n');
		return [for (i in 0...daList.length) daList[i].trim()];
	}

	/**
	 * Runs platform-specific code to open a URL in a web browser.
	 * @param site The URL to open.
	 * @return Results URL status.
	 */
	public static function browserLoad(site:String):Int {
		#if linux
		var cmd:Int = Sys.command("xdg-open", [site]); // generally `xdg-open` should work in every distro
		if (cmd != 0) cmd = Sys.command("/usr/bin/xdg-open", [site]); // run old command JUST IN CASE it fails, which it shouldn't
		return cmd;
		#else
		FlxG.openURL(site);
		return 1;
		#end
	}

	/**
	 * Opens a specified folder in the system's default file explorer.
	 * @param folder The path to the folder to open.
	 * @param absolute If true, uses the provided absolute path; otherwise, resolves the folder relative to the current working directory.
	 */
	inline public static function openFolder(folder:String, absolute:Bool = false):Void {
		#if sys
		if (!absolute) folder = Sys.getCwd() + '$folder';
		folder = folder.replace('/', '\\');
		if (folder.endsWith('/')) folder.substr(0, folder.length - 1);

		var commandOpen:String = '';
		#if windows
		commandOpen = 'explorer.exe';
		#elseif mac
		commandOpen = 'open';
		#else
		commandOpen = '/usr/bin/xdg-open';
		#end

		Sys.command(commandOpen, [folder]);
		#else
		FlxG.error("Platform is not supported for Util.openFolder");
		#end
	}

	/**
	 * Runs platform-specific code to open a file explorer and select a specific file.
	 * @param targetPath The path of the file to select.
	 */
	public static function openSelectFile(targetPath:String):Void {
		#if windows
		Sys.command('explorer', ['/select,' + targetPath.replace('/', '\\')]);
		#elseif mac
		Sys.command('open', ['-R', targetPath]);
		#elseif linux
		// TODO: unsure of the linux equivalent to opening a folder and then "selecting" a file.
		Sys.command('open', [targetPath]);
		#end
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
		if (color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color) ?? FlxColor.fromString('#$color');
		return colorNum ?? FlxColor.WHITE;
	}

	public static inline function createBackDrop(cellW:Int, cellH:Int, w:Int, h:Int, alt:Bool, color1:FlxColor, color2:FlxColor):FlxBackdrop {
		return new FlxBackdrop(flixel.addons.display.FlxGridOverlay.createGrid(cellW, cellH, w, h, alt, color1, color2));
	}

	public static function recursivelyReadFolders(path:String, ?erasePath:Bool = true) {
		var ret:Array<String> = [];
		for (i in FileSystem.readDirectory(path)) returnFileName(i, ret, path);
		if (erasePath) {
			path += '/';
			for (i in 0...ret.length) ret[i] = ret[i].replace(path, '');
		}
		return ret;
	}

	static function returnFileName(path:String, toAdd:Array<String>, full:String) {
		var fullPath:String = '$full/$path';
		if (FileSystem.isDirectory(fullPath)) {
			for (i in FileSystem.readDirectory(fullPath)) returnFileName(i, toAdd, fullPath);
		} else toAdd.push(fullPath.replace('.json', ''));
	}
}