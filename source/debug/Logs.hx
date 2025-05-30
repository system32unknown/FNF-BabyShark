package debug;

import haxe.Log;
import haxe.PosInfos;

import flixel.system.debug.log.LogStyle;

import utils.system.NativeUtil;
import utils.system.Ansi.AnsiColor;

// Credit by Codename Engine Team
class Logs {
	public static function init() {
		Log.trace = function(v:Dynamic, ?infos:Null<PosInfos>) {
			final data = [{fgColor: CYAN, text: '${infos.fileName}:${infos.lineNumber}: '}, {text: Std.string(v)}];
			if (infos.customParams != null) {
				for (i in infos.customParams) data.push({text: ", " + Std.string(i)});
			}
			printChunks(prepareColoredTrace(data, TRACE));
		};

		LogStyle.NORMAL.onLog.add((d:Any, ?pos:PosInfos) -> onLog(LogStyle.NORMAL, d, pos));
		LogStyle.WARNING.onLog.add((d:Any, ?pos:PosInfos) -> onLog(LogStyle.WARNING, d, pos));
		LogStyle.ERROR.onLog.add((d:Any, ?pos:PosInfos) -> onLog(LogStyle.ERROR, d, pos));
		LogStyle.NOTICE.onLog.add((d:Any, ?pos:PosInfos) -> onLog(LogStyle.NOTICE, d, pos));
		LogStyle.CONSOLE.onLog.add((d:Any, ?pos:PosInfos) -> onLog(LogStyle.CONSOLE, d, pos));
	}

	public static function trace(text:String):Void {
		traceColored([{text: text}]);
	}
	public static function warn(text:String):Void {
		traceColored([{text: text, fgColor: YELLOW}], WARNING);
	}
	public static function error(text:String):Void {
		traceColored([{text: text, fgColor: RED}], ERROR);
	}
	public static function verbose(text:String):Void {
		traceColored([{text: text}], VERBOSE);
	}

	public static function traceColored(chunks:Array<LogChunk>, ?level:Level = TRACE):Void {
		printChunks(prepareColoredTrace(chunks, level));
	}

	public static function prepareColoredTrace(chunks:Array<LogChunk>, ?level:Level = TRACE):Array<LogChunk> {
		final newChunks:Array<LogChunk> = [
			{text: '['},
			switch (level) {
				case WARNING: {fgColor: YELLOW, text: "WARNING"}
				case ERROR: {fgColor: RED, text: "ERROR"}
				case VERBOSE: {fgColor: MAGENTA, text: "VERBOSE"}
				default: {fgColor: CYAN, text: "TRACE"}
			}, {text: '] '}
		];
		for (k => e in newChunks) chunks.insert(k, e);
		return chunks;
	}

	public static function printChunks(chunks:Array<LogChunk>):Void {
		while (_showing) Sys.sleep(.05);

		_showing = true;

		for (i in 0...chunks.length) {
			final chunk:LogChunk = chunks[i];
			NativeUtil.setAnsiColors(chunk.fgColor, chunk.bgColor);
			Sys.print(chunk.text);
		}
		NativeUtil.setAnsiColors();
		Sys.print("\n");

		_showing = false;
	}

	//----------- [ Private API ] -----------//

	static var _showing:Bool = false;

	static function onLog(Style:LogStyle, Data:Any, ?Pos:PosInfos):Void {
		var prefix:String = "[FLIXEL]";
		var level:Level = TRACE;

		if (Style == LogStyle.CONSOLE) {
			prefix = "";
			level = TRACE;
		} else if (Style == LogStyle.ERROR) {
			prefix = "[FLIXEL]";
			level = ERROR;
		} else if (Style == LogStyle.NORMAL) {
			prefix = "[FLIXEL]";
			level = TRACE;
		} else if (Style == LogStyle.NOTICE) {
			prefix = "[FLIXEL]";
			level = WARNING;
		} else if (Style == LogStyle.WARNING) {
			prefix = "[FLIXEL]";
			level = WARNING;
		}

		var d:Dynamic = Data;
		if (!(d is Array)) d = [d];

		var a:Array<Dynamic> = d;
		for (e in [for (e in a) Std.string(e)]) traceColored([{text: '$prefix ', fgColor: CYAN}, {text: e}], level);
	}
}

enum abstract Level(Int) from Int to Int {
	var TRACE:Level = 0;
	var WARNING:Level = 1;
	var ERROR:Level = 2;
	var VERBOSE:Level = 3;
}
typedef LogChunk = {
	var ?bgColor:AnsiColor;
	var ?fgColor:AnsiColor;
	var text:String;
}