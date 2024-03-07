package states;

import flixel.input.keyboard.FlxKey;

class TerminalState extends MusicBeatState {
	// dont just yoink this code and use it in your own mod. this includes you, psych engine porters.
	// if you ingore this message and use it anyway, atleast give credit.
	public var curCmd:String = "";
	public var previousText:String = 'Vs Dave Developer Console[Version 1.0.00001.1235]\nAll Rights Reserved.\n>';
	public var displayText:FlxText;

	public var cmdList:Array<TerminalCommand> = new Array<TerminalCommand>();
	public var typeSound:FlxSound;

	// [BAD PERSON] was too lazy to finish this lol.
	var unformattedSymbols:Array<String> = [
		"period", "backslash", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "zero", "shift", "semicolon", "alt", "lbracket",
		"rbracket", "comma", "plus"
	];
	var formattedSymbols:Array<String> = [
		".", "/", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "", ";", "", "[", "]", ",", "="
	];

	override public function create():Void {
		Main.fpsVar.visible = false;
		PlayState.isStoryMode = false;

		displayText = new FlxText(0, 0, FlxG.width, previousText, 32);
		displayText.setFormat(Paths.font("fixedsys.ttf"), 16);
		displayText.size *= 2;
		displayText.antialiasing = false;
		typeSound = FlxG.sound.load(Paths.sound('terminal_space'), .6);
		FlxG.sound.playMusic(Paths.music('TheAmbience'), .7);

		cmdList.push(new TerminalCommand("help", "Displays this menu.", (args:Array<String>) -> {
			updatePreviousText(false); // resets the text
			var helpText:String = "";
			for (v in cmdList) if (v.showInHelp) helpText += (v.commandName + " - " + v.commandHelp + "\n");
			updateText('\n$helpText');
		}));

		cmdList.push(new TerminalCommand("characters", "Shows the list of characters.", (args:Array<String>) -> {
			updatePreviousText(false); // resets the text
			updateText("\ndave.dat\nbambi.dat\ntristan.dat\nexpunged.dat\nexbungo.dat\nrecurser.dat\nmoldy.dat");
		}));
		cmdList.push(new TerminalCommand("admin", "Shows the admin list, use grant to grant rights.", (args:Array<String>) -> {
			if (args.length == 0) {
				updatePreviousText(false); // resets the text
				updateText("\nTo add extra users, add the grant parameter and the name.\n(Example: admin grant expungo.dat)\nNOTE: ADDING CHARACTERS AS ADMINS CAN CAUSE UNEXPECTED CHANGES.");
				return;
			} else if (args.length != 2) {
				updatePreviousText(false); // resets the text
				updateText('\nNo version of the "admin" command takes ${args.length} parameter(s).');
			} else {
				if (args[0] == "grant") {
					switch (args[1]) {
						default:
							updatePreviousText(false); // resets the text
							updateText('\n${args[1]}is not a valid user or character.');
					}
				} else updateText("\nInvalid Parameter"); // todo: translate.
			}
		}));
		cmdList.push(new TerminalCommand("clear", "Clears the screen.", (args:Array<String>) -> {
			previousText = "> ";
			displayText.y = 0;
			updateText("");
		}));
		cmdList.push(new TerminalCommand("open", "Searches for a text file with the specified ID, and if it exists, display it.", (args:Array<String>) -> {
			updatePreviousText(false); // resets the text
			var tx:String = switch(args[0].toLowerCase()) {
				case "dave": "Forever lost and adrift.\nTrying to change his destiny.\nDespite this, it pulls him by a lead.\nIt doesn't matter to him though.\nHe has a child to feed.";
				case "bambi": "A forgotten GOD.\nThe truth will never be known.\nThe extent of his POWERs won't ever unfold.";
				case "god" | "artifact1": "Artifact 1:\nA stone with symbols and writing carved into it.\nDescription:Its a figure that has hundreds of EYEs all across its body.\nNotes: Why does it look so much like Bambi?";
				case "tristan": "The key to defeating the one whose name shall not be stated.\nA heart of gold that will never become faded.";
				case "expunged": "[FILE DELETED]\n[FUCK YOU!]";
				case "deleted": "The unnamable never was a god and never will be. Just an accident.";
				case "exbungo": "[EXBUNGOS FILE ARE THE ONLY ONES I HAVE ACCESS TO UNFORTUNATELY.]\n[I HATE IT. BECAUSE HE'S UGLY AND FAT.]";
				case "recurser": "A being of chaos that wants to spread ORDER.\nDespite this, his sanity is at the border.";
				case "ollie" | "babyshark": "[I HATE HIM. BECAUSE HE KEEPS FOLLOWING ME, AND WANTS FRIENDS. BUT I LIKE HIM.]";
				case "t5" | "t5mpler": "What the fuck are you doing in here?";
				case "redacted": "[THE OTHER ME. BUT HE'S POWERFUL. CAN DESTROY BOYFRIEND.]";
				default: "File not found.";
			}
			updateText('\n$tx');
		}));

		add(displayText);
		super.create();
	}

	public function updateText(val:String) {
		displayText.text = previousText + val;
	}

	public function updatePreviousText(reset:Bool) {
		previousText = displayText.text + (reset ? "\n> " : "");
		displayText.text = previousText;
		curCmd = "";

		var finalthing:String = "";
		var splits:Array<String> = displayText.text.split("\n");
		if (splits.length <= 22) return;
		var split_end:Int = Math.round(Math.max(splits.length - 22, 0));
		for (i in split_end...splits.length) {
			var split:String = splits[i];
			if (split == "") finalthing += "\n";
			else finalthing += split + (i < (splits.length - 1) ? "\n" : "");
		}

		previousText = finalthing;
		displayText.text = finalthing;
		if (displayText.height > 720) displayText.y = 720 - displayText.height;
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		var keyJustPressed:FlxKey = cast(FlxG.keys.firstJustPressed(), FlxKey);
		if (keyJustPressed == FlxKey.ENTER) {
			var calledFunc:Bool = false;
			var args:Array<String> = curCmd.split(" ");
			for (v in cmdList) {
				if (v.commandName == args[0] || (v.commandName == curCmd && v.oneCommand)) { // argument 0 should be the actual command at the moment
					args.shift();
					calledFunc = true;
					v.funcToCall(args);
					break;
				}
			}
			if (!calledFunc) {
				updatePreviousText(false); // resets the text
				updateText('\nUnknown command "${args[0]}"');
			}
			updatePreviousText(true);
			return;
		}

		if (keyJustPressed != FlxKey.NONE) {
			if (keyJustPressed == FlxKey.BACKSPACE) {
				curCmd = curCmd.substr(0, curCmd.length - 1);
				typeSound.play();
			} else if (keyJustPressed == FlxKey.SPACE) {
				curCmd += " ";
				typeSound.play();
			} else {
				var toShow:String = keyJustPressed.toString().toLowerCase();
				for (i in 0...unformattedSymbols.length) {
					if (toShow == unformattedSymbols[i]) {
						toShow = formattedSymbols[i];
						break;
					}
				}

				if (FlxG.keys.pressed.SHIFT) toShow = toShow.toUpperCase();
				curCmd += toShow;
				typeSound.play();
			}
			updateText(curCmd);
		}
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.BACKSPACE) curCmd = "";

		if (FlxG.keys.justPressed.ESCAPE) {
			Main.fpsVar.visible = true;
			FlxG.switchState(new MainMenuState());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}
	}
}

class TerminalCommand {
	public var commandName:String = "undefined";
	public var commandHelp:String = "this is example text help";
	public var funcToCall:Dynamic;
	public var showInHelp:Bool;
	public var oneCommand:Bool;

	public function new(name:String, help:String, func:Dynamic, showInHelp = true, oneCommand:Bool = false) {
		commandName = name;
		commandHelp = help;
		funcToCall = func;
		this.showInHelp = showInHelp;
		this.oneCommand = oneCommand;
	}
}