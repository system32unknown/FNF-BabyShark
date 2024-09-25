package debug;

//crash handler stuff
import haxe.CallStack;
import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
import lime.system.System;
import utils.system.NativeUtil;

class CrashHandler {
	public static function init() {
		FlxG.stage.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onErrorOFL);
		#if cpp untyped __global__.__hxcpp_set_critical_error_handler(onError); #end
	}

	static function onErrorOFL(e:UncaughtErrorEvent) {
		var message:String = '';
		if (Std.isOfType(e.error, Error)) message = cast(e.error, Error).message;
		else if (Std.isOfType(e.error, ErrorEvent)) message = cast(e.error, ErrorEvent).text;
		else message = Std.string(e.error);

		e.stopImmediatePropagation();
		e.preventDefault();

		onError(message);
	}

	static function onError(message:String):Void {
		final path:String = './crash/${FlxG.stage.application.meta.get('file')}_${Date.now().toString().replace(" ", "_").replace(":", "'")}.txt';
		
		var errMsg:String = CallStack.toString(CallStack.exceptionStack(true)).trim();
		errMsg += '\nPlatform: ${System.platformLabel} ${System.platformVersion}';
		errMsg += '\nFlixel Current State: ${Type.getClassName(Type.getClass(FlxG.state))}';
		errMsg += '\nUncaught Error: $message\nPlease report this error to the GitHub page: https://github.com/system32unknown/FNF-BabyShark\n\nCustom Crash Handler written by: sqirra-rng and Codename Engine Team and Altertoriel';

		try {
			if (!FileSystem.exists("./crash/")) FileSystem.createDirectory("./crash/");
			File.saveContent(path, errMsg);

			Sys.println(errMsg);
			Sys.println('Crash dump saved in ${haxe.io.Path.normalize(path)}');
		} catch (e:Dynamic) Sys.println('Error!\nCouldn\'t save the crash dump because:\n$e');

		NativeUtil.showMessageBox("Alter Engine: Error!", errMsg, MSG_ERROR);
		#if DISCORD_ALLOWED DiscordClient.shutdown(); #end
		System.exit(1);
	}
}