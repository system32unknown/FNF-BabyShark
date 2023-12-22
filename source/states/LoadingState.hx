package states;

import lime.app.Promise;
import lime.app.Future;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;

import flixel.FlxState;

import openfl.utils.Assets;
import haxe.io.Path;
import data.StageData;

class LoadingState extends MusicBeatState {
	inline static final MIN_TIME = 1.0;

	// Browsers will load create(), you can make your song load a custom directory there
	// If you're compiling to desktop (or something that doesn't use NO_PRELOAD_ALL), search for getNextState instead
	// I'd recommend doing it on both actually lol
	
	// TO DO: Make this easier
	
	var target:FlxState;
	var stopMusic = false;
	var directory:String;
	var callbacks:MultiCallback;
	var targetShit:Float = 0;

	function new(target:FlxState, stopMusic:Bool, directory:String) {
		super();
		this.target = target;
		this.stopMusic = stopMusic;
		this.directory = directory;
	}

	var loadBar:FlxSprite;
	var loadBarBack:FlxSprite;
	var loadText:FlxText;

	var logo:FlxSprite;
	var loadLogoText:FlxText;
	override function create() {
		var bg:FlxSprite = new FlxSprite(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = FlxColor.fromRGB(FlxG.random.int(0, 255), FlxG.random.int(0, 255), FlxG.random.int(0, 255));
		add(bg);

		var funkay = new FlxSprite(Paths.getPath('images/funkay.png', IMAGE));
		funkay.setGraphicSize(0, FlxG.height);
		funkay.updateHitbox();
		add(funkay);
		funkay.antialiasing = ClientPrefs.getPref('Antialiasing');
		funkay.scrollFactor.set();
		funkay.screenCenter(X);

		logo = new FlxSprite(Paths.getPath('images/logobumpin.png', IMAGE));
		logo.screenCenter();
		logo.antialiasing = ClientPrefs.getPref('Antialiasing');
		add(logo);

		loadLogoText = new FlxText(0, logo.y - logo.height, 0, 'LOADING', 30);
		loadLogoText.setFormat(null, 30, FlxColor.WHITE, FlxTextAlign.CENTER);
		loadLogoText.setBorderStyle(SHADOW, FlxColor.GRAY, 2);
		loadLogoText.screenCenter(X);
		add(loadLogoText);

		loadBarBack = new FlxSprite(0, FlxG.height - 25).makeGraphic(FlxG.width, 20, FlxColor.BLACK);
		loadBarBack.scale.x = .50;
		loadBarBack.screenCenter(X);
		loadBarBack.antialiasing = ClientPrefs.getPref('Antialiasing');
		add(loadBarBack);

		loadBar = new FlxSprite(0, FlxG.height - 20).makeGraphic(FlxG.width, 10, 0xffff16d2);
		loadBar.screenCenter(X);
		loadBar.antialiasing = ClientPrefs.getPref('Antialiasing');
		add(loadBar);

		loadText = new FlxText(0, loadBarBack.y - 24, 0, '0%', 16);
		loadText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, FlxTextAlign.CENTER);
		loadText.setBorderStyle(OUTLINE, FlxColor.BLACK);
		loadText.screenCenter(X);
		add(loadText);
		
		initSongsManifest().onComplete(function(lib) {
			callbacks = new MultiCallback(onLoad);
			var introComplete = callbacks.add("introComplete");
			checkLibrary("shared");
			if(directory != null && directory.length > 0 && directory != 'shared')
				checkLibrary('week_assets');
			var fadeTime = .5;
			FlxG.camera.fade(FlxG.camera.bgColor, fadeTime, true);
			new FlxTimer().start(fadeTime + MIN_TIME, (_) -> introComplete());
		});
	}
	function checkLibrary(library:String) {
		if (Assets.getLibrary(library) == null) {
			@:privateAccess
			if (!LimeAssets.libraryPaths.exists(library))
				throw new haxe.Exception("Missing library: " + library);

			var callback = callbacks.add('library:$library');
			Assets.loadLibrary(library).onComplete((_) -> callback());
		}
	}
	
	override function update(elapsed:Float) {
		super.update(elapsed);

		if(callbacks != null) {
			targetShit = FlxMath.remapToRange(callbacks.numRemaining / callbacks.length, 1, 0, 0, 1);
			loadText.text = 'Loading... (${callbacks.numRemaining} / ${callbacks.length}) [Next State: ${Type.getClass(target)}]';
			loadText.screenCenter(X);
			loadBar.scale.x += 0.5 * (targetShit - loadBar.scale.x);
		}

		loadLogoText.y = logo.y - logo.height;
	}
	
	function onLoad() {
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();
		
		MusicBeatState.switchState(target);
	}

	static function getSongPath() return Paths.inst(PlayState.SONG.song);
	static function getVocalPath() return Paths.voices(PlayState.SONG.song);

	inline static public function loadAndSwitchState(target:FlxState, stopMusic = false) {
		MusicBeatState.switchState(getNextState(target, stopMusic));
	}
	
	static function getNextState(target:FlxState, stopMusic = false):FlxState {
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		Paths.setCurrentLevel(directory);

		#if NO_PRELOAD_ALL
		var loaded:Bool = false;
		if (PlayState.SONG != null)
			loaded = isSoundLoaded(getSongPath()) && (!PlayState.SONG.needsVoices || isSoundLoaded(getVocalPath())) && isLibraryLoaded("shared") && checkLibrary('week_assets');

		if (!loaded) return new LoadingState(target, stopMusic, directory);
		#end

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();
		
		return target;
	}

	static function isSoundLoaded(path:String):Bool return Assets.cache.hasSound(path);
	static function isLibraryLoaded(library:String):Bool return Assets.getLibrary(library) != null;

	override function destroy() {
		super.destroy();
		callbacks = null;
	}
	
	static function initSongsManifest() {
		var id = "songs";
		var promise = new Promise<AssetLibrary>();

		var library = LimeAssets.getLibrary(id);

		if (library != null)
			return Future.withValue(library);

		var path = id;
		var rootPath = null;

		@:privateAccess
		var libraryPaths = LimeAssets.libraryPaths;
		if (libraryPaths.exists(id)) {
			path = libraryPaths[id];
			rootPath = Path.directory(path);
		} else {
			if (path.endsWith(".bundle")) {
				rootPath = path;
				path += "/library.json";
			} else rootPath = Path.directory(path);
			@:privateAccess
			path = LimeAssets.__cacheBreak(path);
		}

		AssetManifest.loadFromFile(path, rootPath).onComplete(function(manifest) {
			if (manifest == null) {
				promise.error("Cannot parse asset manifest for library \"" + id + "\"");
				return;
			}

			var library = AssetLibrary.fromManifest(manifest);
			if (library == null)
				promise.error("Cannot open library \"" + id + "\"");
			else {
				@:privateAccess
				LimeAssets.libraries.set(id, library);
				library.onChange.add(LimeAssets.onChange.dispatch);
				promise.completeWith(Future.withValue(library));
			}
		}).onError((_) -> promise.error("There is no asset library with an ID of \"" + id + "\""));

		return promise.future;
	}
}

class MultiCallback
{
	public var callback:Void->Void;
	public var logId:String = null;
	public var length(default, null) = 0;
	public var numRemaining(default, null) = 0;
	
	var unfired = new Map<String, Void->Void>();
	var fired = new Array<String>();
	
	public function new(callback:Void->Void, logId:String = null) {
		this.callback = callback;
		this.logId = logId;
	}
	
	public function add(id = "untitled")
	{
		id = '$length:$id';
		length++;
		numRemaining++;
		var func:Void -> Void = null;
		func = () -> {
			if (unfired.exists(id)) {
				unfired.remove(id);
				fired.push(id);
				numRemaining--;
				
				if (logId != null) log('fired $id, $numRemaining remaining');
				if (numRemaining == 0) {
					if (logId != null) log('all callbacks fired');
					callback();
				}
			} else log('already fired $id');
		}
		unfired[id] = func;
		return func;
	}
	
	inline function log(msg):Void {
		if (logId != null) Logs.trace('$logId: $msg');
	}
}