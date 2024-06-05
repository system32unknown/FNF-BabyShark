package debug;

//crash handler stuff
import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
import lime.system.System;
import flixel.FlxG.FlxRenderMethod;
import utils.system.NativeUtil;

class CrashHandler {
	public static function init() {
		FlxG.stage.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#if cpp untyped __global__.__hxcpp_set_critical_error_handler((message:Dynamic) -> NativeUtil.showMessageBox("Alter Engine: Critical Error!", message, MSG_ERROR)); #end
	}

	static function onCrash(e:UncaughtErrorEvent):Void {
		var message:String = "";
		if (Std.isOfType(e.error, Error))
			message = cast(e.error, Error).message;
		else if (Std.isOfType(e.error, ErrorEvent))
			message = cast(e.error, ErrorEvent).text;
		else message = Std.string(e.error);

		final path:String = './crash/${FlxG.stage.application.meta.get('file')}_${Date.now().toString().replace(" ", "_").replace(":", "'")}.log';

		var errMsg:String = "";
		for (stackItem in haxe.CallStack.exceptionStack(true)) {
			switch (stackItem) {
				case FilePos(p, file, line, column):
					switch(p) {
						case Method(cla, func): errMsg += '[$file] ${cla.split(".")[cla.split(".").length - 1]}.$func() - (line $line)';
						case _: errMsg += '$file (line $line)';
					}
					if (column != null) errMsg += ':$column';
				case CFunction: errMsg += "Non-Haxe (C) Function";
				case Module(c): errMsg += 'Module $c';
				case Method(cl, m): errMsg += '$cl - $m';
				case LocalFunction(v): errMsg += 'Local Function $v';
			}
			errMsg += '\n';
		}

		e.preventDefault();
		e.stopImmediatePropagation();

		errMsg += '\nPlatform: ${System.platformLabel} ${System.platformVersion}';
		errMsg += '\nFlixel Current State: ${Type.getClassName(Type.getClass(FlxG.state))}';
		errMsg += '\nRender Method: ${renderMethod()}';
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

	static function renderMethod():String {
	  	try {
			return switch (FlxG.renderMethod) {
			  	case FlxRenderMethod.DRAW_TILES: 'DRAW_TILES';
			  	case FlxRenderMethod.BLITTING: 'BLITTING';
			  	default: 'UNKNOWN';
			}
	  	} catch (e) return 'ERROR ON QUERY RENDER METHOD: ${e}';
	}
}