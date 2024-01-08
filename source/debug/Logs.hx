package debug;

import flixel.system.debug.log.LogStyle;
import flixel.system.frontEnds.LogFrontEnd;
import haxe.Log;
import utils.system.NativeUtil;
import utils.system.NativeUtil.ConsoleColor;

//Credit by Codename Engine Team
class Logs {
	static var __showing:Bool = false;

	public static var nativeTrace = Log.trace;
	public static function init() {
		Log.trace = function(v:Dynamic, ?infos:Null<haxe.PosInfos>) {
			var data = [
				logText('${infos.fileName}:${infos.lineNumber}: ', CYAN),
				logText(Std.string(v))
			];

			if (infos.customParams != null)
				for (i in infos.customParams)
					data.push(logText("," + Std.string(i)));
			__showInConsole(prepareColoredTrace(data, TRACE));
		};

		LogFrontEnd.onLogs = function(Data, Style, FireOnce) {
			var prefix = "[FLIXEL]";
			var color:ConsoleColor = LIGHTGRAY;
			var level:Level = INFO;
			if (Style == LogStyle.CONSOLE) {prefix = "> "; color = WHITE;	level = INFO;} else
			if (Style == LogStyle.ERROR) {prefix = "[FLIXEL]"; color = RED; level = ERROR;} else
			if (Style == LogStyle.NORMAL) {prefix = "[FLIXEL]"; color = WHITE; level = INFO;} else
			if (Style == LogStyle.NOTICE) {prefix = "[FLIXEL]"; color = GREEN; level = VERBOSE;} else
			if (Style == LogStyle.WARNING) {prefix = "[FLIXEL]"; color = YELLOW; level = WARNING;}

			var d:Dynamic = Data;
			if (!(d is Array)) d = [d];
			var a:Array<Dynamic> = d;
			for(e in [for(e in a) Std.string(e)]) Logs.trace('$prefix $e', level, color);
		};
	}

	public static function prepareColoredTrace(text:Array<LogText>, level:Level = INFO) {
		var time = Date.now();
		var superCoolText = [
			logText('['),
			switch(level) {
				case WARNING: logText('WARNING', DARKYELLOW);
				case ERROR: logText('ERROR', DARKRED);
				case TRACE: logText('TRACE', GRAY);
				case VERBOSE: logText('VERBOSE', DARKMAGENTA);
				default: logText('INFORMATION', CYAN);
			}, logText('] ')
		];
		for(k => e in superCoolText)
			text.insert(k, e);
		return text;
	}

	public static function logText(text:String, color:ConsoleColor = LIGHTGRAY):LogText {
		return {text: text, color: color};
	}

	public static function __showInConsole(text:Array<LogText>) {
		#if sys
		while(__showing) Sys.sleep(.05);
		__showing = true;
		for(t in text) {
			NativeUtil.setConsoleColors(t.color);
			Sys.print(t.text);
		}
		NativeUtil.setConsoleColors();
		Sys.print("\r\n");
		__showing = false;
		#else
		@:privateAccess
		nativeTrace([for(t in text) t.text].join(""));
		#end
	}

	public static function traceColored(text:Array<LogText>, level:Level = INFO) {
		__showInConsole(prepareColoredTrace(text, level));
	}
	public static function trace(text:String, level:Level = INFO, color:ConsoleColor = LIGHTGRAY) {
		traceColored([{text: text, color: color}], level);
	}
}

enum abstract Level(Int) {
	var INFO = 0;
	var WARNING = 1;
	var ERROR = 2;
	var TRACE = 3;
	var VERBOSE = 4;
}
typedef LogText = {
	var text:String;
	var color:ConsoleColor;
}