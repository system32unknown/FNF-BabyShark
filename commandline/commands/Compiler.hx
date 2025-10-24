package commands;

class Compiler {
	public static function test(args:Array<String>) {
		__runLime(args, ["test", getBuildTarget()]);
	}
	public static function build(args:Array<String>) {
		__runLime(args, ["build", getBuildTarget()]);
	}

	public static function run(args:Array<String>) {
		__runLime(args, ["run", getBuildTarget()]);
	}

	static function __runLime(args:Array<String>, arg:Array<String>) {
		arg.insert(0, "lime");
		arg.insert(0, "run");
		for (a in args) arg.push(a);

		var errorlevel:Int = Sys.command("haxelib", arg);
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