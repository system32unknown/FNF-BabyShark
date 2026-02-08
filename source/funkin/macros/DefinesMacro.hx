package funkin.macros;

@:nullSafety
class DefinesMacro {
	/**
	 * Returns the defined values
	 */
	public static var defines(get, never):Map<String, String>;
	
	// Manually, without macro for scripts.
  	public static function isDefined(define:String):Bool
		return defines.exists(define);

	static inline function get_defines():Map<String, String> return __get();
	static macro function __get():haxe.macro.Expr {
		return macro $v{#if display []:Map<String, Dynamic> #else haxe.macro.Context.getDefines() #end};
	}
}