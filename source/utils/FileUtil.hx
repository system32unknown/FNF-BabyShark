package utils;

import lime.utils.Bytes;
import lime.ui.FileDialog;
import openfl.net.FileFilter;

class FileUtil {
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

	static function convertTypeFilter(typeFilter:Array<FileFilter>):String {
		if (typeFilter != null) return [for (type in typeFilter) type.extension.replace('*.', '').replace(';', ',')].join(';');
		return null;
	}
}