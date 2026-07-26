package external.apple;

#if (macos && cpp)
/**
 * A utility class to get information about the mem usage.
 */
@:build(macros.LinkerMacro.xml('project/Build.xml'))
@:include('memory.hpp')
@:unreflective
extern class Memory {
	/**
	 * Retrieves the current process's resident set size (RSS) in bytes on Apple platforms.
	 *
	 * @return The resident set size (RSS) in bytes if successful; otherwise, returns 0 on failure.
	 */
	@:native('GetCurrentRSS')
	static function getCurrentRSS():cpp.SizeT;
}
#end