package debug;

// crash handler stuff
import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
import lime.system.System;

class CrashHandler {
	public static function init() {
		FlxG.stage.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onErrorOFL);
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onError);
		#elseif hl
		hl.Api.setErrorHandler(onError);
		#end
	}

	static function onErrorOFL(e:UncaughtErrorEvent) {
		var message:String = '';
		if (Std.isOfType(e.error, Error)) {
			var err:Error = cast(e.error, Error);
			message = err.getStackTrace() ?? err.message;
		} else if (Std.isOfType(e.error, ErrorEvent)) message = cast(e.error, ErrorEvent).text;
		else message = Std.string(e.error);

		e.preventDefault();
		e.stopImmediatePropagation();

		onError(message);
	}

	static function onError(message:String):Void {
		final path:String = './crash/${FlxG.stage.application.meta.get('file')}_${Date.now().toString().replace(" ", "_").replace(":", "'")}.txt';
		final defines:Map<String, Dynamic> = macros.DefinesMacro.defines;

		var errMsg:String = getError();
		errMsg += '\nPlatform: ${System.platformLabel} ${System.platformVersion} [Target: ${psychlua.LuaUtils.getTarget()}]';
		errMsg += '\nFlixel Current State: ${Type.getClassName(Type.getClass(FlxG.state))}';
		errMsg += '\nUncaught Error: $message\nPlease report this error to the GitHub page: https://github.com/system32unknown/FNF-BabyShark\n\nCustom Crash Handler written by: sqirra-rng and Codename Engine Team and Altertoriel';
		errMsg += '\nHaxe: ${defines['haxe']} / Flixel: ${defines['flixel']}\nOpenFL: ${defines['openfl']} / Lime: ${defines['lime']}';
		if (Mods.currentModDirectory != '') errMsg += '\nCurrent Active Mod: ${Mods.currentModDirectory}';

		try {
			if (!FileSystem.exists("./crash/")) FileSystem.createDirectory("./crash/");
			File.saveContent(path, errMsg);

			Sys.println("\n" + errMsg);
			Sys.println('Crash dump saved in ${haxe.io.Path.normalize(path)}');
		} catch (e:Dynamic) Sys.println('Error!\nCouldn\'t save the crash dump because:\n$e');

		utils.system.NativeUtil.showMessageBox("Alter Engine: Error!", errMsg, MSG_ERROR);
		#if DISCORD_ALLOWED DiscordClient.shutdown(); #end
		System.exit(1);
	}

	static function getError():String {
		var error:String = "";
		for (stackItem in haxe.CallStack.exceptionStack(true)) {
			switch (stackItem) {
				case FilePos(p, file, line, column):
					switch (p) {
						case Method(cla, func): error += '[$file] ${cla.split(".")[cla.split(".").length - 1]}.$func() - (line $line)';
						case _: error += '$file (line $line)';
					}
					if (column != null) error += ':$column';
				case CFunction: error += "Non-Haxe (C) Function";
				case Module(c): error += 'Module $c';
				case Method(cl, m): error += '$cl - $m';
				case LocalFunction(v): error += 'Local Function $v';
				default: Sys.println(stackItem);
			}
			error += '\n';
		}
		return error;
	}
}