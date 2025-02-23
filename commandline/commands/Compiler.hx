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
		Sys.command("lime", arg);
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