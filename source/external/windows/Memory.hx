package external.windows;

#if (windows && cpp)
/**
 * This class provides handling for Windows API-related functions.
 */
@:build(macros.LinkerMacro.xml('project/Build.xml'))
@:include('memory.hpp')
extern class Memory {
	/**
	 * Retrieves the current working set size (in bytes) of the process.
	 *
	 * @return The size of the working set memory used by the process.
	 */
	@:native('GetCurrentRSS')
	static function getCurrentRSS():cpp.SizeT;
}
#end