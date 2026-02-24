package backend;

#if sys
class CommandLineHandler {
	public static function parse(args:Array<String>):Void {
		if (args == null || args.length == 0) return;

		for (raw in args) {
			var a:String = raw.trim();
			if (a.length == 0) continue;

			switch (a) {
				case "-h" | "-help" | "help":
					printHelp();
					Sys.exit(0);
				case "-nocolor": Main.noTerminalColor = true;
				case "-v" | "-verbose" | "--verbose": Main.verbose = true;
				default: Sys.println('Unknown command: $a (use -help)');
			}
		}
	}

	static function printHelp():Void {
		Sys.println("-- Alter Engine Command Line help --");
		Sys.println("-help           | Show this help");
		Sys.println("-nocolor        | Disables colors in the terminal");
		Sys.println("-v / -verbose   | Enables verbose logging");
	}
}
#end