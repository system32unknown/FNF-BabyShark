package macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.io.Path;
import sys.FileSystem;

/**
 * This class provides a macro to include an XML build file in the metadata of a Haxe class.
 *
 * The file must be located relative to the directory of the Haxe class that uses this macro.
 */
@:nullSafety
class LinkerMacro {
	/**
	 * Adds an XML `<include>` element to the class's metadata, pointing to a specified build file.
	 * @param fileName The name of the XML file to include. Defaults to `Build.xml` if not provided.
	 * @return An array of fields that are processed during the build.
	 */
	public static macro function xml(?fileName:String = 'Build.xml'):Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		final cls:haxe.macro.Type.ClassType = Context.getLocalClass().get();
		final pos:Position = Context.currentPos();

		final sourcePath:String = Path.directory(Context.getPosInfos(pos).file);
		final absSourcePath:String = Path.removeTrailingSlashes(FileSystem.absolutePath(sourcePath));
		final fileToInclude:String = Path.join([absSourcePath, fileName?.length > 0 ? fileName : 'Build.xml']);

		if (!FileSystem.exists(fileToInclude)) Context.error('The specified file "$fileToInclude" could not be found at "$absSourcePath".', pos);

		final includeElement:Xml = Xml.createElement('include');
		includeElement.set('name', fileToInclude);

		cls.meta.add(':buildXml', [{
			expr: EConst(CString(haxe.xml.Printer.print(includeElement, true))),
			pos: pos
		}], pos);

		return fields;
	}
}
