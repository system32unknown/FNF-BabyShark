package;

import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import openfl.system.System;
import openfl.utils.AssetCache;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssetsUtil;
import openfl.Assets as OpenFlAssets;
import openfl.display.BitmapData;
import lime.utils.Assets;
import flash.media.Sound;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
import haxe.Json;
import haxe.io.Path;

import utils.CoolUtil;

@:access(openfl.display.BitmapData.__texture)
@:access(openfl.media.Sound.__buffer)
class Paths
{
	inline public static var SOUND_EXT = "ogg";
	inline public static var VIDEO_EXT = "mp4";

	#if MODS_ALLOWED
	public static var ignoreModFolders:Array<String> = [
		'characters',
		'custom_events',
		'custom_notetypes',
		'custom_gamechangers',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'achievements'
	];
	#end

	public static function excludeAsset(asset:Dynamic) {
		if ((asset is String)) {
			var key:String = asset;
			for (v in keyExclusions) if (key.endsWith(v)) return;
			keyExclusions.push(key);
			return;
		}
		if (!keyExclusions.contains(asset)) keyExclusions.push(asset);
	}

	public static function unexcludeAsset(asset:Dynamic) {
		if ((asset is String)) {
			var key:String = asset;
			for (v in keyExclusions) if (key.endsWith(v)) keyExclusions.remove(v);
			return;
		}
		keyExclusions.remove(asset);
	}

	public static function assetExcluded(asset:Dynamic):Bool {
		if ((asset is String)) {
			var key:String = asset;
			for (v in keyExclusions) if (key.endsWith(v)) return true;
			return false;
		}
		for (v in keyExclusions) if (v == asset) return true;
		return false;
	}

	public static var keyExclusions:Array<String> = [
		'music/freakyMenu.$SOUND_EXT',
		'music/breakfast.$SOUND_EXT',
		'music/tea-time.$SOUND_EXT',
	];

	public static function decacheGraphic(key:String) {
		var obj = currentTrackedAssets.get(key);
		@:privateAccess {
			if (obj == null)
				obj = FlxG.bitmap._cache.get(key);
			if (obj != null) {
				if (assetExcluded(obj)) return;

				OpenFlAssetsUtil.cache.removeBitmapData(key);
				Assets.cache.clear(key);
				FlxG.bitmap._cache.remove(key);

				if (obj.bitmap != null) {
					obj.bitmap.lock();
					if (obj.bitmap.__texture != null)
						obj.bitmap.__texture.dispose();
					obj.bitmap.disposeImage();
				}

				obj.destroy();
				currentTrackedAssets.remove(key);
			}
		}
	}

	public static function decacheSound(key:String) {
		var obj = currentTrackedSounds.get(key);
		if (obj == null && OpenFlAssetsUtil.cache.hasSound(key)) obj = OpenFlAssets.cache.getSound(key);
		if (assetExcluded(obj)) return;

		OpenFlAssetsUtil.cache.removeSound(key);
		Assets.cache.clear(key);
		currentTrackedSounds.remove(key);

		if (obj != null) {
			if (obj.__buffer != null) {
				obj.__buffer.dispose();
				obj.__buffer = null;
			}
			obj = null;
		}
	}

	// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory() {
		for (key in currentTrackedAssets.keys()) {
			if (!localTrackedAssets.contains(key) && !assetExcluded(key)) {
				decacheGraphic(key);
			}
		}
		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];
	public static function clearStoredMemory() {
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys()) {
			if (key != null && !currentTrackedAssets.exists(key) && !assetExcluded(key))
				decacheGraphic(key);
		}

		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys()) {
			if (key != null && !localTrackedAssets.contains(key) && !assetExcluded(key))
				decacheSound(key);
		}
		
		var cache = cast(OpenFlAssets.cache, AssetCache);
		for (key => font in cache.font)
			cache.removeFont(key);

		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		#if !html5 cache.clear("songs"); #end
		System.gc();
	}

	static public var currentModDirectory:String = '';
	static public var currentLevel:String;
	static public function setCurrentLevel(name:String) {
		currentLevel = name.toLowerCase();
	}

	public static function checkReservedFile(text:String):Bool {
		var forbidden:Array<String> = ['AUX', 'CON', 'PRN', 'NUL']; // thanks kingyomoma
		for (i in 1...9) {
			forbidden.push('COM$i');
			forbidden.push('LPT$i');
		}
		for (donot in forbidden) {
			if (text == donot) {
				return true;
				break;
			}
		}
		return false;
	}

	public static function getPath(file:String, type:AssetType, ?library:Null<String> = null) {
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null) {
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(file, currentLevel);
				if (OpenFlAssetsUtil.exists(levelPath, type))
					return levelPath;
			}

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssetsUtil.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload") {
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
		return '$library:assets/$library/$file';

	inline public static function getPreloadPath(file:String = '')
		return 'assets/$file';

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
		return getPath(file, type, library);

	inline static public function txt(key:String, ?library:String)
		return getPath('data/$key.txt', TEXT, library);
	
	inline static public function json(key:String, ?library:String)
		return getPath('data/$key.json', TEXT, library);

	static public function video(key:String) {
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if (FileSystem.exists(file)) return file;
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	inline static public function sound(key:String, ?library:String):Sound
		return returnSound('sounds', key, library);

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
		return sound(key + FlxG.random.int(min, max), library);

	inline static public function music(key:String, ?library:String):Sound
		return returnSound('music', key, library);

	inline static public function voices(song:String):Any {
		#if html5
		return 'songs:assets/songs/${formatToSongPath(song)}/Voices.$SOUND_EXT';
		#else
		return returnSound('songs', '${formatToSongPath(song)}/Voices');
		#end
	}

	inline static public function inst(song:String):Any {
		#if html5
		return 'songs:assets/songs/${formatToSongPath(song)}/Inst.$SOUND_EXT';
		#else
		return returnSound('songs', '${formatToSongPath(song)}/Inst');
		#end
	}
		
	// streamlined the assets process more
	inline static public function image(key:String, ?library:String):FlxGraphic
		return returnGraphic(key, library);

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if sys
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(modFolders(key)))
			return File.getContent(modFolders(key));
		#end

		if (FileSystem.exists(getPreloadPath(key)))
			return File.getContent(getPreloadPath(key));

		if (currentLevel != null) {
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(key, currentLevel);
				if (FileSystem.exists(levelPath))
					return File.getContent(levelPath);
			}

			levelPath = getLibraryPathForce(key, 'shared');
			if (FileSystem.exists(levelPath))
				return File.getContent(levelPath);
		}
		#end
		return Assets.getText(getPath(key, TEXT));
	}

	inline static public function font(key:String):String
	{
		#if MODS_ALLOWED
		var file:String = modsFont(key);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/fonts/$key';
	}

	inline static public function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?isPath:Bool = false, ?library:String):Bool
	{
		#if MODS_ALLOWED
		if(!ignoreMods && (FileSystem.exists(mods('$currentModDirectory/$key')) || FileSystem.exists(mods(key)))) {
			return true;
		}
		#end

		return OpenFlAssetsUtil.exists((isPath ? key : getPath(key, type)));
	}

	inline static public function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key);
		var xmlExists:Bool = FileSystem.exists(modsXml(key));

		return FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : image(key, library)), (xmlExists ? File.getContent(modsXml(key)) : file('images/$key.xml', library)));
		#else
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key);
		var txtExists:Bool = FileSystem.exists(modsTxt(key));

		return FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image(key, library)), (txtExists ? File.getContent(modsTxt(key)) : file('images/$key.txt', library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
		#end
	}

	inline static public function formatToSongPath(path:String) {
		var invalidChars = ~/[~&\\;:<>#]+/g;
		var hideChars = ~/[.,'"%?!]+/g;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	// completely rewritten asset loading? fuck!
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static function returnGraphic(key:String, ?library:String):FlxGraphic {
		#if MODS_ALLOWED
		var modKey:String = modsImages(key);
		if(FileSystem.exists(modKey)) {
			if(!currentTrackedAssets.exists(modKey)) {
				var newBitmap:BitmapData = BitmapData.fromFile(modKey);
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, modKey);

				newGraphic.persist = true;
				currentTrackedAssets.set(modKey, newGraphic);
			}
			localTrackedAssets.push(modKey);
			return currentTrackedAssets.get(modKey);
		}
		#end

		var path = getPath('images/$key.png', IMAGE, library);
		if (OpenFlAssetsUtil.exists(path, IMAGE)) {
			if(!currentTrackedAssets.exists(path)) {
				var newGraphic:FlxGraphic = FlxG.bitmap.add(path, false, path);
				newGraphic.persist = true;
				currentTrackedAssets.set(path, newGraphic);
			}
			localTrackedAssets.push(path);
			return currentTrackedAssets.get(path);
		}
		trace('oh no $key and $library, $path is returning null NOOOO');
		return null;
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(path:String, key:String, ?library:String) {
		#if MODS_ALLOWED
		var file:String = modsSounds(path, key);
		if(FileSystem.exists(file)) {
			if(!currentTrackedSounds.exists(file)) {
				currentTrackedSounds.set(file, Sound.fromFile(file));
			}
			localTrackedAssets.push(key);
			return currentTrackedSounds.get(file);
		}
		#end
		// I hate this so god damn much
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		if(!currentTrackedSounds.exists(gottenPath))
		#if MODS_ALLOWED
			currentTrackedSounds.set(gottenPath, Sound.fromFile('./$gottenPath'));
		#else
		{
			var folder:String = '';
			if(path == 'songs') folder = 'songs:';

			currentTrackedSounds.set(gottenPath, OpenFlAssetsUtil.getSound(folder + getPath('$path/$key.$SOUND_EXT', SOUND, library)));
		}
		#end
		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '')
		return 'mods/$key';

	inline static public function modsFont(key:String)
		return modFolders('fonts/$key');

	inline static public function modsJson(key:String)
		return modFolders('data/$key.json');

	inline static public function modsVideo(key:String)
		return modFolders('videos/$key.$VIDEO_EXT');

	inline static public function modsSounds(path:String, key:String)
		return modFolders(path + '/' + key + '.' + SOUND_EXT);

	inline static public function modsImages(key:String)
		return modFolders('images/$key.png');

	inline static public function modsXml(key:String)
		return modFolders('images/$key.xml');

	inline static public function modsTxt(key:String)
		return modFolders('images/$key.txt');

	static public function modFolders(key:String) {
		if(currentModDirectory != null && currentModDirectory.length > 0) {
			var fileToCheck:String = mods('$currentModDirectory/$key');
			if(FileSystem.exists(fileToCheck)) {
				return fileToCheck;
			}
		}

		for(mod in getGlobalMods()) {
			var fileToCheck:String = mods('$mod/$key');
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;
		}
		return 'mods/' + key;
	}

	public static var globalMods:Array<String> = [];

	static public function getGlobalMods()
		return globalMods;

	static public function pushGlobalMods() // prob a better way to do this but idc
	{
		globalMods = [];
		var path:String = 'modsList.txt';
		if(FileSystem.exists(path)) {
			var list:Array<String> = CoolUtil.coolTextFile(path);
			for (i in list) {
				var dat = i.split("|");
				if (dat[1] == "1") {
					var folder = dat[0];
					var path = Paths.mods('$folder/pack.json');
					if(FileSystem.exists(path)) {
						try {
							var rawJson:String = File.getContent(path);
							if(rawJson != null && rawJson.length > 0) {
								var stuff:Dynamic = Json.parse(rawJson);
								var global:Bool = Reflect.getProperty(stuff, "runsGlobally");
								if(global)globalMods.push(dat[0]);
							}
						} catch(e:Dynamic) trace(e);
					}
				}
			}
		}
		return globalMods;
	}

	static public function getModDirectories(lowercase:Bool = false):Array<String> {
		var list:Array<String> = [];
		var modsFolder:String = mods();

		if (!FileSystem.exists(modsFolder)) return list;

		for (folder in FileSystem.readDirectory(modsFolder)) {
			var path:String = haxe.io.Path.join([modsFolder, folder]);
			var lower:String = folder.toLowerCase();

			if (FileSystem.isDirectory(path) && !ignoreModFolders.contains(lower) && !list.contains(lower))
				list.push(lowercase ? lower : folder);
		}

		return list;
	}

	static public function getActiveModDirectories(lowercase:Bool = false):Array<String> {
		var list:Array<String> = [];
		final path:String = 'modsList.txt';

		var remains:Array<String> = getModDirectories(true);

		if (remains.length <= 0 || !FileSystem.exists(path)) return list;
		var leMods:Array<String> = CoolUtil.coolTextFile(path);

		for (i in 0...leMods.length) {
			if (remains.length <= 0) break;
			if (leMods.length > 1 && leMods[0].length > 0) {
				var modSplit:Array<String> = leMods[i].split('|');
				var modLower:String = modSplit[0].toLowerCase();

				if (remains.contains(modLower) && modSplit[1] == '1') {
					remains.remove(modLower);
					list.push(lowercase ? modLower : modSplit[0]);
				}
			}
		}

		remains = null;
		return list;
	}
	#end


	#if LUA_ALLOWED
	static public function getLuaPackagePath():String {
		var toAdd:Array<String> = ['.'];
		#if MODS_ALLOWED
		toAdd.push('./mods');
		if (currentModDirectory != null && currentModDirectory.length > 0)
			toAdd.push('./mods/$currentModDirectory');
		for (mod in getGlobalMods()) toAdd.push('./mods/$mod');
		#end
		toAdd.push('./assets');
		var paths:Array<String> = [];
		for (path in toAdd) {
			#if sys
			path = FileSystem.absolutePath(path);
			#end
			paths.push(Path.join([path, '?.lua']));
			paths.push(Path.join([path, '?', 'init.lua']));
		}
		return paths.join(';');
	}
	#end
}
