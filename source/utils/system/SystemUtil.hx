package utils.system;

import haxe.io.Path as HxPath;
import sys.io.Process;

class SystemUtil {
	public static function getSysPath(path:String = ""):String {
		return Sys.getEnv(switch (path.toLowerCase()) {
			case "username": #if windows "USERNAME" #else "USER" #end;
			case "userpath": #if windows "USERPROFILE" #else "HOME" #end;
			case "temppath" | _: #if windows "TEMP" #else "HOME" #end;
		});
	}

	public static function getProgramPath():String {
		return HxPath.directory(Sys.programPath()).replace("\\", "/");
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

	public static var isConsoleOn(get, never):Bool;
	public static function get_isConsoleOn():Bool {
		var available:Bool = false;
		try {
			Sys.stdout().writeString('');
			available = true;
		} catch (e:Dynamic) available = false;
		return available;
	}

	/**
	 * Gets laptop battery status and charge level.
	 * @return [charging, percentage]
	 */
	// this is coded horribly. i'm fucking so sorry.
	public static function getBattery():Array<Int> {
		var ret:Array<Int> = [0, -1];

		#if windows
		final wmic_battery:String = "wmic path win32_battery Get";
		try {
			var chargingProc:Process = new Process(wmic_battery + " BatteryStatus");
			var chargingOutput:Array<String> = chargingProc.stdout.readAll().toString().split("\n");
			chargingProc.close();

			if (chargingOutput.length > 1) {
				var val:Int = Std.parseInt(chargingOutput[1].trim());
				if (val == 1 || (val >= 3 && val <= 5) || val == 10) ret[0] = 0;
				else ret[0] = 1;
			}

			var batteryProc:Process = new Process(wmic_battery + " EstimatedChargeRemaining");
			var batteryOutput:Array<String> = batteryProc.stdout.readAll().toString().split("\n");
			batteryProc.close();

			if (batteryOutput.length > 1) ret[1] = Std.parseInt(batteryOutput[1].trim());
		} catch (e:Dynamic) return ret;
		#elseif linux
		final battery_path:String = '/sys/class/power_supply/BAT0/';
		try {
			var chargingProc:Process = new Process("cat", [battery_path + "status"]);
			var chargingOutput:String = chargingProc.stdout.readAll().toString().trim();
			chargingProc.close();

			ret[0] = (chargingOutput == "Charging" ? 1 : 0);

			var batteryProc:Process = new Process("cat", [battery_path + "capacity"]);
			var batteryOutput:String = batteryProc.stdout.readAll().toString().trim();
			batteryProc.close();

			ret[1] = Std.parseInt(batteryOutput);
		} catch (e:Dynamic) return ret;
		#elseif mac
		try {
			var process:Process = new Process("pmset", ["-g", "batt"]);
			var output:Array<String> = process.stdout.readAll().toString().split("\n");
			process.close();

			for (line in output) {
				if (line.indexOf("InternalBattery") != -1) {
					var parts:Array<String> = line.split(";");
					ret[0] = parts[1].indexOf("charging") != -1 ? 1 : 0;
					ret[1] = Std.parseInt(parts[0].split("%")[0].split(" ").pop());
					break;
				}
			}
		} catch (e:Dynamic) return ret;
		#end
		return ret;
	}
}