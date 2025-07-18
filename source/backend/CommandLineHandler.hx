package backend;

#if sys
class CommandLineHandler {
	public static function parse(args:Array<String>) {
		for (arg in args) {
			switch (arg) {
				case "-h" | "-help" | "help":
					Sys.println("-- Alter Engine Command Line help --");
					Sys.println("-help				| Show this help");
					Sys.println("-nocolor			| Disables colors in the terminal");
					Sys.exit(0);
				case "-nocolor": Main.noTerminalColor = true;
				case "-terminal": FlxG.switchState(() -> new states.TerminalState());
				case "-v" | "-verbose" | "--verbose": Main.verbose = true;
				default: Sys.println('Unknown argument command (${args[1]})');
			}
		}
	}
}
#end