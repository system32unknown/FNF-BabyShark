package backend;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.FlxGraphic;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.display.BitmapData;
import openfl.media.Sound;
import lime.utils.Assets;
import utils.system.MemoryUtil;

@:access(openfl.display.BitmapData)
class Paths {
	inline public static final CHART_PATH = "charts";
	inline public static final SOUND_EXT = "ogg";
	inline public static final VIDEO_EXT = "mp4";

	public static var popUpFramesMap:Map<String, FlxFramesCollection> = new Map<String, FlxFramesCollection>();

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key)) dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = ['assets/shared/music/freakyMenu.$SOUND_EXT',];

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var localTrackedAssets:Array<String> = [];

	// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory() {
		for (key => asset in currentTrackedAssets) {
			if (localTrackedAssets.contains(key) || dumpExclusions.contains(key)) continue;	
			destroyGraphic(asset); // get rid of the graphic
			currentTrackedAssets.remove(key); // and remove the key from local cache map
		}
		if (ClientPrefs.data.disableGC) {
			MemoryUtil.enable();
			MemoryUtil.collect(true);
			if ((cast FlxG.state) is PlayState) MemoryUtil.enable(false);
		} else MemoryUtil.clearMajor();
	}

	@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
	public static function clearStoredMemory() {
		for (key in FlxG.bitmap._cache.keys())
			if (!currentTrackedAssets.exists(key))
				destroyGraphic(FlxG.bitmap.get(key));

		for (key => asset in currentTrackedSounds) {
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null) {
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}

		localTrackedAssets = [];
		OpenFlAssets.cache.clear("songs");
		if (!ClientPrefs.data.disableGC) MemoryUtil.clearMajor();
	}

	inline static function destroyGraphic(graphic:FlxGraphic) {
		// free some gpu memory
		if (graphic != null && graphic.bitmap != null && graphic.bitmap.__texture != null)
			graphic.bitmap.__texture.dispose();
		FlxG.bitmap.remove(graphic);
	}

	public static var currentLevel:String;
	public static function setCurrentLevel(name:String)
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

	inline public static function getFolderPath(file:String, folder = "shared"):String
		return 'assets/$folder/$file';

	inline public static function getSharedPath(file:String = ''):String
		return 'assets/shared/$file';

	inline public static function txt(key:String, ?folder:String):String
		return getPath('data/$key.txt', TEXT, folder);
	inline public static function json(key:String, ?folder:String):String
		return getPath('data/$key.json', TEXT, folder);

	public static function video(key:String):String {
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	inline public static function sound(key:String, ?modsAllowed:Bool = true, ?playBeep: Bool = true):Sound
		return returnSound('sounds/$key', null, modsAllowed, playBeep);

	inline public static function music(key:String, ?modsAllowed:Bool = true, ?playBeep: Bool = true):Sound
		return returnSound('music/$key', null, modsAllowed, playBeep);

	inline public static function inst(song:String, ?modsAllowed:Bool = true):Sound
		return returnSound('${formatToSongPath(song)}/Inst', 'songs', modsAllowed);

	inline public static function voices(song:String, ?modsAllowed:Bool = true):Sound
		return returnSound('${formatToSongPath(song)}/Voices', 'songs', modsAllowed, false);
	inline public static function soundRandom(key:String, min:Int, max:Int, ?modsAllowed:Bool = true):Sound
		return sound(key + FlxG.random.int(min, max), modsAllowed);

	public static function image(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxGraphic {
		key = Language.getFileTranslation('images/$key') + '.png';

		var bitmap:BitmapData = null;
		if (currentTrackedAssets.exists(key)) {
			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}
		return cacheBitmap(key, parentFolder, bitmap, allowGPU);
	}

	public static function cacheBitmap(key:String, ?parentFolder:String = null, ?bitmap:BitmapData, ?allowGPU:Bool = true):FlxGraphic {
		if (bitmap == null) {
			var file:String = getPath(key, IMAGE, parentFolder);
			#if MODS_ALLOWED
			if (FileSystem.exists(file)) bitmap = BitmapData.fromFile(file);
			else #end if (OpenFlAssets.exists(file, IMAGE)) bitmap = OpenFlAssets.getBitmapData(file);

			if (bitmap == null) {
				FlxG.log.warn('Could not find image with key: "$key"' + (parentFolder == null ? "" : 'in parent folder: "$parentFolder"'));
				return null;
			}
		}

		if (allowGPU && ClientPrefs.data.cacheOnGPU && bitmap.image != null) {
			@:privateAccess
			if (bitmap.__texture == null) {
				bitmap.image.premultiplied = true;
				bitmap.getTexture(FlxG.stage.context3D);
			}

			bitmap.getSurface();
			bitmap.disposeImage();
			bitmap.image.data = null;
			@:privateAccess {
				bitmap.image = null;
				bitmap.readable = true;
			}
		}

		final graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
		graph.persist = true;
		graph.destroyOnNoUse = false;

		currentTrackedAssets.set(key, graph);
		localTrackedAssets.push(key);
		return graph;
	}

	inline public static function getTextFromFile(key:String, ?ignoreMods:Bool = false):String {
		var path:String = getPath(key, TEXT, !ignoreMods);
		return (#if sys FileSystem.exists(path)) ? File.getContent(path) #else OpenFlAssets.exists(path, TEXT)) ? Assets.getText(path) #end : null;
	}

	inline public static function font(key:String):String {
		var folderKey:String = Language.getFileTranslation('fonts/$key');
		#if MODS_ALLOWED
		var file:String = modFolders(folderKey);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/$folderKey';
	}

	public static function fileExists(key:String, ?type:AssetType = TEXT, ?ignoreMods:Bool = false, ?parentFolder:String = null):Bool {
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

	public static function getAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames {
		var useMod:Bool = false;
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

	public static function getMultiAtlas(keys:Array<String>, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames {
		var parentFrames:FlxAtlasFrames = cast getAtlas(keys[0].trim());
		if (keys.length < 1) return parentFrames;

		var original:FlxAtlasFrames = parentFrames;
		parentFrames = new FlxAtlasFrames(parentFrames.parent);
		parentFrames.addAtlas(original, true);
		for (i in 1...keys.length) {
			var extraFrames:FlxAtlasFrames = cast getAtlas(keys[i].trim(), parentFolder, allowGPU);
			if (extraFrames != null) parentFrames.addAtlas(extraFrames, true);
		}

		return parentFrames;
	}

	inline public static function getSparrowAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames {
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		var xmlExists:Bool = false;

		var xml:String = modsXml(key);
		if(FileSystem.exists(xml)) xmlExists = true;

		return FlxAtlasFrames.fromSparrow(imageLoaded, (xmlExists ? File.getContent(xml) : getPath(Language.getFileTranslation('images/$key') + '.xml', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromSparrow(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.xml', TEXT, parentFolder));
		#end
	}

	inline public static function getPackerAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames {
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		var txtExists:Bool = false;
		
		var txt:String = modsTxt(key);
		if(FileSystem.exists(txt)) txtExists = true;

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, (txtExists ? File.getContent(txt) : getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentFolder));
		#end
	}

	inline public static function getAsepriteAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames {
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		var jsonExists:Bool = false;

		var json:String = modsImagesJson(key);
		if(FileSystem.exists(json)) jsonExists = true;

		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (jsonExists ? File.getContent(json) : getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentFolder));
		#end
	}

	inline public static function formatToSongPath(path:String):String {
		final invalidChars:EReg = ~/[~&;:<>#\s]/g;
		final hideChars:EReg = ~/[.,'"%?!]/g;

		return hideChars.replace(invalidChars.replace(path, '-'), '').trim().toLowerCase();
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true):Sound {
		var file:String = getPath(Language.getFileTranslation(key) + '.$SOUND_EXT', SOUND, path, modsAllowed);
		
		if(!currentTrackedSounds.exists(file)) {
			var snd:Sound = #if sys Sound.fromFile #else OpenFlAssets.getSound #end(file);
			if(#if sys FileSystem.exists(file) #else OpenFlAssets.exists(file, SOUND) #end) currentTrackedSounds.set(file, snd);
			else if(beepOnNull) {
				FlxG.log.error('SOUND NOT FOUND: $key, PATH: $path');
				return flixel.system.FlxAssets.getSound('flixel/sounds/beep');
			}
		}
		localTrackedAssets.push(file);
		return currentTrackedSounds.get(file);
	}

	#if MODS_ALLOWED
	inline public static function mods(key:String = ''):String
		return 'mods/$key';
	inline public static function modsJson(key:String):String
		return modFolders('data/$key.json');
	inline public static function modsVideo(key:String):String
		return modFolders('videos/$key.$VIDEO_EXT');
	inline public static function modsImages(key:String):String
		return modFolders('images/$key.png');
	inline public static function modsXml(key:String):String
		return modFolders('images/$key.xml');
	inline public static function modsTxt(key:String):String
		return modFolders('images/$key.txt');
	inline public static function modsImagesJson(key:String):String
		return modFolders('images/$key.json');

	public static function modFolders(key:String):String {
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0) {
			var file:String = mods('${Mods.currentModDirectory}/$key');
			if(FileSystem.exists(file)) return file;
			#if linux
			else {
				var newPath:String = findFile(key);
				if (newPath != null) return newPath;
			}
			#end
		}

		for(mod in Mods.getGlobalMods()) {
			var file:String = mods('$mod/$key');
			if(FileSystem.exists(file)) return file;
			#if linux
			else {
				var newPath:String = findFile(key);
				if (newPath != null) return newPath;
			}
			#end
		}
		return mods(key);
	}

	#if linux
	static function findFile(key:String):String { // used above ^^^^
		var targetDir:Array<String> = key.replace('\\','/').split('/');
		var searchDir:String = mods(Mods.currentModDirectory + '/' + targetDir[0]);
		targetDir.remove(targetDir[0]);
		for (x in targetDir) {
			if(x == '') continue;
			var newPart:String = findNode(searchDir, x);
			if (newPart != null) {
				searchDir += '/$newPart';
			} else return null;
		}
		return searchDir;
	}
	static function findNode(dir:String, key:String):String {
		var allFiles:Array<String> = null;
		try {
			allFiles = FileSystem.readDirectory(dir);
		} catch (e) return null;

		var allSearchies:Array<String> = allFiles.map(s -> s.toLowerCase());
		for (i => name in allSearchies) {
			if (key.toLowerCase() == name) return allFiles[i];
		}
		return null;
	}
	#end // linux
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

	public static function exists(file:String, ?type:AssetType = TEXT, ?parentFolder:String, ?modsAllowed:Bool = true):Bool {
		return #if MODS_ALLOWED FileSystem #else Assets #end.exists(getPath(file, type, parentFolder, modsAllowed));
	}
}