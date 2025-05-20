package macros;

#if macro import haxe.macro.Context; #end

class DefinesMacro {
	/**
	 * Returns the defined values
	 */
	public static var defines(get, never):Map<String, Dynamic>;

	static inline function get_defines():Map<String, Dynamic> return _get();
	static macro function _get() {
		return macro $v{#if display [] #else Context.getDefines() #end};
	}
}