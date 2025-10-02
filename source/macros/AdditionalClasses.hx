package macros;

#if macro
import haxe.macro.Compiler;

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

		if (haxe.macro.Context.defined("sys")) Compiler.include("openfl.net");
		for (inc in [
			// FLIXEL
			"flixel", "lime", "haxe", "openfl", "funkin.vis",
			#if VIDEOS_ALLOWED "hxvlc", #end
			#if (desktop && DISCORD_ALLOWED) "hxdiscord_rpc", #end
			"hscript",
			// OTHER LIBRARIES & STUFF
			#if cpp "cpp", #end
			#if sys "sys", #end
			"json2object",
			// BASE PATH LIBRARIES THAT DOESN'T INCLUDE
			"backend", "shaders", "objects", "utils",
			// BASE HAXE
			"DateTools", "EReg", "Lambda", "StringBuf"
		]) Compiler.include(inc, true, exc);
	}
}
#end