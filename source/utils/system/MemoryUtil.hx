package utils.system;

#if cpp
import cpp.vm.Gc;
import flixel.util.FlxDestroyUtil;

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
	 * @param minor If true, performs a minor collection; otherwise, does a major collection.
	 */
	public static function clearMajor(?minor:Bool = false):Void {
		#if cpp
		Gc.run(!minor);
		if (!minor) Gc.compact();
		#else
		openfl.system.System.gc();
		#end
	}

	/**
	 * Enable or disable garbage collection.
	 */
	public static function enable(on:Bool = true):Void {
		#if cpp
		isGcOn = on;
		Gc.enable(isGcOn);
		cpp.NativeGc.enable(isGcOn);
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

	/**
	 * Returns the current resident set size (physical memory use) measured
	 * in bytes, or zero if the value cannot be determined on this OS.
	 * @return gets Current Process Memory.
	 */
	#if cpp
	#if windows
	@:functionCode('
		PROCESS_MEMORY_COUNTERS_EX pmc;
		if (GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc))) return pmc.WorkingSetSize;
	')
	#elseif linux
	@:functionCode('
		long rss = 0L;
		FILE* fp = NULL;

		if ((fp = fopen("/proc/self/statm", "r")) == NULL) return 0L;
		if (fscanf(fp, "%*s%ld", &rss) != 1) {
			fclose(fp);
			return 0L;
		}
		fclose(fp);
		return rss * sysconf(_SC_PAGESIZE);
	')
	#elseif mac
	@:functionCode("
		struct mach_task_basic_info info;
		mach_msg_type_number_t infoCount = MACH_TASK_BASIC_INFO_COUNT;
		if (task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &infoCount) == KERN_SUCCESS) return info.resident_size;
	")
	#end
	#end
	public static function getProcessMEM():Float return 0;

	/**
	 * Retrieves all "zombie" objects (dangling references) detected by the garbage collector.
	 * 
	 * In HXCPP, a "zombie" is an object that was freed but still has a reference.
	 * This function collects all such objects that implement `IFlxDestroyable` and,
	 * if `destroy` is `true`, immediately calls `FlxDestroyUtil.destroy` on them.
	 * 
	 * @param destroy Whether to automatically destroy found zombies.
	 * @return An array of detected zombie objects.
	 */
	public static function getFlxZombies(destroy:Bool = false):Array<Dynamic> {
		var _zombie:Dynamic = null;
		var containedZombies:Array<Dynamic> = [];
		#if cpp
		while ((_zombie = Gc.getNextZombie()) != null) {
			if (_zombie is IFlxDestroyable) {
				containedZombies.push(_zombie);
				if (destroy) FlxDestroyUtil.destroy(cast(_zombie, IFlxDestroyable));
			}
		}
		#end
		_zombie = null;
		return containedZombies;
	}
}