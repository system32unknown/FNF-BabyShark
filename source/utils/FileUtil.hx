package utils;

import haxe.zip.Entry;
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
class FileUtil {

	/**
	 * Browses for a single file location, then writes the provided `haxe.io.Bytes` data and calls `onSave(path)` when done.
	 *
	 * @return Whether the file dialog was opened successfully.
	 */
	public static function saveFile(data:Bytes, ?typeFilter:Array<FileFilter>, ?onSave:String->Void, ?onCancel:Void->Void, ?defaultFileName:String, ?dialogTitle:String):Bool {
		#if desktop
		var fileDialog:FileDialog = new FileDialog();
		if (onSave != null) fileDialog.onSave.add(onSave);
		if (onCancel != null) fileDialog.onCancel.add(onCancel);
		fileDialog.save(data, convertTypeFilter(typeFilter), defaultFileName, dialogTitle);
		return true;
		#else
		onCancel();
		return false;
		#end
	}

	public static function saveFileRef(content:String, format:String, filedefault:String, save:Bool = true) {
		var fileRef:FileReference = new FileReference();
		if (save) fileRef.save(content, '$filedefault.$format');
		else fileRef.load();
	}

	/**
	 * Browses for a file location to save to, then calls `onSave(path)` when a path chosen.
	 *
	 * @param typeFilter TODO What does this do?
	 * @return Whether the file dialog was opened successfully.
	 */
	public static function browseForSaveFile(?typeFilter:Array<FileFilter>, ?onSelect:String->Void, ?onCancel:Void->Void, ?defaultPath:String, ?dialogTitle:String):Bool {
		#if desktop
		var fileDialog:FileDialog = new FileDialog();
		if (onSelect != null) fileDialog.onSelect.add(onSelect);
		if (onCancel != null) fileDialog.onCancel.add(onCancel);
		fileDialog.browse(SAVE, convertTypeFilter(typeFilter), defaultPath, dialogTitle);
		return true;
		#else
		onCancel();
		return false;
		#end
	}

	/**
	 * Browses for multiple file, then calls `onSelect(paths)` when a path chosen.
	 *
	 * @return Whether the file dialog was opened successfully.
	 */
	public static function browseForMultipleFiles(?typeFilter:Array<FileFilter>, ?onSelect:Array<String>->Void, ?onCancel:Void->Void, ?defaultPath:String, ?dialogTitle:String):Bool {
		#if desktop
		var fileDialog:FileDialog = new FileDialog();
		if (onSelect != null) fileDialog.onSelectMultiple.add(onSelect);
		if (onCancel != null) fileDialog.onCancel.add(onCancel);
		fileDialog.browse(OPEN_MULTIPLE, convertTypeFilter(typeFilter), defaultPath, dialogTitle);
		return true;
		#else
		onCancel();
		return false;
		#end
	}

	/**
	 * Browses for a directory, then calls `onSelect(path)` when a path chosen.
	 *
	 * @param typeFilter TODO What does this do?
	 * @return Whether the file dialog was opened successfully.
	 */
	public static function browseForDirectory(?typeFilter:Array<FileFilter>, ?onSelect:String->Void, ?onCancel:Void->Void, ?defaultPath:String, ?dialogTitle:String):Bool {
		#if desktop
		var fileDialog:FileDialog = new FileDialog();
		if (onSelect != null) fileDialog.onSelect.add(onSelect);
		if (onCancel != null) fileDialog.onCancel.add(onCancel);
		fileDialog.browse(OPEN_DIRECTORY, convertTypeFilter(typeFilter), defaultPath, dialogTitle);
		return true;
		#else
		onCancel();
		return false;
		#end
	}

	/**
	 * Prompts the user to save multiple files.
	 * On desktop, this will prompt the user for a directory, then write all of the files to there.
	 *
	 * @param typeFilter TODO What does this do?
	 * @return Whether the file dialog was opened successfully.
	 */
	public static function saveMultipleFiles(resources:Array<Entry>, ?onSaveAll:Array<String>->Void, ?onCancel:Void->Void, ?defaultPath:String, force:Bool = false):Bool {
		#if desktop
		// Prompt the user for a directory, then write all of the files to there.
		var onSelectDir:String->Void = (targetPath:String) -> {
			var paths:Array<String> = [];
			for (resource in resources) {
				var filePath = haxe.io.Path.join([targetPath, resource.fileName]);
				try {
					if (resource.data == null) {
						trace('WARNING: File $filePath has no data or content. Skipping.');
						continue;
					} else writeBytesToPath(filePath, resource.data, force ? Force : Skip);
				} catch (_) throw 'Failed to write file (probably already exists): $filePath';
				paths.push(filePath);
			}
			onSaveAll(paths);
		}
		trace('Browsing for directory to save individual files to...');
		#if mac
		defaultPath = null;
		#end
		browseForDirectory(null, onSelectDir, onCancel, defaultPath, 'Choose directory to save all files to...');
		return true;
		#else
		onCancel();
		return false;
		#end
	}

	/**
	 * Takes an array of file entries and forcibly writes a ZIP to the given path.
	 * Only works on desktop.
	 * Use `saveFilesAsZIP` instead.
	 * @param force Whether to force overwrite an existing file.
	 */
	public static function saveFilesAsZIPToPath(resources:Array<Entry>, path:String, mode:FileWriteMode = Skip):Bool {
		#if desktop
		// Create a ZIP file.
		var zipBytes:Bytes = createZIPFromEntries(resources);
		// Write the ZIP.
		writeBytesToPath(path, zipBytes, mode);
		return true;
		#else
		return false;
		#end
	}

	/**
	 * Read bytes file contents directly from a given path.
	 * Only works on desktop.
	 *
	 * @param path The path to the file.
	 * @return The file contents.
	 */
	public static function readBytesFromPath(path:String):Bytes {
		#if sys
		if (!FileSystem.exists(path)) return null;
		return File.getBytes(path);
		#else
		return null;
		#end
	}

	/**
	 * Browse for a file to read and execute a callback once we have a file reference.
	 * Works great on desktop.
	 *
	 * @param	callback The function to call when the file is loaded.
	 */
	public static function browseFileReference(callback:FileReference->Void) {
		var file:FileReference = new FileReference();
		file.addEventListener(Event.SELECT, function(e) {
			var selectedFileRef:FileReference = e.target;
			trace('Selected file: ' + selectedFileRef.name);
			selectedFileRef.addEventListener(Event.COMPLETE, function(e) {
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
	public static function writeFileReference(path:String, data:String) {
		var file:FileReference = new FileReference();
		file.addEventListener(Event.COMPLETE, (e:Event) -> trace('Successfully wrote file.'));
		file.addEventListener(Event.CANCEL, (e:Event) -> trace('Cancelled writing file.'));
		file.addEventListener(IOErrorEvent.IO_ERROR, (e:IOErrorEvent) -> trace('IO error writing file.'));
		file.save(data, path);
	}

	/**
	 * Write string file contents directly to a given path.
	 * Only works on desktop.
	 *
	 * @param path The path to the file.
	 * @param data The string to write.
	 * @param mode Whether to Force, Skip, or Ask to overwrite an existing file.
	 */
	public static function writeStringToPath(path:String, data:String, mode:FileWriteMode = Skip):Void {
		#if sys
		createDirIfNotExists(Path.directory(path));
		switch (mode) {
			case Force: File.saveContent(path, data);
			case Skip: if (!FileSystem.exists(path)) File.saveContent(path, data);
			case Ask:
				if (FileSystem.exists(path)) throw 'File already exists: $path'; // TODO: We don't have the technology to use native popups yet.
				else File.saveContent(path, data);
		}
		#else
		throw 'Direct file writing by path not supported on this platform.';
		#end
	}

	/**
	 * Write byte file contents directly to a given path.
	 * Only works on desktop.
	 *
	 * @param path The path to the file.
	 * @param data The bytes to write.
	 * @param mode Whether to Force, Skip, or Ask to overwrite an existing file.
	 */
	public static function writeBytesToPath(path:String, data:Bytes, mode:FileWriteMode = Skip):Void {
		#if sys
		createDirIfNotExists(Path.directory(path));
		switch (mode) {
			case Force: File.saveBytes(path, data);
			case Skip: if (!FileSystem.exists(path)) File.saveBytes(path, data);
			case Ask:
				if (FileSystem.exists(path)) throw 'File already exists: $path'; // TODO: We don't have the technology to use native popups yet.
				else File.saveBytes(path, data);
		}
		#else
		throw 'Direct file writing by path not supported on this platform.';
		#end
	}

	/**
	 * Write string file contents directly to the end of a file at the given path.
	 * Only works on desktop.
	 *
	 * @param path The path to the file.
	 * @param data The string to append.
	 */
	public static function appendStringToPath(path:String, data:String):Void {
		#if sys
		File.append(path, false).writeString(data);
		#else
		throw 'Direct file writing by path not supported on this platform.';
		#end
	}

	/**
	 * Create a directory if it doesn't already exist.
	 * Only works on desktop.
	 *
	 * @param dir The path to the directory.
	 */
	public static function createDirIfNotExists(dir:String):Void {
		#if sys
		if (!FileSystem.exists(dir)) sys.FileSystem.createDirectory(dir);
		#end
	}

	static var tempDir:String = null;
	static final TEMP_ENV_VARS:Array<String> = ['TEMP', 'TMPDIR', 'TEMPDIR', 'TMP'];

	/**
	 * Get the path to a temporary directory we can use for writing files.
	 * Only works on desktop.
	 *
	 * @return The path to the temporary directory.
	 */
	public static function getTempDir():String {
		if (tempDir != null)
			return tempDir;
		#if sys
		#if windows
		var path:String = null;
		for (envName in TEMP_ENV_VARS) {
			path = Sys.getEnv(envName);
			if (path == '') path = null;
			if (path != null) break;
		}
		tempDir = Path.join([path, 'funkin/']);
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
	 * Create a Bytes object containing a ZIP file, containing the provided entries.
	 *
	 * @param entries The entries to add to the ZIP file.
	 * @return The ZIP file as a Bytes object.
	 */
	public static function createZIPFromEntries(entries:Array<Entry>):Bytes {
		var o:haxe.io.BytesOutput = new haxe.io.BytesOutput();
		var zipWriter:haxe.zip.Writer = new haxe.zip.Writer(o);
		zipWriter.write(Lambda.list(entries));
		return o.getBytes();
	}

	public static function readZIPFromBytes(input:Bytes):Array<Entry> {
		var bytesInput = new haxe.io.BytesInput(input);
		var zippedEntries = haxe.zip.Reader.readZip(bytesInput);
		var results:Array<Entry> = [];
		for (entry in zippedEntries) {
			if (entry.compressed) entry.data = haxe.zip.Reader.unzip(entry);
			results.push(entry);
		}
		return results;
	}

	public static function mapZIPEntriesByName(input:Array<Entry>):Map<String, Entry> {
		var results:Map<String, Entry> = [];
		for (entry in input) results.set(entry.fileName, entry);
		return results;
	}

	/**
	 * Create a ZIP file entry from a file name and its string contents.
	 *
	 * @param name The name of the file. You can use slashes to create subdirectories.
	 * @param content The string contents of the file.
	 * @return The resulting entry.
	 */
	public static function makeZIPEntry(name:String, content:String):Entry {
		var data:Bytes = haxe.io.Bytes.ofString(content, UTF8);
		return makeZIPEntryFromBytes(name, data);
	}

	/**
	 * Create a ZIP file entry from a file name and its string contents.
	 *
	 * @param name The name of the file. You can use slashes to create subdirectories.
	 * @param data The byte data of the file.
	 * @return The resulting entry.
	 */
	public static function makeZIPEntryFromBytes(name:String, data:haxe.io.Bytes):Entry {
		return {
			fileName: name,
			fileSize: data.length,
			data: data,
			dataSize: data.length,
			compressed: false,
			fileTime: Date.now(),
			crc32: null,
			extraFields: null,
		};
	}

	static function convertTypeFilter(typeFilter:Array<FileFilter>):String {
		if (typeFilter != null) return [for (type in typeFilter) type.extension.replace('*.', '').replace(';', ',')].join(';');
		return null;
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