package macros;

#if macro import haxe.macro.Context; #end

class DefinesMacro {
	/**
	 * Returns the defined values
	 */
	public static var defines(get, null):Map<String, Dynamic>;

	// GETTERS
	static inline function get_defines()
		return __getDefines();

	// INTERNAL MACROS
	static macro function __getDefines() {
		return macro $v{#if display [] #else Context.getDefines() #end};
	}
}