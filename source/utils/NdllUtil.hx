package utils;

import lime.utils.Assets;

/**
 * Small util that allows you to load any function from ndlls via `getFunction`.
 *
 * NDLLs must be in your mod's "data/ndlls" folder, and must follow this name scheme:
 * - `name.ndll` for Windows targeted ndlls
 *
 * If:
 * - The NDLL is not found
 * - The Function cannot be found in the NDLL
 * then an empty function will be returned instead, and a message will be shown in logs.
 * Ported to Alter Engine.
 * @author Codename Engine Team, Altertoriel
 */
class NdllUtil {
	/**
	 * Returns an function from a Haxe NDLL.
	 * Limited to 25 argument due to a limitation
	 *
	 * @param ndll Name of the NDLL.
	 * @param name Name of the function.
	 * @param args Number of arguments of that function.
	 */
	public static function getFunction(ndll:String, name:String, args:Int):Dynamic {
		var path:String;
		#if MODS_ALLOWED
		path = Paths.modsNdll(ndll);
		if(!FileSystem.exists(path))
		#end
			path = Paths.ndll(ndll);

		#if NDLLS_SUPPORTED
		var func:Dynamic = getFunctionFromPath(path, name, args);
		return Reflect.makeVarArgs((a:Array<Dynamic>) -> return macros.ReflectMacro.generateReflectionLike(25, "func", "a"));
		#else
		Logs.trace('NDLLs are not supported on this platform.', WARNING);
		return noop;
		#end
	}

	/**
	 * Returns an function from a Haxe NDLL at specified path.
	 *
	 * @param ndll Asset path to the NDLL.
	 * @param name Name of the function.
	 * @param args Number of arguments of that function.
	 */
	public static function getFunctionFromPath(ndll:String, name:String, args:Int):Dynamic {
		#if NDLLS_SUPPORTED
		if (!#if MODS_ALLOWED FileSystem #else Assets #end.exists(ndll)) {
			Logs.trace('Couldn\'t find ndll at ${ndll}.', WARNING);
			return noop;
		}
		var func = lime.system.CFFI.load(ndll, name, args);
		if (func == null) {
			Logs.trace('Method ${name} in ndll ${ndll} with ${args} args was not found.', ERROR);
			return noop;
		}
		return func;
		#else Logs.trace('NDLLs are not supported on this platform.', WARNING); #end
		return noop;
	}

	@:noCompletion static function noop() {}
}