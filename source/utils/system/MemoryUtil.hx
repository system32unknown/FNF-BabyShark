package utils.system;

import _external.memory.Memory;

#if cpp
import cpp.vm.Gc;

#if windows
@:cppFileCode('
	#include <windows.h>
	#include <psapi.h>
')
#elseif linux
@:cppFileCode('#include <stdio.h>')
#elseif mac
@:cppFileCode('
	#include <unistd.h>
	#include <sys/resource.h>
	#include <mach/mach.h>
')
#end
#elseif hl
import hl.Gc;
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
		#elseif hl
		Gc.blocking(true);
		Gc.major();
		Gc.blocking(false);
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
		cpp.NativeGc.enable(isGcOn);
		#elseif hl
		Gc.enable(isGcOn);
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
		#end
	}

	public static var appMemoryNumber(get, never):Float;
	static function get_appMemoryNumber():Float {
		return Memory.getCurrentUsage();
	}
}