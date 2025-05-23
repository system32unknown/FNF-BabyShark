package commands;

class Compiler {
	public static function release(args:Array<String>) {
		__build(args, ["build", getBuildTarget()]);
	}
	public static function testRelease(args:Array<String>) {
		__build(args, ["test", getBuildTarget()]);
	}

	static function __build(args:Array<String>, arg:Array<String>) {
		for (a in args) arg.push(a);
		var errorlevel:Int = Sys.command("lime", arg);
		if (errorlevel == 1) trace("Failed Compiling Game!");
		else trace("Compiling Game Done!");
	}

	public static function getBuildTarget():String {
		return switch (Sys.systemName()) {
			case "Windows": "windows";
			case "Mac": "macos";
			case "Linux": "linux";
			case def: def.toLowerCase();
		}
	}
}