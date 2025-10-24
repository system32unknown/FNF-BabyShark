package utils.system;

class SystemUtil {
	/**
	 * Retrieves a system path based on the given identifier.
	 * 
	 * @param path The identifier for the system path. Can be "username", "userpath", or "temppath".
	 * @return The system path as a string.
	 */
	public static function getSysPath(path:String = ""):String {
		return Sys.getEnv(switch (path.toLowerCase()) {
			case "username": #if windows "USERNAME" #else "USER" #end;
			case "userpath": #if windows "USERPROFILE" #else "HOME" #end;
			case "temppath" | _: #if windows "TEMP" #else "HOME" #end;
		});
	}

	/**
	 * Gets the directory path of the currently running program.
	 * 
	 * @return The program's directory path with forward slashes.
	 */
	public static function getProgramPath():String {
		return haxe.io.Path.directory(Sys.programPath()).replace("\\", "/");
	}

	/**
	 * Retrieves the name of the executable file.
	 * 
	 * @return The executable file name as a string.
	 */
	public static function executableFileName():String {
		var programPath:Array<String> = Sys.programPath().split(#if windows "\\" #else "/" #end);
		return programPath[programPath.length - 1];
	}

	/**
	 * Generates a text file with the specified content and opens it.
	 * 
	 * @param fileContent The content to write to the file.
	 * @param fileName The name of the file (without extension).
	 */
	public static function generateTextFile(fileContent:String, fileName:String) {
		#if desktop
		var path:String = getSysPath() + '/$fileName.txt';
		File.saveContent(path, fileContent);
		Sys.command(#if windows "start " #elseif linux "xdg-open " #else "open " #end + path);
		#end
	}

	/**
	 * Indicates whether the console output is available.
	 */
	public static function isConsoleOn():Bool {
		var available:Bool = false;
		try {
			Sys.stdout().writeString('');
			available = true;
		} catch (e:Dynamic) available = false;
		return available;
	}

	/**
	 * Checks if OBS (Open Broadcaster Software) is currently running on the system.
	 * It runs the "tasklist" command and searches for OBS executables in the process list.
	 *
	 * @return True if any OBS process (obs64.exe, obs32.exe, or obs.exe) is found; otherwise, false.
	 */
	public static function checkForOBS():Bool {
		var tasklists:haxe.io.Bytes = new Process("tasklist").stdout.readAll();
		var tasklist:String = tasklists.getString(0, tasklists.length);
		return tasklist.contains("obs64.exe") || tasklist.contains("obs32.exe") || tasklist.contains("obs.exe");
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