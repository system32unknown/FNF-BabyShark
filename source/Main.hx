package;

import openfl.display.Sprite;
import flixel.input.keyboard.FlxKey;
import utils.system.MemoryUtil;
import utils.GameVersion;
import debug.FPSCounter;

#if desktop
import backend.ALSoftConfig; // Just to make sure DCE doesn't remove this, since it's not directly referenced anywhere else.
#end

class Main extends Sprite {
	public static var engineVer:GameVersion = new GameVersion(0, 1, 5);

	public static var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: states.TitleState, // initial game state
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var fpsVar:FPSCounter;

	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public function new() {
		super();
		#if windows @:functionCode('#include <windows.h> SetProcessDPIAware();') #end
		setupGame();
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0") ['--no-lua'] #end);
	}

	function setupGame():Void {
		debug.Logs.init();

		addChild(new backend.FunkinGame(game.width, game.height, () -> new Init(), game.framerate, game.framerate, game.skipSplash, game.startFullscreen));
		addChild(fpsVar = new FPSCounter());
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.data.showFPS;
			fpsVar.memType = ClientPrefs.data.memCounterType;
		}

		#if CRASH_HANDLER debug.CrashHandler.init(); #end
		#if DISCORD_ALLOWED DiscordClient.prepare(); #end

		FlxG.signals.preStateSwitch.add(() -> Paths.clearStoredMemory());
		FlxG.signals.postStateSwitch.add(() -> {
			Paths.clearUnusedMemory();
			MemoryUtil.clearMajor();
			MemoryUtil.clearMajor(true);
			MemoryUtil.clearMajor();
		});
		FlxG.signals.gameResized.add((w, h) -> {
			if (FlxG.cameras != null) for (cam in FlxG.cameras.list) {
				if (cam != null && cam.filters != null) resetSpriteCache(cam.flashSprite);
			}
			if (FlxG.game != null) resetSpriteCache(FlxG.game);
			@:privateAccess FlxG.game.soundTray._defaultScale = (w / FlxG.width) * 2;
		});
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		if (sprite == null) return;
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = sprite.__cacheBitmapData2 = sprite.__cacheBitmapData3 = null;
			sprite.__cacheBitmapColorTransform = null;
		}
	}
}
