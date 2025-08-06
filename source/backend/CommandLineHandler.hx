package backend;

#if sys
class CommandLineHandler {
	public static function parse(cmd:Array<String>) {
		var i:Int = 0;
		while (i < cmd.length) {
			switch (cmd[i]) {
				case null: break;
				case "-h" | "-help" | "help":
					Sys.println("-- Alter Engine Command Line help --");
					Sys.println("-help				| Show this help");
					Sys.println("-nocolor			| Disables colors in the terminal");
					Sys.exit(0);
				case "-nocolor": Main.noTerminalColor = true;
				case "-v" | "-verbose" | "--verbose": Main.verbose = true;
				default: Sys.println('Unknown command');
			}
			i++;
		}
	}
}
#end