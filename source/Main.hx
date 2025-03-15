package;

import openfl.display.Sprite;
import flixel.input.keyboard.FlxKey;
import utils.system.MemoryUtil;
import utils.GameVersion;
import debug.FPSCounter;
#if HSCRIPT_ALLOWED
import alterhscript.AlterHscript;
import psychlua.HScript.HScriptInfos;
import haxe.PosInfos;
#end
#if desktop
import backend.ALSoftConfig; // Just to make sure DCE doesn't remove this, since it's not directly referenced anywhere else.
#end

#if (linux && !debug)
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end
class Main extends Sprite {
	public static var engineVer:GameVersion = '0.1.5';
	public static var fnfVer:GameVersion = '0.5.3';

	public static final game = {
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
		utils.system.PlatformUtil.fixScaling();
		#if (linux || mac) openfl.Lib.current.stage.window.setIcon(lime.graphics.Image.fromFile("icon.png")); #end

		#if CRASH_HANDLER debug.CrashHandler.init(); #end
		debug.Logs.init();

		#if HSCRIPT_ALLOWED
		AlterHscript.warn = function(x, ?pos:PosInfos) {
			AlterHscript.logLevel(WARN, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '') + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) msgInfo += '${newPos.lineNumber}:';
			msgInfo += ' $x';
			if (PlayState.instance != null) PlayState.instance.addTextToDebug('WARNING: $msgInfo', FlxColor.YELLOW);
		}
		AlterHscript.error = function(x, ?pos:PosInfos) {
			AlterHscript.logLevel(ERROR, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '') + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) msgInfo += '${newPos.lineNumber}:';
			msgInfo += ' $x';
			if (PlayState.instance != null) PlayState.instance.addTextToDebug('ERROR: $msgInfo', FlxColor.RED);
		}
		AlterHscript.fatal = function(x, ?pos:PosInfos) {
			AlterHscript.logLevel(FATAL, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '') + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) msgInfo += '${newPos.lineNumber}:';
			msgInfo += ' $x';
			if (PlayState.instance != null) PlayState.instance.addTextToDebug('FATAL: $msgInfo', 0xFFBB0000);
		}
		#end

		addChild(new backend.FunkinGame(game.width, game.height, () -> new Init(), game.framerate, game.framerate, game.skipSplash, game.startFullscreen));
		ClientPrefs.load();
		addChild(fpsVar = new FPSCounter());
		fpsVar.visible = ClientPrefs.data.showFPS;
		fpsVar.memType = ClientPrefs.data.memCounterType;

		#if !MODS_ALLOWED
		final path:String = 'mods';
		if (FileSystem.exists(path) && FileSystem.isDirectory(path)) {
			for (entry in FileSystem.readDirectory(path)) FileSystem.deleteFile('$path/$entry');
			FileSystem.deleteDirectory(path);
		}
		#end

		FlxG.signals.preStateSwitch.add(() -> if (ClientPrefs.data.autoCleanAssets) Paths.clearStoredMemory());
		FlxG.signals.postStateSwitch.add(() -> {
			if (ClientPrefs.data.autoCleanAssets) Paths.clearUnusedMemory();
			if (!ClientPrefs.data.disableGC) {
				MemoryUtil.clearMajor();
				MemoryUtil.clearMajor(true);
				MemoryUtil.clearMajor();
			}
		});
		FlxG.signals.gameResized.add((w:Int, h:Int) -> {
			if (FlxG.cameras != null)
				for (cam in FlxG.cameras.list) {
					if (cam != null && cam.filters != null)
						resetSpriteCache(cam.flashSprite);
				}
			if (FlxG.game != null) resetSpriteCache(FlxG.game);
			@:privateAccess FlxG.game.soundTray._defaultScale = (w / FlxG.width) * 2;
		});
		#if VIDEOS_ALLOWED hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0") ['--no-lua'] #end); #end
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
