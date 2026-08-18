package lime.utils;

import haxe.PosInfos;
#if !macro import debug.Logs as FunkinLogs; #end
#if js import js.Syntax #end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class Log {
	public static var level:LogLevel;

	public static function debug(message:Dynamic, ?info:PosInfos):Void {
		if (level >= LogLevel.DEBUG) #if js untyped Syntax.code("console").debug #else println #end('[${info.className}] $message');
	}

	public static function error(message:Dynamic, ?info:PosInfos):Void {
		if (level >= LogLevel.ERROR) {
			var message:String = '[${info.className}] ERROR: $message';
			#if !macro FunkinLogs.error #else trace #end(message);
			throw message;
		}
	}

	public static function info(message:Dynamic, ?info:PosInfos):Void {
		if (level >= LogLevel.INFO) #if !macro trace #else println #end('[${info.className}] $message');
	}

	public static inline function print(message:Dynamic):Void {
		#if sys
		Sys.print(Std.string(message));
		#elseif js
		untyped Syntax.code("console").log(message);
		#else
		trace(message);
		#end
	}

	public static inline function println(message:Dynamic):Void {
		#if sys
		Sys.println(Std.string(message));
		#elseif js
		untyped Syntax.code("console").log(message);
		#else
		trace(Std.string(message));
		#end
	}

	public static function verbose(message:Dynamic, ?info:PosInfos):Void {
		if (level >= LogLevel.VERBOSE) #if !macro FunkinLogs.verbose #else trace #end('[${info.className}] $message');
	}

	public static function warn(message:Dynamic, ?info:PosInfos):Void {
		if (level >= LogLevel.WARN) #if !macro FunkinLogs.warn #else trace #end('[${info.className}] $message');
	}

	static function __init__():Void {
		#if no_traces
		level = NONE;
		#elseif verbose
		level = VERBOSE;
		#else
		#if sys
		var args:Array<String> = Sys.args();
		if (args.indexOf("-v") > -1 || args.indexOf("-verbose") > -1) {
			level = VERBOSE;
		} else
		#end
			level = #if debug DEBUG #else INFO #end;
		#end

		#if js
		if (untyped Syntax.code("typeof console") == "undefined") untyped Syntax.code("console = {}");
		if (untyped Syntax.code("console").log == null) untyped Syntax.code("console").log = () -> {};
		#end
	}
}