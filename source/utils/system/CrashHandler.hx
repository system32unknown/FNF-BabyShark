package utils.system;

//crash handler stuff
import openfl.Lib;
import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
import haxe.CallStack;
import haxe.io.Path;

class CrashHandler {
	public static function init() {
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onError);
		#elseif hl
		hl.Api.setErrorHandler(onError);
		#end
	}

	public static function onCrash(e:UncaughtErrorEvent):Void {
		var message:String = "";
		if (Std.isOfType(e.error, Error)) {
			var err = cast(e.error, Error);
			message = '${err.message}';
		} else if (Std.isOfType(e.error, ErrorEvent)) {
			var err = cast(e.error, ErrorEvent);
			message = '${err.text}';
		} else message = try Std.string(e) catch(_:haxe.Exception) "Unknown";

		var dateNow:String = Date.now().toString().replace(" ", "_").replace(":", "'");
		final path = './crash/PsychEngine_$dateNow.txt';

		final callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var errMsg:String = "";

		for (stackItem in callStack) {
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

		errMsg += '\nUncaught Error: $message\nPlease report this error to the GitHub page: https://github.com/system32unknown/FNF-BabyShark\n\nCrash Handler written by: sqirra-rng\nCustom Crash Handler by: Altertoriel';

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");
		File.saveContent(path, 'errMsg\n');

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		CoolUtil.callErrBox("Alter Engine: Error!", errMsg);
		
		#if discord_rpc Discord.shutdown(); #end
		#if sys Sys.exit(1); #end
	}

	#if (cpp || hl)
	static function onError(message:Dynamic):Void {
		throw Std.string(message);
	}
	#end
}