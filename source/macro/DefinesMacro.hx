package macro;

#if macro
import haxe.macro.Context;
#end

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
		#if display
		return macro $v{[]};
		#else
		return macro $v{Context.getDefines()};
		#end
	}
}