package backend;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.display.BitmapData;
import openfl.media.Sound;
import lime.utils.Assets;

@:access(openfl.display.BitmapData.__texture)
@:access(openfl.media.Sound.__buffer)
class Paths
{
	inline public static final CHART_PATH = "charts";
	inline public static var SOUND_EXT = "ogg";
	inline public static var VIDEO_EXT = "mp4";

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

	public static function decacheSound(key:String) {
		var obj = currentTrackedSounds.get(key);
		currentTrackedSounds.remove(key);

		if (obj == null && OpenFlAssets.cache.hasSound(key)) obj = OpenFlAssets.cache.getSound(key);
		if (obj == null || assetExcluded(obj)) return;

		OpenFlAssets.cache.removeSound(key);
		Assets.cache.clear(key);
		
		if (obj.__buffer != null) {
			obj.__buffer.dispose();
			obj.__buffer = null;
		}
		obj = null;
	}

	public static function decacheGraphic(key:String) @:privateAccess {
		var obj = currentTrackedAssets.get(key);
		currentTrackedAssets.remove(key);
		if ((obj == null && (obj = FlxG.bitmap._cache.get(key)) == null) || assetExcluded(obj)) return;

		OpenFlAssets.cache.removeBitmapData(key);
		OpenFlAssets.cache.clear(key);
		FlxG.bitmap._cache.remove(key);

		if (obj.bitmap != null) {
			obj.bitmap.lock();
			if (obj.bitmap.__texture != null) obj.bitmap.__texture.dispose();
			if (obj.bitmap.image != null) obj.bitmap.image.data = null;
			obj.bitmap.disposeImage();
		}

		obj.persist = false;
		obj.destroyOnNoUse = true;

		obj.dump();
		obj.destroy();
		obj = null;
	}

	// haya I love you for the base cache dump I took to the max
	public static function clearUnusedCache() {
		for (key in currentTrackedAssets.keys()) {
			if (!localTrackedAssets.contains(key) && !keyExclusions.contains(key))
				decacheGraphic(key);
		}

		#if cpp
		utils.system.MemoryUtil.clearMajor();
		#else
		openfl.system.System.gc();
		#end
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];
	public static function clearStoredCache() {
		for (key in @:privateAccess FlxG.bitmap._cache.keys()) {
			if (key != null && !currentTrackedAssets.exists(key) && !assetExcluded(key))
				decacheGraphic(key);
		}

		for (key in currentTrackedSounds.keys()) {
			if (key != null && !localTrackedAssets.contains(key) && !assetExcluded(key))
				decacheSound(key);
		}

		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		#if !html5 openfl.Assets.cache.clear("songs"); #end
		utils.system.MemoryUtil.clearMajor();
		clearUnusedCache();
	}

	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();

	public static function checkReservedFile(text:String):Bool {
		final forbidden:Array<String> = ['AUX', 'CON', 'PRN', 'NUL']; // thanks kingyomoma
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

	public static function getPath(file:String, ?type:AssetType = TEXT, ?library:Null<String> = null, ?modsAllowed:Bool = false):String {
		#if MODS_ALLOWED
		if(modsAllowed) {
			var modded:String = modFolders(file);
			if(FileSystem.exists(modded)) return modded;
		}
		#end

		if (library != null) return getLibraryPath(file, library);

		if (currentLevel != null) {
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(file, 'week_assets', currentLevel);
				if (OpenFlAssets.exists(levelPath, type)) return levelPath;
			}

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type)) return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload") {
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String, ?level:String) {
		if (level == null) level = library;
		return '$library:assets/$level/$file';
	}

	inline public static function getPreloadPath(file:String = '')
		return 'assets/$file';

	inline static public function txt(key:String, ?library:String)
		return getPath('data/$key.txt', TEXT, library);
	
	inline static public function json(key:String, ?library:String)
		return getPath('data/$key.json', TEXT, library);

	#if (!MODS_ALLOWED) inline #end static public function video(key:String) {
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if (FileSystem.exists(file)) return file;
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}
	#if (!MODS_ALLOWED) inline #end static public function sound(key:String, ?library:String):Sound
		return returnSound('sounds', key, library);

	#if (!MODS_ALLOWED) inline #end static public function soundRandom(key:String, min:Int, max:Int, ?library:String):Sound
		return sound(key + FlxG.random.int(min, max), library);

	public static var streamMusic:Bool = false;
	#if (!MODS_ALLOWED) inline #end static public function music(key:String, ?library:String, ?stream:Bool):Sound {
		return returnSound('music', key, library, stream || streamMusic);
	}

	// streamlined the assets process more
	#if (!MODS_ALLOWED) inline #end static public function image(key:String, ?library:String):FlxGraphic
		return returnGraphic(key, library);

	#if (!MODS_ALLOWED) inline #end static public function inst(song:String, ?stream:Bool, forceNoStream:Bool = false):Sound
		return returnSound('songs', '${formatToSongPath(song)}/Inst', !forceNoStream && (stream || streamMusic));

	#if (!MODS_ALLOWED) inline #end static public function voices(song:String, ?stream:Bool, forceNoStream:Bool = false):Sound
		return returnSound('songs', '${formatToSongPath(song)}/Voices', !forceNoStream && (stream || streamMusic));

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false, ?absolute:Bool = false):String {
		if (absolute) {
			#if sys
			if (FileSystem.exists(key)) return File.getContent(key);
			#end
			if(OpenFlAssets.exists(key, TEXT)) return Assets.getText(key);

			return null;
		}
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
				levelPath = getLibraryPathForce(key, 'week_assets', currentLevel);
				if (FileSystem.exists(levelPath))
					return File.getContent(levelPath);
			}

			levelPath = getLibraryPathForce(key, 'shared');
			if (FileSystem.exists(levelPath))
				return File.getContent(levelPath);
		}
		#end
		var path:String = getPath(key, TEXT);
		if(OpenFlAssets.exists(path, TEXT)) return Assets.getText(path);
		return null;
	}

	inline static public function font(key:String):String {
		#if MODS_ALLOWED
		var file:String = modsFont(key);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/fonts/$key';
	}

	static public function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?isPath:Bool = false, ?library:String):Bool {
		#if MODS_ALLOWED
		if(!ignoreMods) {
			for(mod in Mods.getGlobalMods())
				if (FileSystem.exists(mods('$mod/$key')))
					return true;

			if (FileSystem.exists(mods('${Mods.currentModDirectory}/$key')) || FileSystem.exists(mods(key)))
				return true;
		}
		#end

		return OpenFlAssets.exists((isPath ? key : getPath(key, type, library, false)));
	}

	inline static public function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames {
		var imageLoaded:FlxGraphic = image(key, library);
		#if MODS_ALLOWED
		var xmlExists:Bool = false;
		var xml:String = modsXml(key);
		if(FileSystem.exists(xml)) xmlExists = true;

		return FlxAtlasFrames.fromSparrow(imageLoaded, (xmlExists ? File.getContent(xml) : getPath('images/$key.xml', library)));
		#else
		return FlxAtlasFrames.fromSparrow(imageLoaded, getPath('images/$key.xml', library));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?library:String):FlxAtlasFrames {
		var imageLoaded:FlxGraphic = image(key, library);
		#if MODS_ALLOWED
		var txtExists:Bool = false;
		var txt:String = modsTxt(key);
		if(FileSystem.exists(txt)) txtExists = true;

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, (txtExists ? File.getContent(txt) : getPath('images/$key.txt', library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, getPath('images/$key.txt', library));
		#end
	}

	inline static public function formatToSongPath(path:String) {
		var invalidChars = ~/[~&\\;:<>#]+/g;
		var hideChars = ~/[.,'"%?!]+/g;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	static var assetCompressTrack:Int = 0;
	@:noCompletion static function stepAssetCompress():Void {
		assetCompressTrack++;
		if (assetCompressTrack > 6) {
			assetCompressTrack = 0;
			utils.system.MemoryUtil.clearMajor();
		}
	}

	public static var hardwareCache:Bool = false;
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static function returnGraphic(key:String, ?library:String):FlxGraphic {
		var modExists:Bool = false, graph:FlxGraphic = null;

		#if MODS_ALLOWED
		var modKey:String = modsImages(key);
		if ((graph = currentTrackedAssets.get(modKey)) != null) {
			localTrackedAssets.push(modKey);
			return graph;
		}

		var srcKey:String = getPath('images/$key.png', IMAGE, library);
		if ((graph = currentTrackedAssets.get(srcKey)) != null) {
			localTrackedAssets.push(srcKey);
			return graph;
		} else modExists = FileSystem.exists(modKey);

		var path:String = modExists ? modKey : srcKey;
		#else
		var path:String = getPath('images/$key.png', IMAGE, library);
		if ((graph = currentTrackedAssets.get(path)) != null) return graph;
		#end

		if (modExists || OpenFlAssets.exists(path, IMAGE)) {
			localTrackedAssets.push(path);

			var bitmap:BitmapData = _regBitmap(path, hardwareCache, modExists);
			if (bitmap != null) graph = FlxGraphic.fromBitmapData(bitmap, false, path);

			if (graph != null) {
				graph.persist = true;
				graph.destroyOnNoUse = false;
				currentTrackedAssets.set(path, graph);
				return graph;
			}
		}

		Logs.trace('returnGraphic returning null: $path' #if MODS_ALLOWED + ' | Mods: $modKey' #end, WARNING);
		return null;
	}

	static function _regBitmap(key:String, hardware:Bool, file:Bool):BitmapData {
		stepAssetCompress();
		if (!file) return OpenFlAssets.getBitmapData(key, false, hardware);
		#if sys
		var newBitmap:BitmapData = BitmapData.fromFile(key);
		if (newBitmap != null) return OpenFlAssets.registerBitmapData(newBitmap, key, false, hardware);
		#end
		return null;
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(path:String, key:String, ?library:String, ?stream:Bool):Sound {
		#if MODS_ALLOWED
		var modKey:String = modsSounds(path, key), modExists:Bool = FileSystem.exists(modKey);
		var path:String = if (modExists) modKey; else getPath('$path/$key.$SOUND_EXT', SOUND, library);
		var track:String = path.substr(path.indexOf(':') + 1);
		var folder:String = './';
		#else
		var path:String = getPath('$path/$key.$SOUND_EXT', IMAGE, library), modExists:Bool = false;
		var track:String = path.substr(path.indexOf(':') + 1);
		var folder:String = '';
		if (path == 'songs') folder = 'songs:';
		#end
		var uwu:String = folder + (modExists ? path : track);

		#if (!MODS_ALLOWED) if (OpenFlAssets.exists(uwu, SOUND)) {#end
			localTrackedAssets.push(track);
			var sound:Sound = currentTrackedSounds.get(track);

			// if no stream and sound is stream, fuck it, load one that arent stream
			@:privateAccess if (!stream && sound != null && sound.__buffer != null && sound.__buffer.__srcVorbisFile != null) {
				decacheSound(track);
				sound = null;
			}
			if (sound == null) currentTrackedSounds.set(track, sound = _regSound(uwu, stream, #if MODS_ALLOWED true #else modExists #end));
			if (sound != null) return sound;
		#if (!MODS_ALLOWED) } #end

		Logs.trace('returnSound returning null: $path' #if MODS_ALLOWED + ' | $modKey' #end, WARNING);
		return null;
	}

	static function _regSound(key:String, stream:Bool, file:Bool):Sound {
		var snd:Sound = OpenFlAssets.getRawSound(key, stream, file);
		if (snd != null) stepAssetCompress();
		return snd;
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
		return modFolders('$path/$key.$SOUND_EXT');

	inline static public function modsImages(key:String)
		return modFolders('images/$key.png');

	inline static public function modsXml(key:String)
		return modFolders('images/$key.xml');

	inline static public function modsTxt(key:String)
		return modFolders('images/$key.txt');

	static public function modFolders(key:String) {
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0) {
			var file:String = mods('${Mods.currentModDirectory}/$key');
			if(FileSystem.exists(file)) return file;
		}

		for(mod in Mods.getGlobalMods()) {
			var file:String = mods('$mod/$key');
			if(FileSystem.exists(file)) return file;
		}
		return mods(key);
	}
	#end
}
