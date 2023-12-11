package utils.system;

class SystemUtil {
	public static function getSysPath(path:String = ""):String {
		return Sys.getEnv(switch (path.toLowerCase()) {
			case "username": #if windows "USERNAME" #else "USER" #end;
			case "userpath": #if windows "USERPROFILE" #else "HOME" #end;
			case "temppath" | _: #if windows "TEMP" #else "HOME" #end;
		});
	}

	public static function executableFileName() {
		var programPath = Sys.programPath().split(#if windows "\\" #else "/" #end);
		return programPath[programPath.length - 1];
	}
	public static function generateTextFile(fileContent:String, fileName:String) {
		#if desktop
		var path = '${getSysPath()}/$fileName.txt';
		File.saveContent(path, fileContent);
		Sys.command(#if windows "start " #elseif linux "xdg-open " #else "open " #end + path);
		#end
	}
}