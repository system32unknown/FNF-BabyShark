package utils.system;

// lordryan wrote this :) (erizur added cross platform env vars)
import sys.io.File;

class SystemUtil {
	public static function getUsername():String {
		return Sys.getEnv(#if windows "USERNAME" #else "USER" #end);
	}
	public static function getUserPath():String {
		return Sys.getEnv(#if windows "USERPROFILE" #else "HOME" #end);
	}
	public static function getTempPath():String {
		return Sys.getEnv(#if windows "TEMP" #else "HOME" #end);
	}

	public static function executableFileName() {
		var programPath = Sys.programPath().split(#if windows "\\" #else "/" #end);
		return programPath[programPath.length - 1];
	}
	public static function generateTextFile(fileContent:String, fileName:String) {
		#if desktop
		var path = '${getTempPath()}/$fileName.txt';

		File.saveContent(path, fileContent);
		#if windows
		Sys.command("start " + path);
		#elseif linux
		Sys.command("xdg-open " + path);
		#else
		Sys.command("open " + path);
		#end
		#end
	}
}