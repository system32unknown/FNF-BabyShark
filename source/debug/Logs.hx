package debug;

import haxe.Log;
import haxe.PosInfos;

import flixel.system.debug.log.FlxLogStyle;

import utils.system.NativeUtil;
import utils.system.Ansi.AnsiColor;

// Credit by Codename Engine Team
class Logs {
	public static function init():Void {
		Log.trace = function(v:Dynamic, ?infos:Null<PosInfos>) {
			final data = [{fgColor: CYAN, text: '${infos.fileName}:${infos.lineNumber}: '}, {text: Std.string(v)}];
			if (infos.customParams != null) {
				for (i in infos.customParams) data.push({text: ", " + Std.string(i)});
			}
			printChunks(prepareColoredTrace(data, TRACE));
		};

		FlxG.log.styles.normal.onLog.add((d:Any, ?pos:PosInfos) -> onLog(FlxG.log.styles.normal, d, pos));
		FlxG.log.styles.warning.onLog.add((d:Any, ?pos:PosInfos) -> onLog(FlxG.log.styles.warning, d, pos));
		FlxG.log.styles.error.onLog.add((d:Any, ?pos:PosInfos) -> onLog(FlxG.log.styles.error, d, pos));
		FlxG.log.styles.notice.onLog.add((d:Any, ?pos:PosInfos) -> onLog(FlxG.log.styles.notice, d, pos));
		FlxG.log.styles.console.onLog.add((d:Any, ?pos:PosInfos) -> onLog(FlxG.log.styles.console, d, pos));
	}

	public static function trace(text:String):Void
		traceColored([{text: text}]);

	public static function warn(text:String):Void
		traceColored([{text: text, fgColor: YELLOW}], WARNING);

	public static function error(text:String):Void
		traceColored([{text: text, fgColor: RED}], ERROR);

	public static function verbose(text:String):Void
		if (Main.verbose) traceColored([{text: text}], VERBOSE);

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

	static function onLog(Style:FlxLogStyle, Data:Any, ?Pos:PosInfos):Void {
		var prefix:String = "[FLIXEL]";
		var level:Level = TRACE;

		if (Style == FlxG.log.styles.console) {
			prefix = "";
			level = TRACE;
		} else if (Style == FlxG.log.styles.error) {
			prefix = "[FLIXEL]";
			level = ERROR;
		} else if (Style == FlxG.log.styles.normal) {
			prefix = "[FLIXEL]";
			level = TRACE;
		} else if (Style == FlxG.log.styles.notice) {
			prefix = "[FLIXEL]";
			level = WARNING;
		} else if (Style == FlxG.log.styles.warning) {
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