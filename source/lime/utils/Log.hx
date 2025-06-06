package lime.utils;

import haxe.PosInfos;
#if !macro import debug.Logs as FunkinLogs; #end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class Log {
	public static var level:LogLevel;

	public static function debug(message:Dynamic, ?info:PosInfos):Void {
		if (level >= LogLevel.DEBUG) #if js untyped __js__("console").debug #else println #end('[${info.className}] $message');
	}

	public static function error(message:Dynamic, ?info:PosInfos):Void {
		if (level >= LogLevel.ERROR) {
			var message:String = '[${info.className}] ERROR: $message';
			#if !macro FunkinLogs.error(message); #else trace(message); #end
			throw message;
		}
	}

	public static function info(message:Dynamic, ?info:PosInfos):Void {
		if (level >= LogLevel.INFO) trace('[${info.className}] $message');
	}

	public static inline function print(message:Dynamic):Void {
		#if sys
		Sys.print(Std.string(message));
		#elseif flash
		untyped __global__["trace"](Std.string(message));
		#elseif js
		untyped __js__("console").log(message);
		#else
		trace(message);
		#end
	}

	public static inline function println(message:Dynamic):Void {
		#if sys
		Sys.println(Std.string(message));
		#elseif flash
		untyped __global__["trace"](Std.string(message));
		#elseif js
		untyped __js__("console").log(message);
		#else
		trace(Std.string(message));
		#end
	}

	public static function verbose(message:Dynamic, ?info:PosInfos):Void {
		if (level >= LogLevel.VERBOSE) #if !macro FunkinLogs.verbose('[${info.className}] $message'); #else trace('[${info.className}] $message'); #end
	}

	public static function warn(message:Dynamic, ?info:PosInfos):Void {
		if (level >= LogLevel.WARN) #if !macro FunkinLogs.warn('[${info.className}] $message'); #else trace('[${info.className}] $message'); #end
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
		if (untyped __js__("typeof console") == "undefined") untyped __js__("console = {}");
		if (untyped __js__("console").log == null) untyped __js__("console").log = function() {};
		#end
	}
}