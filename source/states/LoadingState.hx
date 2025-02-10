package states;

import haxe.Json;
import haxe.Exception;
import lime.app.Future;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.utils.Assets as OpenFlAssets;
import openfl.media.Sound;
import flixel.util.typeLimit.NextState;

import backend.Song;
import data.StageData;

import sys.thread.FixedThreadPool;
import sys.thread.Mutex;

import objects.Note;
import objects.NoteSplash;

class LoadingState extends MusicBeatState {
	public static var loaded:Int = 0;
	public static var loadMax:Int = 0;

	static var originalBitmapKeys:Map<String, String> = [];
	static var requestedBitmaps:Map<String, BitmapData> = [];
	static var mutex:Mutex;
	static var threadPool:FixedThreadPool = null;

	function new(target:NextState, stopMusic:Bool) {
		this.target = target;
		this.stopMusic = stopMusic;
		super();
	}

	inline public static function loadAndSwitchState(target:NextState, stopMusic = false, intrusive:Bool = true)
		FlxG.switchState(getNextState(target, stopMusic, intrusive));

	var target:NextState = null;
	var stopMusic:Bool = false;
	var dontUpdate:Bool = false;

	var bar:FlxSprite;
	var barWidth:Int = 0;
	var intendedPercent:Float = 0;
	var curPercent:Float = 0;

	var timePassed:Float;
	var loadingText:FlxText;

	override function create() {
		#if !SHOW_LOADING_SCREEN while (true) #end {
			if (checkLoaded()) {
				dontUpdate = true;
				super.create();
				onLoad();
				return;
			}
			#if !SHOW_LOADING_SCREEN Sys.sleep(.001); #end
		}

		var bg:FlxSprite = new FlxSprite().makeSolid(FlxG.width, FlxG.height, 0xFFCAFF4D);
		bg.gameCenter();
		add(bg);

		var funkay:FlxSprite = new FlxSprite(Paths.image('funkay'));
		funkay.antialiasing = ClientPrefs.data.antialiasing;
		funkay.setGraphicSize(0, FlxG.height);
		funkay.updateHitbox();
		add(funkay);

		loadingText = new FlxText(520, 600, 450, Language.getPhrase('now_loading', 'Now Loading', ['...']), 32);
		loadingText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		loadingText.setBorderStyle(OUTLINE_FAST, FlxColor.BLACK, 2);
		loadingText.gameCenter(X);
		add(loadingText);

		var bg:FlxSprite = new FlxSprite(0, 660).makeSolid(FlxG.width - 300, 25, FlxColor.BLACK);
		bg.gameCenter(X);
		add(bg);
		
		add(bar = new FlxSprite(bg.x + 5, bg.y + 5).makeSolid(0, 15, FlxColor.WHITE));
		barWidth = Std.int(bg.width - 10);

		persistentUpdate = true;
		super.create();
	}

	var transitioning:Bool = false;
	override function update(elapsed:Float) {
		super.update(elapsed);
		if (dontUpdate) return;

		if (!transitioning) {
			if (!finishedLoading && checkLoaded()) {
				transitioning = true;
				onLoad();
				return;
			}
			intendedPercent = loaded / loadMax;
		}

		if (curPercent != intendedPercent) {
			if (Math.abs(curPercent - intendedPercent) < .001) curPercent = intendedPercent;
			else curPercent = FlxMath.lerp(intendedPercent, curPercent, Math.exp(-elapsed * 15));

			bar.scale.x = barWidth * curPercent;
			bar.updateHitbox();
		}

		timePassed += elapsed;
		var dots:String = '';
		switch(Math.floor(timePassed % 1 * 3)) {
			case 0: dots = '.';
			case 1: dots = '..';
			case 2: dots = '...';
		}
		loadingText.text = Language.getPhrase('now_loading', '({1}%) Now Loading{2}', [utils.MathUtil.floorDecimal(curPercent * 100, 2), dots]);
	}

	var finishedLoading:Bool = false;
	function onLoad() {
		_loaded();
		if (stopMusic && FlxG.sound.music != null) FlxG.sound.music.stop();

		FlxG.camera.visible = false;
		FlxG.switchState(target);
		transitioning = finishedLoading = true;
	}

	static function _loaded():Void {
		loaded = loadMax = 0;
		initialThreadCompleted = true;
		isIntrusive = false;

		MusicBeatState.skipNextTransIn = true;
		if (threadPool != null) threadPool.shutdown(); // kill all workers safely
		threadPool = null;
		mutex = null;
	}

	public static function checkLoaded():Bool {
		for (key => bitmap in requestedBitmaps) {
			if (bitmap != null && Paths.cacheBitmap(originalBitmapKeys.get(key), bitmap) != null) trace('finished preloading image $key');
			else Logs.trace('failed to cache image $key', ERROR);
		}
		requestedBitmaps.clear();
		originalBitmapKeys.clear();
		return (loaded >= loadMax && initialThreadCompleted);
	}

	public static function loadNextDirectory() {
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if (weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		Paths.setCurrentLevel(directory);
		trace('Setting asset folder to ' + directory);
	}

	static var isIntrusive:Bool = false;
	static function getNextState(target:NextState, stopMusic = false, intrusive:Bool = true):NextState {
		isIntrusive = intrusive;
		loadNextDirectory();

		if (intrusive) return () -> new LoadingState(target, stopMusic);
		if (stopMusic && FlxG.sound.music != null) FlxG.sound.music.stop();

		while (true) {
			if (checkLoaded()) {
				_loaded();
				break;
			} else Sys.sleep(.001);
		}
		return target;
	}

	static var imagesToPrepare:Array<String> = [];
	static var soundsToPrepare:Array<String> = [];
	static var musicToPrepare:Array<String> = [];
	static var songsToPrepare:Array<String> = [];
	public static function prepare(images:Array<String> = null, sounds:Array<String> = null, music:Array<String> = null) {
		if (images != null) imagesToPrepare = imagesToPrepare.concat(images);
		if (sounds != null) soundsToPrepare = soundsToPrepare.concat(sounds);
		if (music != null) musicToPrepare = musicToPrepare.concat(music);
	}

	static var initialThreadCompleted:Bool = true;
	static function _startPool() {
		threadPool = new FixedThreadPool(#if MULTITHREADED_LOADING #if cpp utils.system.PlatformUtil.getCPUThreadsCount() #else 8 #end #else 1 #end);
	}

	public static function prepareToSong() {
		_startPool();
		imagesToPrepare = [];
		soundsToPrepare = [];
		musicToPrepare = [];
		songsToPrepare = [];

		initialThreadCompleted = false;
		var threadsCompleted:Int = 0;
		var threadsMax:Int = 0;
		function completedThread() {
			threadsCompleted++;
			if (threadsCompleted == threadsMax) {
				clearInvalids();
				startThreads();
				initialThreadCompleted = true;
			}
		}

		var song:SwagSong = PlayState.SONG;
		var folder:String = Paths.formatToSongPath(Song.loadedSongName);
		new Future<Bool>(() -> {
			// LOAD NOTE IMAGE
			var noteSkin:String = Note.defaultNoteSkin;
			if (song.arrowSkin != null && song.arrowSkin.length > 1) noteSkin = song.arrowSkin;

			var customSkin:String = noteSkin + Note.getNoteSkinPostfix();
			if (Paths.fileExists('images/$customSkin.png', IMAGE)) noteSkin = customSkin;
			imagesToPrepare.push(noteSkin);

			// LOAD NOTE SPLASH IMAGE
			var noteSplash:String = NoteSplash.defaultNoteSplash;
			if (song.splashSkin != null && song.splashSkin.length > 0) noteSplash = song.arrowSkin;
			else noteSplash += NoteSplash.getSplashSkinPostfix();
			imagesToPrepare.push(noteSplash);

			try {
				var path:String = Paths.json('${Paths.CHART_PATH}/$folder/preload');
				var json:Dynamic = null;

				#if MODS_ALLOWED
				var moddyFile:String = Paths.modsJson('${Paths.CHART_PATH}/$folder/preload');
				if (FileSystem.exists(moddyFile)) json = Json.parse(File.getContent(moddyFile));
				else json = Json.parse(File.getContent(path));
				#else json = Json.parse(Assets.getText(path)); #end

				if (json != null) {
					var imgs:Array<String> = [];
					var snds:Array<String> = [];
					var mscs:Array<String> = [];
					for (asset in Reflect.fields(json)) {
						var filters:Int = Reflect.field(json, asset);
						var asset:String = asset.trim();
	
						if (filters < 0 || StageData.validateVisibility(filters)) {
							if (asset.startsWith('images/')) imgs.push(asset.substr('images/'.length));
							else if (asset.startsWith('sounds/')) snds.push(asset.substr('sounds/'.length));
							else if (asset.startsWith('music/')) mscs.push(asset.substr('music/'.length));
						}
					}
					prepare(imgs, snds, mscs);
				}
			} catch (e:Dynamic) Logs.trace("ERROR PREPARING SONG: " + e, ERROR);
			return true;
		}, isIntrusive).then((_) -> new Future<Bool>(() -> {
			if (song.stage == null || song.stage.length < 1)
				song.stage = StageData.vanillaSongStage(folder);

			var stageData:StageFile = StageData.getStageFile(song.stage);
			if (stageData != null) {
				var imgs:Array<String> = [];
				var snds:Array<String> = [];
				var mscs:Array<String> = [];
				if (stageData.preload != null) {
					for (asset in Reflect.fields(stageData.preload)) {
						var filters:Int = Reflect.field(stageData.preload, asset);
						var asset:String = asset.trim();
	
						if (filters < 0 || StageData.validateVisibility(filters)) {
							if (asset.startsWith('images/')) imgs.push(asset.substr('images/'.length));
							else if (asset.startsWith('sounds/')) snds.push(asset.substr('sounds/'.length));
							else if (asset.startsWith('music/')) mscs.push(asset.substr('music/'.length));
						}
					}
				}

				if (stageData.objects != null) {
					for (sprite in stageData.objects) {
						if (sprite.type == 'sprite' || sprite.type == 'animatedSprite')
							if ((sprite.filters < 0 || StageData.validateVisibility(sprite.filters)) && !imgs.contains(sprite.image))
								imgs.push(sprite.image);
					}
				}
				prepare(imgs, snds, mscs);
			}

			songsToPrepare.push('$folder/Inst');

			var player1:String = song.player1;
			var player2:String = song.player2;
			var gfVersion:String = song.gfVersion;
			var prefixVocals:String = song.needsVoices ? '$folder/Voices' : null;
			gfVersion ??= 'gf';

			preloadCharacter(player1);
			if (Paths.fileExists('$prefixVocals.${Paths.SOUND_EXT}', SOUND, false, 'songs')) songsToPrepare.push(prefixVocals);

			if (player2 != player1) {
				threadsMax++;
				threadPool.run(() -> {
					try {
						preloadCharacter(player2);
					} catch (e:Dynamic) Logs.trace('Error preloading player2: ' + e.details(), ERROR);
					completedThread();
				});
			}
			if (!stageData.hide_girlfriend && gfVersion != player2 && gfVersion != player1) {
				threadsMax++;
				threadPool.run(() -> {
					try {
						preloadCharacter(gfVersion);
					} catch (e:Dynamic) Logs.trace('Error preloading gf: ' + e.details(), ERROR);
					completedThread();
				});
			}

			if (threadsCompleted == threadsMax) {
				clearInvalids();
				startThreads();
				initialThreadCompleted = true;
			}
			return true;
		}, isIntrusive)).onError((err:Dynamic) -> Logs.trace('ERROR! while preparing song: $err', ERROR));
	}

	public static function clearInvalids() {
		clearInvalidFrom(imagesToPrepare, 'images', '.png', IMAGE);
		clearInvalidFrom(soundsToPrepare, 'sounds', '.${Paths.SOUND_EXT}', SOUND);
		clearInvalidFrom(musicToPrepare, 'music', ' .${Paths.SOUND_EXT}', SOUND);
		clearInvalidFrom(songsToPrepare, 'songs', '.${Paths.SOUND_EXT}', SOUND, 'songs');

		for (arr in [imagesToPrepare, soundsToPrepare, musicToPrepare, songsToPrepare])
			while (arr.contains(null)) arr.remove(null);
	}

	static function clearInvalidFrom(arr:Array<String>, prefix:String, ext:String, type:openfl.utils.AssetType, ?parentFolder:String = null) {
		for (folder in arr.copy()) {
			var nam:String = folder.trim();
			if (nam.endsWith('/')) {
				for (subfolder in Mods.directoriesWithFile(Paths.getSharedPath(), '$prefix/$nam')) {
					for (file in FileSystem.readDirectory(subfolder)) {
						if (file.endsWith(ext)) {
							var toAdd:String = nam + haxe.io.Path.withoutExtension(file);
							if (!arr.contains(toAdd)) arr.push(toAdd);
						}
					}
				}
			}
		}

		var i:Int = 0;
		while (i < arr.length) {
			var member:String = arr[i];
			var myKey:String = '$prefix/$member$ext';
			if (parentFolder == 'songs') myKey = '$member$ext';

			var doTrace:Bool = false;
			if (member.endsWith('/') || (!Paths.fileExists(myKey, type, false, parentFolder) && (doTrace = true))) {
				arr.remove(member);
				if (doTrace) trace('Removed invalid $prefix: $member');
			} else i++;
		}
	}

	public static function startThreads() {
		mutex = new Mutex();
		loadMax = imagesToPrepare.length + soundsToPrepare.length + musicToPrepare.length + songsToPrepare.length;
		loaded = 0;

		// then start threads
		_threadFunc();
	}
	static function _threadFunc() {
		_startPool();
		for (sound in soundsToPrepare) initThread(() -> preloadSound('sounds/$sound'), 'sound $sound');
		for (music in musicToPrepare) initThread(() -> preloadSound('music/$music'), 'music $music');
		for (song in songsToPrepare) initThread(() -> preloadSound(song, 'songs', true, false), 'song $song');

		// for images, they get to have their own thread
		for (image in imagesToPrepare) initThread(() -> preloadGraphic(image), 'image $image');
	}

	static function initThread(func:Void->Dynamic, traceData:String) {
		#if debug var threadSchedule:Float = Sys.time(); #end
		threadPool.run(() -> {
			#if debug
			var threadStart:Float = Sys.time();
			trace('$traceData took ${threadStart - threadSchedule}s to start preloading');
			#end

			try {
				if (func() != null) {
					#if debug
					var diff:Float = Sys.time() - threadStart;
					trace('finished preloading $traceData in ${diff}s');
					#end
				} else Logs.trace('ERROR! fail on preloading $traceData', ERROR);
			} catch(e:Dynamic) Logs.trace('ERROR! fail on preloading $traceData', ERROR);
			loaded++;
		});
	}

	inline static function preloadCharacter(char:String) {
		try {
			var character:Dynamic = Json.parse(#if MODS_ALLOWED File.getContent #else Assets.getText #end(Paths.getPath('characters/$char.json')));

			var isAnimateAtlas:Bool = false;
			var img:String = character.image;
			img = img.trim();
			#if flxanimate
			var animToFind:String = Paths.getPath('images/$img/Animation.json');
			if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
				isAnimateAtlas = true;
			#end

			if (!isAnimateAtlas) {
				var split:Array<String> = img.split(',');
				for (file in split) imagesToPrepare.push(file.trim());
			}
			#if flxanimate
			else {
				for (i in 0...10) {
					var st:String = '$i';
					if (i == 0) st = '';

					if (Paths.fileExists('images/$img/spritemap$st.png', IMAGE)) {
						imagesToPrepare.push('$img/spritemap$st');
						break;
					}
				}
			}
			#end
		} catch (e:Exception) Logs.trace("ERROR PRELOADING CHARACTER: " + e.details(), ERROR);
	}

	// thread safe sound loader
	static function preloadSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true):Null<Sound> {
		var file:String = Paths.getPath(Language.getFileTranslation(key) + '.${Paths.SOUND_EXT}', SOUND, path, modsAllowed);

		if (!Paths.currentTrackedSounds.exists(file)) {
			if (#if sys FileSystem.exists(file) || #end OpenFlAssets.exists(file, SOUND)) {
				var sound:Sound = #if sys Sound.fromFile(file) #else OpenFlAssets.getSound(file, false) #end;
				mutex.acquire();
				Paths.currentTrackedSounds.set(file, sound);
				mutex.release();
			} else if (beepOnNull) {
				FlxG.log.error('SOUND NOT FOUND: $key, PATH: $path');
				return flixel.system.FlxAssets.getSoundAddExtension('flixel/sounds/beep');
			}
		}
		mutex.acquire();
		Paths.localTrackedAssets.push(file);
		mutex.release();

		return Paths.currentTrackedSounds.get(file);
	}

	// thread safe sound loader
	static function preloadGraphic(key:String):Null<BitmapData> {
		try {
			var requestKey:String = 'images/$key';
			#if TRANSLATIONS_ALLOWED requestKey = Language.getFileTranslation(requestKey); #end
			if (requestKey.lastIndexOf('.') < 0) requestKey += '.png';

			if (!Paths.currentTrackedAssets.exists(requestKey)) {
				var file:String = Paths.getPath(requestKey, IMAGE);
				if (#if sys FileSystem.exists(file) || #end OpenFlAssets.exists(file, IMAGE)) {
					var bitmap:BitmapData = #if sys BitmapData.fromFile(file) #else OpenFlAssets.getBitmapData(file, false) #end;
					mutex.acquire();
					requestedBitmaps.set(file, bitmap);
					originalBitmapKeys.set(file, requestKey);
					mutex.release();
					return bitmap;
				} else Logs.trace('no such image $key exists', WARNING);
			}
			return Paths.currentTrackedAssets.get(requestKey).bitmap;
		} catch (e:Exception) Logs.trace('fail on preloading image $key', ERROR);

		return null;
	}
}