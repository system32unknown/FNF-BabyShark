package macro;

#if macro
import haxe.macro.Compiler;

/**
 * Macros containing additional help functions to expand HScript capabilities.
*/
class ScriptsMacro {
	public static function addAdditionalClasses() {
		var include:Array<String> = [
			// FLIXEL
			"flixel", "lime", "haxe",
			// OTHER LIBRARIES & STUFF
			#if flash "flash", #end
			#if cpp "cpp", #end
			#if hl "hl", #end
			#if neko "neko", #end
			#if sys "sys", #end "openfl.net", "shaders",
			// BASE HAXE
			"DateTools", "EReg", "Lambda", "StringBuf", "haxe"
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
	}
}
#end