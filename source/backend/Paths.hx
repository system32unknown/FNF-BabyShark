package backend;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.display.BitmapData;
import openfl.media.Sound;
import lime.utils.Assets;

@:access(openfl.display.BitmapData.__texture)
@:access(openfl.media.Sound.__buffer)
class Paths {
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
		'assets/shared/music/freakyMenu.$SOUND_EXT',
	];

	public static function decacheSound(key:String) {
		var obj = currentTrackedSounds.get(key);
		currentTrackedSounds.remove(key);

		if (obj == null && OpenFlAssets.cache.hasSound(key)) obj = OpenFlAssets.cache.getSound(key);
		if (obj == null || assetExcluded(obj)) return;

		OpenFlAssets.cache.removeSound(key);
		Assets.cache.clear(key);
		
		obj.close();
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

		#if cpp utils.system.MemoryUtil.clearMajor #else openfl.system.System.gc #end();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];
	public static function clearStoredCache() {
		for (key in @:privateAccess FlxG.bitmap._cache.keys()) {
			if (key != null && !currentTrackedAssets.exists(key) && !assetExcluded(key))
				decacheGraphic(key);
		}

		for (key => asset in currentTrackedSounds) {
			if (!localTrackedAssets.contains(key) && !assetExcluded(key) && asset != null)
				decacheSound(key);
		}

		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		OpenFlAssets.cache.clear("songs");
		utils.system.MemoryUtil.clearMajor();
		clearUnusedCache();
	}

	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();

	public static function getPath(file:String, ?type:AssetType = TEXT, ?parentfolder:Null<String> = null, ?modsAllowed:Bool = true):String {
		#if MODS_ALLOWED
		if(modsAllowed) {
			var customFile:String = file;
			if (parentfolder != null) customFile = '$parentfolder/$file';

			var modded:String = modFolders(customFile);
			if(FileSystem.exists(modded)) return modded;
		}
		#end

		if (parentfolder != null) return getFolderPath(file, parentfolder);

		if (currentLevel != null && currentLevel != 'shared') {
			var levelPath:String = getFolderPath(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type)) return levelPath;
		}

		return getSharedPath(file);
	}

	inline static public function getFolderPath(file:String, folder = "shared") return 'assets/$folder/$file';
	inline public static function getSharedPath(file:String = '') return 'assets/shared/$file';

	public static inline function ndll(key:String, ?folder:String)
		return getPath('data/ndlls/$key.ndll', folder);
	inline static public function txt(key:String, ?folder:String)
		return getPath('data/$key.txt', TEXT, folder);
	inline static public function json(key:String, ?folder:String)
		return getPath('data/$key.json', TEXT, folder);

	static public function video(key:String) {
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if (FileSystem.exists(file)) return file;
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	inline static public function sound(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('sounds/$key', modsAllowed);
	inline static public function music(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('music/$key', modsAllowed);
	inline static public function soundRandom(key:String, min:Int, max:Int, ?modsAllowed:Bool = true):Sound
		return sound(key + FlxG.random.int(min, max), modsAllowed);

	inline static public function inst(song:String, ?modsAllowed:Bool = true):Sound
		return returnSound('${formatToSongPath(song)}/Inst', 'songs', modsAllowed);
	inline static public function voices(song:String, postfix:String = null, ?modsAllowed:Bool = true):Sound
		return returnSound('${formatToSongPath(song)}/Voices', 'songs', modsAllowed, false);

	static public function image(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxGraphic {
		key = Language.getFileTranslation('images/$key');
		if(key.lastIndexOf('.') < 0) key += '.png';

		var bitmap:BitmapData = null;
		if (currentTrackedAssets.exists(key)) {
			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}
		return cacheBitmap(key, parentFolder, bitmap, allowGPU);
	}

	inline static public function getTextFromFile(key:String, ?absolute:Bool = false):String {
		if (absolute) {
			#if sys
			if (FileSystem.exists(key)) return File.getContent(key); #end
			if (OpenFlAssets.exists(key, TEXT)) return Assets.getText(key);
			return null;
		}

		var path:String = getPath(key, TEXT, true);
		return (#if sys FileSystem.exists(path)) ? File.getContent(path) #else OpenFlAssets.exists(path, TEXT)) ? Assets.getText(path) #end : null;
	}

	inline static public function font(key:String):String {
		#if MODS_ALLOWED
		var file:String = modsFont(key);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/fonts/$key';
	}

	static public function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?parentFolder:String):Bool {
		#if MODS_ALLOWED
		if(!ignoreMods) {
			var modKey:String = key;
			if(parentFolder == 'songs') modKey = 'songs/$key';

			for(mod in Mods.getGlobalMods()) if (FileSystem.exists(mods('$mod/$modKey'))) return true;
			if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + modKey)) || FileSystem.exists(mods(modKey)))
				return true;
		}
		#end
		return OpenFlAssets.exists(getPath(key, type, parentFolder, false));
	}

	static public function getAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames {
		var useMod = false;
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);

		var myXml:Dynamic = getPath('images/$key.xml', TEXT, parentFolder);
		if(OpenFlAssets.exists(myXml) #if MODS_ALLOWED || (FileSystem.exists(myXml) && (useMod = true)) #end)
			return FlxAtlasFrames.fromSparrow(imageLoaded, #if MODS_ALLOWED (useMod ? File.getContent(myXml) : myXml) #else myXml #end);
		else {
			var myJson:Dynamic = getPath('images/$key.json', TEXT, parentFolder);
			if(OpenFlAssets.exists(myJson) #if MODS_ALLOWED || (FileSystem.exists(myJson) && (useMod = true)) #end )
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, #if MODS_ALLOWED (useMod ? File.getContent(myJson) : myJson) #else myJson #end);
		}
		return getPackerAtlas(key, parentFolder);
	}

	inline static public function getSparrowAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames {
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		var xmlExists:Bool = false;

		var xml:String = modsXml(key);
		if(FileSystem.exists(xml)) xmlExists = true;

		return FlxAtlasFrames.fromSparrow(imageLoaded, (xmlExists ? File.getContent(xml) : getPath('images/$key.xml', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromSparrow(imageLoaded, getPath('images/$key.xml', TEXT, parentFolder));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames {
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		var txtExists:Bool = false;
		
		var txt:String = modsTxt(key);
		if(FileSystem.exists(txt)) txtExists = true;

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, (txtExists ? File.getContent(txt) : getPath('images/$key.txt', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, getPath('images/$key.txt', TEXT, parentFolder));
		#end
	}

	inline static public function getAsepriteAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames {
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		var jsonExists:Bool = false;

		var json:String = modsImagesJson(key);
		if(FileSystem.exists(json)) jsonExists = true;

		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (jsonExists ? File.getContent(json) : getPath('images/$key.json', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, getPath('images/$key.json', TEXT, parentFolder));
		#end
	}

	inline static public function formatToSongPath(path:String) {
		var invalidChars:EReg = ~/[~&\\;:<>#]+/g;
		var hideChars:EReg = ~/[.,'"%?!]+/g;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static function cacheBitmap(key:String, ?parentFolder:String = null, ?bitmap:BitmapData, ?allowGPU:Bool = true) {
		var file:String = getPath(key, IMAGE, parentFolder);
		if (bitmap == null) {
			#if MODS_ALLOWED
			if (FileSystem.exists(file)) bitmap = BitmapData.fromFile(file);
			#else
			if (OpenFlAssets.exists(file, IMAGE)) bitmap = OpenFlAssets.getBitmapData(file);
			#end

			if(bitmap == null) {
				FlxG.log.warn('Could not find image with key: "$key"' + (parentFolder == null ? "" : 'in parent folder: "$parentFolder"'));
				return null;
			}
		}

		if (allowGPU && ClientPrefs.data.cacheOnGPU && bitmap.image != null) @:privateAccess {
			bitmap.lock();
			if (bitmap.__texture == null) {
				bitmap.image.premultiplied = true;
				bitmap.getTexture(FlxG.stage.context3D);
			}
			bitmap.getSurface();
			bitmap.disposeImage();
			bitmap.image.data = null;
			bitmap.image = null;
			bitmap.readable = true;
		}

		var graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
		graph.persist = true;
		graph.destroyOnNoUse = false;

		currentTrackedAssets.set(key, graph);
		localTrackedAssets.push(key);
		return graph;
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true) {
		var file:String = getPath(Language.getFileTranslation(key) + '.$SOUND_EXT', SOUND, path, modsAllowed);
		if(!currentTrackedSounds.exists(file)) {
			#if sys
			if(FileSystem.exists(file)) currentTrackedSounds.set(file, Sound.fromFile(file));
			#else
			if(OpenFlAssets.exists(file, SOUND)) currentTrackedSounds.set(file, OpenFlAssets.getSound(file));
			#end
			else if(beepOnNull) {
				FlxG.log.error('SOUND NOT FOUND: $key, PATH: $path');
				return FlxAssets.getSound('flixel/sounds/beep');
			}
		}
		localTrackedAssets.push(file);
		return currentTrackedSounds.get(file);
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

	inline static public function modsImagesJson(key:String)
		return modFolders('images/$key.json');

	inline static public function modsNdll(key:String)
		return modFolders('data/ndlls/$key.ndll');

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

	#if flxanimate
	public static function loadAnimateAtlas(spr:FlxAnimate, folderOrImg:Dynamic, spriteJson:Dynamic = null, animationJson:Dynamic = null) {
		var changedAnimJson:Bool = false;
		var changedAtlasJson:Bool = false;
		var changedImage:Bool = false;

		if(spriteJson != null) {
			changedAtlasJson = true;
			spriteJson = File.getContent(spriteJson);
		}

		if(animationJson != null) {
			changedAnimJson = true;
			animationJson = File.getContent(animationJson);
		}

		// is folder or image path
		if(Std.isOfType(folderOrImg, String)) {
			var originalPath:String = folderOrImg;
			for (i in 0...10) {
				var st:String = '$i';
				if(i == 0) st = '';

				if(!changedAtlasJson) {
					spriteJson = getTextFromFile('images/$originalPath/spritemap$st.json');
					if(spriteJson != null) {
						changedImage = true;
						changedAtlasJson = true;
						folderOrImg = image('$originalPath/spritemap$st');
						break;
					}
				} else if(fileExists('images/$originalPath/spritemap$st.png', IMAGE)) {
					changedImage = true;
					folderOrImg = image('$originalPath/spritemap$st');
					break;
				}
			}

			if(!changedImage) {
				changedImage = true;
				folderOrImg = image(originalPath);
			}

			if(!changedAnimJson) {
				changedAnimJson = true;
				animationJson = getTextFromFile('images/$originalPath/Animation.json');
			}
		}
		spr.loadAtlasEx(folderOrImg, spriteJson, animationJson);
	}
	#end

	inline static public function exists(key:String)
		return FileSystem.exists(modFolders(key)) || FileSystem.exists(getSharedPath(key));
}
