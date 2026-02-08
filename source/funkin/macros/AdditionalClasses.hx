package funkin.macros;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;

/**
 * Macros containing additional help functions to expand HScript capabilities.
 */
class AdditionalClasses {
	public static function add() {
		var exc:Array<String> = [
			"flixel.addons.editors.spine",
			"flixel.addons.nape",
			"flixel.system.macros",

			"haxe.macro",
			#if (js || hxcpp) "haxe.atomic.AtomicObject", #end

			"lime._internal.backend.air",
			"lime._internal.backend.html5",
			"lime._internal.backend.kha",
			"lime.tools",
		];

		var compathx4:Array<String> = [
			"sys.db.Sqlite",
			"sys.db.Mysql",
			"sys.db.Connection",
			"sys.db.ResultSet",
			"haxe.remoting.Proxy",
		];

		if (Context.defined("sys"))
			for (inc in ["sys", "openfl.net"])
				if (!Context.defined("hl")) Compiler.include(inc, compathx4);

		for (inc in [
			// FLIXEL
			"flixel", "lime", "haxe", "openfl", "funkin.vis",
			#if VIDEOS_ALLOWED "hxvlc", #end
			#if (desktop && DISCORD_ALLOWED) "hxdiscord_rpc", #end
			"hscript",
			// OTHER LIBRARIES & STUFF
			#if cpp "cpp", #end
			#if sys "sys", #end
			"json2object", "funkin",
			// BASE HAXE
			"DateTools", "EReg", "Lambda", "StringBuf"
		]) Compiler.include(inc, true, exc);
	}
}
#end