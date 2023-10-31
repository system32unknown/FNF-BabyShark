package utils.system;

class SystemUtil {
	public static function getUsername():String return Sys.getEnv(#if windows "USERNAME" #else "USER" #end);
	public static function getUserPath():String return Sys.getEnv(#if windows "USERPROFILE" #else "HOME" #end);
	public static function getTempPath():String return Sys.getEnv(#if windows "TEMP" #else "HOME" #end);

	public static function executableFileName() {
		var programPath = Sys.programPath().split(#if windows "\\" #else "/" #end);
		return programPath[programPath.length - 1];
	}
	public static function generateTextFile(fileContent:String, fileName:String) {
		#if desktop
		var path = '${getTempPath()}/$fileName.txt';
		File.saveContent(path, fileContent);
		Sys.command(#if windows "start " #elseif linux "xdg-open " #else "open " #end + path);
		#end
	}
}