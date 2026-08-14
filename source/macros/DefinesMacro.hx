package macros;

@:nullSafety
class DefinesMacro {
	/**
	 * Returns the defined values
	 */
	public static var defines(get, never):Map<String, String>;

	static inline function get_defines():Map<String, String> return __get();
	static macro function __get():haxe.macro.Expr {
		return macro $v{#if display []:Map<String, Dynamic> #else haxe.macro.Context.getDefines() #end};
	}
}