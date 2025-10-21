package;

import commands.*;

class Main {
	public static var commands:Array<Command> = [];

	public static var curCommand:Command;

	public static function initCommands() {
		commands = [
			{
				names: ["setup"],
				doc: "Setups (or updates) all libraries required for the engine.",
				func: Setup.main,
				dDoc: [
					"Usage: setup",
					"",
					"This command runs through all libraries in libs.xml, and install them.",
					"If they're already installed, they will be updated.",
					"",
					"--all : Reinstall all libraries.",
					"-s | --silent | --silent-progress : Don't show download progress."
				].join("\n")
			}, {
				names: ["help", null],
				doc: "Shows help. Pass a command name to get additional help.",
				func: help,
				dDoc: [
					"Usage: help <cmd>",
					"",
					"For example, use \"cne help test\" to get additional help on the test command."
				].join("\n")
			}, {
				names: ["test"],
				doc: "Creates a non final test build, then runs it.",
				func: Compiler.test,
				dDoc: [
					"Usage: test <optional args>",
					"",
					"This will create a quick debug build connected to the source then run it, which means:",
					"- The assets WON'T be copied over - Assets will be read from the game's source.",
					"- This build WON'T be ready for release - Running anywhere else than in the bin folder will result in a crash from missing assets",
					"- This build will also use the mods folder from the source directory.",
					"",
					"If you want a full build which contains all assets, run \"cne release\" or \"cne test-release\"",
					"Additional arguments will be sent to the lime compiler.",
					"",
					"-debug : Builds a debug build.",
					"-clean : Compiled files will be deleted before compiling."
				].join("\n")
			}, {
				names: ["build"],
				doc: "Creates a non final test build, without running it.",
				func: Compiler.build,
				dDoc: [
					"Usage: build <optional arguments>",
					"",
					"This will create a quick debug build connected to the source then run it, which means:",
					"- The assets WON'T be copied over - Assets will be read from the game's source.",
					"- This build WON'T be ready for release - Running anywhere else than in the bin folder will result in a crash from missing assets",
					"- This build will also use the mods folder from the source directory.",
					"",
					"If you want a full build which contains all assets, run \"cne release\" or \"cne test-release\"",
					"Additional arguments will be sent to the lime compiler.",
					"",
					"-debug : Builds a debug build.",
					"-clean : Compiled files will be deleted before compiling."
				].join("\n")
			}, {
				names: ["run"],
				doc: "Runs the last build that was created.",
				func: Compiler.run,
				dDoc: [
					"Usage: run <optional arguments>",
					"",
					"This will run the last build that was created.",
					"If the last build was a debug build, you need to pass the -debug argument to run it.",
					"Additional arguments will be sent to the lime compiler."
				].join("\n")
			}
		];
	}

	public static function main() {
		initCommands();
		final args:Array<String> = Sys.args();
		var commandName:Null<String> = args.shift();
		if (commandName != null) commandName = commandName.toLowerCase();
		else commandName = "help";

		for (c in commands) {
			if (c.names.contains(commandName)) {
				curCommand = c;
				c.func(args);
				return;
			}
		}
	}

	public static function help(args:Array<String>) {
		var cmdName:Null<String> = args.shift();
		if (cmdName != null) {
			cmdName = cmdName.toLowerCase();

			var matchingCommand:Command = null;
			for (c in commands) if (c.names.contains(cmdName)) {
				matchingCommand = c;
				break;
			}

			if (matchingCommand == null) {
				Sys.println('help - Command named $cmdName not found.');
				return;
			}

			Sys.println('Command: ${matchingCommand.names.filter(v -> v != null).join(", ")}');
			Sys.println("---");
			Sys.println(matchingCommand.dDoc);

			return;
		}

		// shows help
		Sys.println("Alter Engine Command Line utility");
		Sys.println('Available commands (${commands.length}):\n');
		for (line in commands) Sys.println('${line.names.join(", ")} - ${line.doc}');
	}
}

typedef Command = {
	var names:Array<String>;
	var func:Array<String>->Void;
	var ?doc:String;
	var ?dDoc:String;
}