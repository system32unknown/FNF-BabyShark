package utils;

import haxe.io.Path;
import lime.utils.Bytes;
import lime.ui.FileDialog;
import openfl.net.FileFilter;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

/**
 * Utilities for reading and writing files on various platforms.
 */
 @:nullSafety
class FileUtil {
	/**
	 * Paths which should not be deleted or modified by scripts.
	 */
	public static var PROTECTED_PATHS(get, never):Array<String>;

	public static function get_PROTECTED_PATHS():Array<String> {
		final protected:Array<String> = [
			'',
			'.',
			'assets',
			'assets/*',
			'backups',
			'backups/*',
			'manifest',
			'manifest/*',
			'plugins',
			'plugins/*',
			'AlterEngine.exe',
			'AlterEngine',
			'icon.ico',
			'libvlc.dll',
			'libvlccore.dll',
			'lime.ndll'
		];

		#if sys
		for (i in 0...protected.length) protected[i] = FileSystem.fullPath(Path.join([gameDirectory, protected[i]]));
		#end
		return protected;
	}

	/**
	 * Regex for invalid filesystem characters.
	 */
	public static final INVALID_CHARS:EReg = ~/[:*?"<>|\n\r\t]/g;

	#if sys
	private static var _gameDirectory:Null<String> = null;
	public static var gameDirectory(get, never):String;

	public static function get_gameDirectory():String {
		if (_gameDirectory != null) return _gameDirectory;
		return _gameDirectory = FileSystem.fullPath(Path.directory(Sys.programPath()));
	}
	#end

	/**
	 * Browses for a directory, then calls `onSelect(path)` when a path chosen.
	 * Note that on HTML5 this will immediately fail.
	 *
	 * @param typeFilter TODO What does this do?
	 * @return Whether the file dialog was opened successfully.
	 */
	public static function browseForDirectory(?typeFilter:Array<FileFilter>, onSelect:(String) -> Void, ?onCancel:() -> Void, ?defaultPath:String, ?dialogTitle:String):Bool {
		#if desktop
		var filter:Null<String> = convertTypeFilter(typeFilter);
		var fileDialog:FileDialog = new FileDialog();
		fileDialog.onSelect.add(onSelect);
		if (onCancel != null) fileDialog.onCancel.add(onCancel);
		fileDialog.browse(OPEN_DIRECTORY, filter, defaultPath, dialogTitle);
		return true;
		#else
		Logs.warn('browseForDirectory not implemented for this platform');
		if (onCancel != null) onCancel();
		return false;
		#end
	}

	/**
	 * Browses for multiple file, then calls `onSelect(paths)` when a path chosen.
	 * Note that on HTML5 this will immediately fail.
	 *
	 * @return Whether the file dialog was opened successfully.
	 */
	public static function browseForMultipleFiles(?typeFilter:Array<FileFilter>, onSelect:(Array<String>) -> Void, ?onCancel:() -> Void, ?defaultPath:String, ?dialogTitle:String):Bool {
		#if desktop
		var filter:Null<String> = convertTypeFilter(typeFilter);
		var fileDialog:FileDialog = new FileDialog();
		fileDialog.onSelectMultiple.add(onSelect);
		if (onCancel != null) fileDialog.onCancel.add(onCancel);
		fileDialog.browse(OPEN_MULTIPLE, filter, defaultPath, dialogTitle);
		return true;
		#else
		Logs.warn('browseForMultipleFiles not implemented for this platform');
		if (onCancel != null) onCancel();
		return false;
		#end
	}

	/**
	 * Browses for a file location to save to, then calls `onSave(path)` when a path chosen.
	 *
	 * @param typeFilter TODO What does this do?
	 * @return Whether the file dialog was opened successfully.
	 */
	public static function browseForSaveFile(?typeFilter:Array<FileFilter>, onSelect:(String)->Void, ?onCancel:()->Void, ?defaultPath:String, ?dialogTitle:String):Bool {
		#if desktop
		var filter:Null<String> = convertTypeFilter(typeFilter);
		var fileDialog:FileDialog = new FileDialog();
		fileDialog.onSelect.add(onSelect);
		if (onCancel != null) fileDialog.onCancel.add(onCancel);
		fileDialog.browse(SAVE, filter, defaultPath, dialogTitle);
		return true;
		#else
		Logs.warn('browseForSaveFile not implemented for this platform');
		if (onCancel != null) onCancel();
		return false;
		#end
	}

	/**
	 * Browses for a single file location, then writes the provided `haxe.io.Bytes` data and calls `onSave(path)` when done.
	 * Works great on only desktop.
	 *
	 * @return Whether the file dialog was opened successfully.
	 */
	public static function saveFile(data:Bytes, ?typeFilter:Array<FileFilter>, onSave:(String)->Void, ?onCancel:()->Void, ?defaultFileName:String, ?dialogTitle:String):Bool {
		#if desktop
		var filter:Null<String> = convertTypeFilter(typeFilter);
		var fileDialog:FileDialog = new FileDialog();
		fileDialog.onSave.add(onSave);
		if (onCancel != null) fileDialog.onCancel.add(onCancel);
		fileDialog.save(data, filter, defaultFileName, dialogTitle);
		return true;
		#else
		Logs.warn('saveFile not implemented for this platform');
		if (onCancel != null) onCancel();
		return false;
		#end
	}

	public static function saveFileRef(content:String, format:String, filedefault:String, save:Bool = true):FileReference {
		var fileRef:FileReference = new FileReference();
		if (save) fileRef.save(content, '$filedefault.$format');
		else fileRef.load();
		return fileRef;
	}

	/**
	 * Prompts the user to save multiple files.
	 * On desktop, this will prompt the user for a directory, then write all of the files to there.
	 *
	 * @param typeFilter TODO What does this do?
	 * @return Whether the file dialog was opened successfully.
	 */
	public static function saveMultipleFiles(resources:Array<haxe.zip.Entry>, ?onSaveAll:(Array<String>)->Void, ?onCancel:()->Void, ?defaultPath:String, force:Bool = false):Bool {
		#if desktop
		// Prompt the user for a directory, then write all of the files to there.
		var onSelectDir:(String) -> Void = (targetPath:String) -> {
			var paths:Array<String> = new Array<String>();
			for (resource in resources) {
				if (resource.data == null) {
					Logs.warn('File ${resource.fileName} has no data or content. Skipping.');
					continue;
				}
				paths.push(Path.join([targetPath, resource.fileName]));
			}
			if (onSaveAll != null) onSaveAll(paths);
		}
		trace('Browsing for directory to save individual files to...');
		#if mac
		defaultPath = null;
		#end
		browseForDirectory(null, onSelectDir, onCancel, defaultPath, 'Choose directory to save all files to...');
		return true;
		#else
		Logs.warn('saveMultipleFiles not implemented for this platform');
		if (onCancel != null) onCancel();
		return false;
		#end
	}

	/**
	 * Read bytes file contents directly from a given path.
	 * Only works on native.
	 *
	 * @param path The path to the file.
	 * @return The file contents.
	 */
	public static function readBytesFromPath(path:String):Bytes {
		#if sys
		return File.getBytes(path);
		#else
		throw 'Direct file reading by path is not supported on this platform.';
		#end
	}

	/**
	 * Browse for a file to read and execute a callback once we have a file reference.
	 * Works great on only desktop.
	 *
	 * @param	callback The function to call when the file is loaded.
	 */
	public static function browseFileReference(callback:(FileReference)->Void):Void {
		var file:FileReference = new FileReference();
		file.addEventListener(Event.SELECT, (e:Event) -> {
			var selectedFileRef:FileReference = e.target;
			trace('Selected file: ' + selectedFileRef.name);
			selectedFileRef.addEventListener(Event.COMPLETE, (e:Event) -> {
				var loadedFileRef:FileReference = e.target;
				trace('Loaded file: ' + loadedFileRef.name);
				callback(loadedFileRef);
			});
			selectedFileRef.load();
		});
		file.browse();
	}

	/**
	 * Prompts the user to save a file to their computer.
	 */
	public static function writeFileReference(path:String, data:String, callback:String->Void):Void {
		var file:FileReference = new FileReference();
		file.addEventListener(Event.COMPLETE, (e:Event) -> {
			trace('Successfully wrote file: "$path"');
			callback("success");
		});
		file.addEventListener(Event.CANCEL, (e:Event) -> {
			trace('Cancelled writing file: "$path"');
			callback("info");
		});
		file.addEventListener(IOErrorEvent.IO_ERROR, (e:IOErrorEvent) -> {
			trace('IO error writing file: "$path"');
			callback("error");
		});
		file.save(data, path);
	}

	/**
	 * Write string file contents directly to a given path.
	 * Only works on native.
	 *
	 * @param path The path to the file.
	 * @param data The string to write.
	 * @param mode Whether to Force, Skip, or Ask to overwrite an existing file.
	 */
	public static function writeStringToPath(path:String, data:String, mode:FileWriteMode = Skip):Void {
		#if sys
		if (FileSystem.isDirectory(path)) throw 'Target path is a directory, not a file: "$path"';
		createDirIfNotExists(Path.directory(path));

		switch (mode) {
			case Force: File.saveContent(path, data);
			case Skip: if (!FileSystem.exists(path)) File.saveContent(path, data);
			case Ask:
				if (FileSystem.exists(path)) {
					// TODO: We don't have the technology to use native popups yet.
					throw 'Entry at path already exists: $path';
				} else File.saveContent(path, data);
		}
		#else
		throw 'Direct file writing by path is not supported on this platform.';
		#end
	}

	/**
	 * Write byte file contents directly to a given path.
	 * Only works on native.
	 *
	 * @param path The path to the file.
	 * @param data The bytes to write.
	 * @param mode Whether to Force, Skip, or Ask to overwrite an existing file.
	 */
	public static function writeBytesToPath(path:String, data:Bytes, mode:FileWriteMode = Skip):Void {
		#if sys
		if (FileSystem.isDirectory(path)) throw 'Target path is a directory, not a file: "$path"';

		var shouldWrite:Bool = true;
		switch (mode) {
			case Force: shouldWrite = true;
			case Skip: if (!FileSystem.exists(path)) shouldWrite = true;
			case Ask:
				if (FileSystem.exists(path)) {
					// TODO: We don't have the technology to use native popups yet.
					throw 'Entry at path already exists: "$path"';
				} else shouldWrite = true;
		}

		if (shouldWrite) {
			createDirIfNotExists(Path.directory(path));
			File.saveBytes(path, data);
		}
		#else
		throw 'Direct file writing by path is not supported on this platform.';
		#end
	}

	/**
	 * Write string file contents directly to the end of a file at the given path.
	 * Only works on native.
	 *
	 * @param path The path to the file.
	 * @param data The string to append.
	 */
	public static function appendStringToPath(path:String, data:String):Void {
		#if sys
		if (!FileSystem.exists(path)) {
			writeStringToPath(path, data, Force);
			return;
		} else if (FileSystem.isDirectory(path)) throw 'Target path is a directory, not a file: "$path"';

		var output:Null<FileOutput> = null;
		try {
			output = File.append(path, false);
			output.writeString(data);
			output.close();
		} catch (e:Dynamic) {
			if (output != null) output.close();
			throw 'Failed to append to file: "$path"';
		}
		#else
		throw 'Direct file writing by path is not supported on this platform.';
		#end
	}

	/**
	 * Create a directory if it doesn't already exist.
	 * Only works on native.
	 *
	 * @param dir The path to the directory.
	 */
	public static function createDirIfNotExists(dir:String):Void {
		if (!FileSystem.isDirectory(dir)) {
			#if sys
			FileSystem.createDirectory(dir);
			#else
			throw 'Directory creation is not supported on this platform.';
			#end
		}
	}
	/**
	 * Get a directory's total size in bytes. Max representable size is ~2.147 GB.
	 * Only works on native.
	 *
	 * @param path The path to the directory.
	 * @return The total size of the directory in bytes.
	 */
	public static function getDirSize(path:String):Int {
		#if sys
		if (!FileSystem.isDirectory(path)) throw 'Path is not a valid directory path: $path';

		var stack:Array<String> = [path];
		var total:Int = 0;
		while (stack.length > 0) {
			var currentPath:Null<String> = stack.pop();
			if (currentPath == null) continue;

			for (entry in FileSystem.readDirectory(currentPath)) {
				var entryPath:String = Path.join([currentPath, entry]);
				if (FileSystem.isDirectory(entryPath)) stack.push(entryPath);
				else total += FileSystem.stat(entryPath).size;
			}
		}

		return total;
		#else
		throw 'Directory size calculation not supported on this platform.';
		#end
	}

	static var tempDir:Null<String> = null;
	/**
	 * Get the path to a temporary directory we can use for writing files.
	 * Only works on native.
	 *
	 * @return The path to the temporary directory.
	 */
	public static function getTempDir():Null<String> {
		if (tempDir != null) return tempDir;
		#if sys
		#if windows
		var path:Null<String> = null;
		for (envName in ['TEMP', 'TMPDIR', 'TEMPDIR', 'TMP']) {
			path = Sys.getEnv(envName);
			if (path == '') path = null;
			if (path != null) break;
		}
		tempDir = Path.join([path ?? '', 'funkin/']);
		return tempDir;
		#else
		tempDir = '/tmp/funkin/';
		return tempDir;
		#end
		#else
		return null;
		#end
	}


	/**
	 * Runs platform-specific code to open a path in the file explorer.
	 *
	 * @param pathFolder The path of the folder to open.
	 * @param createIfNotExists If `true`, creates the folder if missing; otherwise, throws an error.
	 */
	public static function openFolder(pathFolder:String, createIfNotExists:Bool = true):Void {
		#if sys
		pathFolder = pathFolder.trim();
		if (createIfNotExists) {
			createDirIfNotExists(pathFolder);
		} else if (!FileSystem.isDirectory(pathFolder)) throw 'Path is not a directory: "$pathFolder"';

		#if windows
		Sys.command('explorer', [pathFolder.replace('/', '\\')]);
		#elseif mac
		// mac could be fuckie with where the log folder is relative to the game file...
		// if this comment is still here... it means it has NOT been verified on mac yet!
		//
		// FileUtil.hx note: this was originally used to open the logs specifically!
		// thats why the above comment is there!
		Sys.command('open', [pathFolder]);
		#elseif linux
		// TODO: implement linux
		// some shit with xdg-open :thinking: emoji...
		#end
		#else
		throw 'External folder open is not supported on this platform.';
		#end
	}

	/**
	 * Runs platform-specific code to open a file explorer and select a specific file.
	 *
	 * @param path The path of the file to select.
	 */
	public static function openSelectFile(path:String):Void {
		#if sys
		path = path.trim();
		if (!FileSystem.exists(path)) throw 'Path does not exist: "$path"';
		#if windows
		Sys.command('explorer', ['/select,', path.replace('/', '\\')]);
		#elseif mac
		Sys.command('open', ['-R', path]);
		#elseif linux
		// TODO: unsure of the linux equivalent to opening a folder and then "selecting" a file.
		Sys.command('open', [path]);
		#end
		#else
		throw 'External file selection is not supported on this platform.';
		#end
	}

	public static function convertTypeFilter(?typeFilter:Array<FileFilter>):Null<String> {
		var filter:Null<String> = null;
		if (typeFilter != null) {
			var filters:Array<String> = new Array<String>();
			for (type in typeFilter) filters.push(type.extension.replace('*.', '').replace(';', ','));
			filter = filters.join(';');
		}
		return filter;
	}
}

/**
 * Utilities for reading and writing files on various platforms.
 * Wrapper for `FileUtil` that sanitizes paths for script safety.
 */
@:nullSafety
class FileUtilSandboxed {
	/**
	 * Prevent paths from exiting the root.
	 *
	 * @param path The path to sanitize.
	 * @return The sanitized path.
	 */
	public static function sanitizePath(path:String):String {
		path = (path ?? '').trim();
		if (path == '') return #if sys FileUtil.gameDirectory #else '' #end;

		if (path.contains(':')) path = path.substring(path.lastIndexOf(':') + 1);
		path = path.replace('\\', '/');
		while (path.contains('//')) path = path.replace('//', '/');

		final parts:Array<String> = FileUtil.INVALID_CHARS.replace(path, '').split('/');
		final sanitized:Array<String> = new Array<String>();
		for (part in parts) {
			switch (part) {
				case '.' | '': continue;
				case '..': sanitized.pop();
				default: sanitized.push(part.trim());
			}
		}

		if (sanitized.length == 0) return #if sys FileUtil.gameDirectory #else '' #end;

		#if sys
		// TODO: figure out how to get "real" path of symlinked paths
		final realPath:String = FileSystem.fullPath(Path.join([FileUtil.gameDirectory, sanitized.join('/')]));
		if (!realPath.startsWith(FileUtil.gameDirectory)) return FileUtil.gameDirectory;
		return realPath;
		#else
		return sanitized.join('/');
		#end
	}

	/**
	 * Check against protected paths.
	 * @param path The path to check.
	 * @return Whether the path is protected.
	 */
	public static function isProtected(path:String, sanitizeFirst:Bool = true):Bool {
		if (sanitizeFirst) path = sanitizePath(path);
		@:privateAccess for (protected in FileUtil.PROTECTED_PATHS) {
			if (path == protected || (protected.contains('*') && path.startsWith(protected.substring(0, protected.indexOf('*'))))) {
				return true;
			}
		}
		return false;
	}

	public static function readBytesFromPath(path:String):Bytes {
		return FileUtil.readBytesFromPath(sanitizePath(path));
	}
	public static function writeStringToPath(path:String, data:String, mode:FileWriteMode = Skip):Void {
		if (isProtected(path = sanitizePath(path), false)) throw 'Cannot write to protected path: $path';
		FileUtil.writeStringToPath(path, data, mode);
	}
	public static function writeBytesToPath(path:String, data:Bytes, mode:FileWriteMode = Skip):Void {
		if (isProtected(path = sanitizePath(path), false)) throw 'Cannot write to protected path: $path';
		FileUtil.writeBytesToPath(path, data, mode);
	}
	public static function appendStringToPath(path:String, data:String):Void {
		if (isProtected(path = sanitizePath(path), false)) throw 'Cannot write to protected path: $path';
		FileUtil.appendStringToPath(path, data);
	}
	public static function getDirSize(path:String):Int {
		return FileUtil.getDirSize(sanitizePath(path));
	}
	public static function createDirIfNotExists(dir:String):Void {
		FileUtil.createDirIfNotExists(sanitizePath(dir));
	}
	public static function openFolder(pathFolder:String, createIfNotExists:Bool = true):Void {
		FileUtil.openFolder(sanitizePath(pathFolder), createIfNotExists);
	}
	public static function openSelectFile(path:String):Void {
		FileUtil.openSelectFile(sanitizePath(path));
	}
}

enum FileWriteMode {
	/**
	 * Forcibly overwrite the file if it already exists.
	 */
	Force;

	/**
	 * Ask the user if they want to overwrite the file if it already exists.
	 */
	Ask;

	/**
	 * Skip the file if it already exists.
	 */
	Skip;
}