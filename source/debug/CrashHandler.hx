package debug;

//crash handler stuff
import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;

class CrashHandler {
	public static function init() {
		FlxG.stage.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#if cpp untyped __global__.__hxcpp_set_critical_error_handler(onError); #end
	}

	static function onCrash(e:UncaughtErrorEvent):Void {
		var message:String = "";
		if (Std.isOfType(e.error, Error))
			message = cast(e.error, Error).message;
		else if (Std.isOfType(e.error, ErrorEvent))
			message = cast(e.error, ErrorEvent).text;
		else message = try Std.string(e.error) catch(_:haxe.Exception) "Unknown";

		var dateNow:String = Date.now().toString().replace(" ", "_").replace(":", "'");
		final path:String = './crash/AlterEngine_$dateNow.txt';

		var errMsg:String = "";
		for (stackItem in haxe.CallStack.exceptionStack(true)) {
			switch (stackItem) {
				case CFunction: errMsg += "Non-Haxe (C) Function\n";
				case Module(c): errMsg += 'Module ${c}\n';
				case FilePos(p, file, line, _):
					switch(p) {
						case Method(cla, func): errMsg += '[$file] ${cla.split(".")[cla.split(".").length - 1]}.$func() - (line $line)\n';
						case _: errMsg += '$file (line $line)\n';
					}
				case LocalFunction(v): errMsg += 'Local Function ${v}\n';
				case Method(cl, m): errMsg += '${cl} - ${m}\n';
				default: Sys.println(stackItem);
			}
		}

		e.preventDefault();
		e.stopPropagation();
		e.stopImmediatePropagation();

		errMsg += '\nUncaught Error: $message\nPlease report this error to the GitHub page: https://github.com/system32unknown/FNF-BabyShark\n\nCrash Handler written by: sqirra-rng\nCustom Crash Handler by: Codename Engine Team';

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");
		File.saveContent(path, '$errMsg\n');

		Sys.println(errMsg);
		Sys.println('Crash dump saved in ${haxe.io.Path.normalize(path)}');

		utils.system.NativeUtil.showMessageBox("Alter Engine: Error!", errMsg, MSG_ERROR);
		
		#if DISCORD_ALLOWED DiscordClient.shutdown(); #end
		#if sys Sys.exit(1); #end
	}

	#if cpp
	static function onError(message:Dynamic):Void
		throw Std.string(message);
	#end
}