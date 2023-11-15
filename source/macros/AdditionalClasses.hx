package macros;

#if macro
import haxe.macro.Compiler;

/**
 * Macros containing additional help functions to expand HScript capabilities.
*/
class AdditionalClasses {
	public static function add() {
		var include:Array<String> = [
			// FLIXEL
			"flixel", "lime", "haxe", "openfl",
			#if VIDEOS_ALLOWED "hxcodec", #end
			#if LUA_ALLOWED "llua", #end
			#if desktop "discord_rpc", #end
			"hscript",
			// OTHER LIBRARIES & STUFF
			#if cpp "cpp", #end
			#if hl "hl", #end
			#if neko "neko", #end
			#if sys "sys", #end
			// BASE PATH LIBRARIES THAT DOESN'T INCLUDE
			"backend", "shaders", "objects", "backend.subtitles",
			// BASE HAXE
			"DateTools", "EReg", "Lambda", "StringBuf"
		];
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

		for (inc in include) Compiler.include(inc, true, exc);
		Compiler.addGlobalMetadata('haxe.xml', '@:build(hscript.macros.UsingHandler.build())');
		Compiler.addGlobalMetadata('haxe.CallStack', '@:build(hscript.macros.UsingHandler.build())');
	}
}
#end