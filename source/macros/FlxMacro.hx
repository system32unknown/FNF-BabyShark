package macros;

#if macro
import haxe.macro.Context;

@:nullSafety
class FlxMacro {
	public static function initMacros():Void {
		if (Context.defined("hscript_improved") && !Context.defined("hscript")) haxe.macro.Compiler.define("hscript");
	}
}
#end