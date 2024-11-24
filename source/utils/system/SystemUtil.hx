package utils.system;

import sys.io.Process;

class SystemUtil {
	public static function getSysPath(path:String = ""):String {
		return Sys.getEnv(switch (path.toLowerCase()) {
			case "username": #if windows "USERNAME" #else "USER" #end;
			case "userpath": #if windows "USERPROFILE" #else "HOME" #end;
			case "temppath" | _: #if windows "TEMP" #else "HOME" #end;
		});
	}

	public static function executableFileName():String {
		var programPath:Array<String> = Sys.programPath().split(#if windows "\\" #else "/" #end);
		return programPath[programPath.length - 1];
	}
	public static function generateTextFile(fileContent:String, fileName:String) {
		#if desktop
		var path:String = '${getSysPath()}/$fileName.txt';
		File.saveContent(path, fileContent);
		Sys.command(#if windows "start " #elseif linux "xdg-open " #else "open " #end + path);
		#end
	}

	/**
	 * Gets Current Battery (Laptop Only).
	 * @return Array of Battery [0: Charging, 1: Remaining Battery].
	**/
	public static function getBattery():Array<Int> {
		final wmic_battery:String = "wmic path win32_battery Get";
		var charging:Process = new Process(wmic_battery + " BatteryStatus");
		var ret:Array<Int> = [0, -1];

		if (charging.stderr.readAll().toString().split("\n")[0] != "") return ret;
		var val:Int = Std.parseInt(charging.stdout.readAll().toString().split("\n")[1]);
		if (val == 1 || (val >= 3 && val <= 5) || val == 10) ret[0] = 0;
		else ret[0] = 1;

		var battery:Int = Std.parseInt(new Process(wmic_battery + " EstimatedChargeRemaining").stdout.readAll().toString().split("\n")[1]);
		ret[1] = battery;
		return ret;
	}
}