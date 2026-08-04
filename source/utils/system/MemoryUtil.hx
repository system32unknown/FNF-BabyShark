package utils.system;

#if cpp
import cpp.vm.Gc;
#end

/**
 * Utilities for working with the garbage collector.
 *
 * HXCPP is built on Immix.
 * HTML5 builds use the browser's built-in mark-and-sweep and JS has no APIs to interact with it.
 * @see https://www.cs.cornell.edu/courses/cs6120/2019fa/blog/immix/
 * @see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Memory_management
 * @see https://betterprogramming.pub/deep-dive-into-garbage-collection-in-javascript-6881610239a
 * @see https://github.com/HaxeFoundation/hxcpp/blob/master/docs/build_xml/Defines.md
 * @see cpp.vm.Gc
 */
@:nullSafety
class MemoryUtil {
	/**
	 * Flag indicating whether the garbage collector is enabled.
	 * When `true`, the GC is active; setting it to `false` may disable automatic collection.
	 */
	public static var isGcOn:Bool = true;

	/**
	 * Triggers a garbage collection cycle.
	 * @param major If true, performs a major collection; otherwise, does a major collection.
	 */
	public static function clearMajor(major:Bool = false):Void {
		#if cpp
		Gc.run(major);
		if (major) Gc.compact();
		#else
		openfl.system.System.gc();
		#end
	}

	/**
	 * Enable or disable garbage collection.
	 */
	public static function enable(on:Bool = true):Void {
		isGcOn = on;
		#if cpp
		Gc.enable(isGcOn);
		#else
		throw 'Not implemented!';
		#end
	}

	/**
	 * Manually perform garbage collection once.
	 * Should only be called from the main thread.
	 * @param major `true` to perform major collection, whatever that means.
	 */
	public static function collect(major:Bool = false):Void {
		#if cpp
		Gc.run(major);
		#else
		throw 'Not implemented!';
		#end
	}

	/**
	 * Perform major garbage collection repeatedly until less than 16kb of memory is freed in one operation.
	 * Should only be called from the main thread.
	 *
	 * NOTE: This is DIFFERENT from actual compaction,
	 */
	public static function compact():Void {
		#if cpp
		Gc.compact();
		#else
		throw 'Not implemented!';
		#end
	}

	public static function supportsTaskMem():Bool {
		return #if ((cpp && (windows || macos)) || linux) true #else false #end;
	}

	/**
	 * @return The current task memory for the game process.
	 */
	public static function getTaskMemory():Float {
		#if (windows && cpp)
		return external.windows.Memory.getCurrentRSS();
		#elseif (macos && cpp)
		return external.apple.Memory.getCurrentRSS();
		#elseif linux
		return external.linux.Memory.getCurrentRSS();
		#else
		return 0.0;
		#end
	}
}