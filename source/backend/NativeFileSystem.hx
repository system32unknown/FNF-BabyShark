package backend;

import haxe.io.Path;
import openfl.media.Sound;
import openfl.display.BitmapData;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;

/**
	**Works only on paths relative to game's root dorectory*

	Basically NativeFileSystem, but we can emulate it on OpenFL.
	It can either 
**/
class NativeFileSystem {
	public static var openFlAssets:Array<String> = null;

	public static function getContent(path:String):Null<String> {
		if (!path.startsWith("mods")) return openFlAssets.contains(path) ? Assets.getText(path) : null;

		var sysPath:String = getPathLike(path);
		if (sysPath != null && FileSystem.exists(sysPath)) return File.getContent(sysPath);

		Logs.warn("Text file doesn't exist: " + path);
		return null;
	}

	// Loads a given bitmap. Returns null if it doesn't exist
	public static function getBitmap(path:String):Null<BitmapData> {
		return openFlAssets.contains(path) ? OpenFlAssets.getBitmapData(path) : null;

		var sysPath:String = getPathLike(path);
		return sysPath != null ? BitmapData.fromFile(sysPath) : null;
	}

	public static function getSound(path:String):Null<Sound> {
		return openFlAssets.contains(path) ? OpenFlAssets.getSound(path) : null;

		var sysPath:String = getPathLike(path);
		return sysPath != null ? Sound.fromFile(sysPath) : null;
	}

	// Check if the file exists
	public static function exists(path:String) {
		if (!path.startsWith("mods")) {
			if (openFlAssets.contains(path)) return true;

			// treat folders as existing if anything is under them
			var prefix:String = path.endsWith("/") ? path : path + "/";
			for (asset in openFlAssets) if (asset.startsWith(prefix)) return true;
			return false;
		}

		return getPathLike(path) != null;
	}

	/**
	 * Adds the current root dir to the path.
	 * Depends a lot on the target system!
	 */
	static function addCwd(path:String):String {
		#if desktop
		return path;
		#else
		var cwd:String = Sys.getCwd();
		var test_cwd:String = Path.removeTrailingSlashes(cwd);
		if (path.startsWith(test_cwd)) return path;
		return Path.addTrailingSlash(cwd) + path;
		#end
	}

	#if linux
	/**
		A local cache for non existent directories.
		Make sure to clean it regularly in case user adds a missing file(s)
	 */
	public static final excludePaths:Array<String> = [];

	/**
	 * Returns a path to the existing file similar to the given one.
	 * (For instance "mod/firelight" and "Mod/FireLight" are *similar* paths)
	 * @param path The path to find
	 * @return Null<String> Found path or null if such doesn't exist
	 */
	public static function getPathLike(path:String):Null<String> {
		var path:String = addCwd(path); // fix ios
		var dir:String = Path.directory(path);

		for (exclude in excludePaths) {
			if (dir.startsWith(exclude)) return null;
		}
		if (FileSystem.exists(path)) return path;

		var parts:Array<String> = path.replace('\\', '/').split('/');
		var keys:Array<String> = [];

		while (parts.length > 0 && !FileSystem.exists(parts.join("/")))
			keys.unshift(parts.pop());

		return parts.length > 0 ? findFile(parts.join("/"), keys) : null;
	}

	static function findFile(base_path:String, keys:Array<String>):Null<String> {
		var nextDir:String = base_path;
		for (part in keys) {
			if (part == '') continue;

			var foundNode:String = findNode(nextDir, part);
			if (foundNode == null) {
				excludePaths.push(nextDir + "/" + part);
				return null;
			}
			nextDir += "/" + foundNode;
		}
		return nextDir;
	}

	/**
	 * Searches a given directory and returns a name of the existing file/directory
	 * *similar* to the **key**
	 * @param dir Base directory to search
	 * @param key The file/directory you want to find
	 * @return Either a file name, or null if the one doesn't exist
	 */
	static function findNode(dir:String, key:String):Null<String> {
		try {
			for (file in FileSystem.readDirectory(dir)) {
				if (file.toLowerCase() == key.toLowerCase()) {
					return file;
				}
			}
		} catch (e:Dynamic) Logs.error('ERROR FINDING NODE: $e');

		return null;
	}

	#elseif sys
	/**
	 * Returns a path to the existing file similar to the given one.
	 * (For instance "mod/firelight" and  "Mod/FireLight" are *similar* paths)
	 * @param path
	 * @return Null<String>
	 */
	public static function getPathLike(path:String):Null<String> {
		var fullPath:String = addCwd(path);
		return FileSystem.exists(fullPath) ? fullPath : null;
	}
	#end
}
