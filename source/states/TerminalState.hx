package states;

import flixel.input.keyboard.FlxKey;

class TerminalState extends MusicBeatState
{
	// dont just yoink this code and use it in your own mod. this includes you, psych engine porters.
	// if you ingore this message and use it anyway, atleast give credit.
	public var curCommand:String = "";
	public var previousText:String = "Vs Dave Developer Console [Version 1.0.00001.1235]\nAll Rights Reserved.\n>";
	public var displayText:FlxText;

	public var commandList:Array<TerminalCommand> = new Array<TerminalCommand>();

	// cuzie was too lazy to finish this lol.
	var unformattedSymbols:Array<String> = ["period", "backslash", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "zero", "shift", "semicolon", "alt", "lbracket", "rbracket", "comma", "plus"];
	var formattedSymbols:Array<String> = [".", "/", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "", ";", "", "[", "]", ",", "="];

	override public function create():Void {
		displayText = new FlxText(0, 0, FlxG.width, previousText, 32);
		displayText.setFormat(Paths.font("vcr.ttf"), 32);
		displayText.antialiasing = false;

		commandList.push(new TerminalCommand("help", "Displays this menu.", function(arguments:Array<String>) {
			UpdatePreviousText(false); // resets the text
			var helpText:String = "";
			for (v in commandList) if (v.showInHelp) helpText += (v.commandName + " - " + v.commandHelp + "\n");
			UpdateText("\n" + helpText);
		}));

		commandList.push(new TerminalCommand("admin", "use execute to executes something, open to open something.", function(arguments:Array<String>) {
			if (arguments[0] == "execute") {
				switch (arguments[1]) {
					default:
						UpdatePreviousText(false); // resets the text
						UpdateText("\n" + arguments[1] + "Error.");
					case "fnf.exe":
						UpdatePreviousText(false); // resets the text
						UpdateText('Executing ${arguments[1]}...');
						LoadingState.loadAndSwitchState(new PlayState());
					case "backdoor":
                        utils.system.NativeUtil.showMessageBox("", "Null Object Reference");
						Sys.exit(0);
				}
			} else UpdateText("\nInvalid Parameter"); // todo: translate.
		}));
		commandList.push(new TerminalCommand("clear", "Clears the screen.", function(arguments:Array<String>) {
			previousText = "> ";
			displayText.y = 0;
			UpdateText("");
		}));
		commandList.push(new TerminalCommand("open", "Searches for a text file with the specified ID, and if it exists, display it.", function(arguments:Array<String>) {
			UpdatePreviousText(false); // resets the text
			UpdateText("\n" + switch (arguments[0].toLowerCase()) {
				default: "File not found.";
				case "dave": "Forever lost and adrift.\nTrying to change his destiny.\nDespite this, it pulls him by a lead.\nIt doesn't matter to him though.\nHe has a child to feed.";
				case "bambi": "A forgotten GOD.\nThe truth will never be known.\nThe extent of his POWERs won't ever unfold.";
                case "babyshark": "He's unlikely hero, embarked on a quest to protect the Heart of the Ocean from those who sought to misuse its power.\nAlong their journey, they encountered various sea creatures, some friendly and some not, who joined them in their quest.";
				case "tristan": "The key to defeating the one whose name shall not be stated.\nA heart of gold that will never become faded.";
				case "expunged": "[ACCESS DENIED]";
				case "boyfriend": "LOG [REDACTED]\nA multiversal constant, for some reason. Must dive into further research.";
			});
		}));

		add(displayText);

		super.create();
	}

	public function UpdateText(val:String)
	{
		displayText.text = previousText + val;
	}

	public function UpdatePreviousText(reset:Bool)
	{
		previousText = displayText.text + (reset ? "\n> " : "");
		displayText.text = previousText;
		curCommand = "";
		var finalthing:String = "";
		var splits:Array<String> = displayText.text.split("\n");
		if (splits.length <= 22)
		{
			return;
		}
		var split_end:Int = Math.round(Math.max(splits.length - 22, 0));
		for (i in split_end...splits.length)
		{
			var split:String = splits[i];
			if (split == "")
			{
				finalthing = finalthing + "\n";
			}
			else
			{
				finalthing = finalthing + split + (i < (splits.length - 1) ? "\n" : "");
			}
		}
		previousText = finalthing;
		displayText.text = finalthing;
		if (displayText.height > 720)
			displayText.y = 720 - displayText.height;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var keyJustPressed:FlxKey = cast(FlxG.keys.firstJustPressed(), FlxKey);

		if (keyJustPressed == FlxKey.ENTER)
		{
			var calledFunc:Bool = false;
			var arguments:Array<String> = curCommand.split(" ");
			for (v in commandList)
			{
				if (v.commandName == arguments[0]
					|| (v.commandName == curCommand && v.oneCommand)) // argument 0 should be the actual command at the moment
				{
					arguments.shift();
					calledFunc = true;
					v.funcToCall(arguments);
					break;
				}
			}
			if (!calledFunc)
			{
				UpdatePreviousText(false); // resets the text
				UpdateText("Error Unknown: " + arguments[0] + "\"");
			}
			UpdatePreviousText(true);
			return;
		}

		if (keyJustPressed != FlxKey.NONE)
		{
			if (keyJustPressed == FlxKey.BACKSPACE)
			{
				curCommand = curCommand.substr(0, curCommand.length - 1);
			}
			else if (keyJustPressed == FlxKey.SPACE)
			{
				curCommand += " ";
			}
			else
			{
				var toShow:String = keyJustPressed.toString().toLowerCase();
				for (i in 0...unformattedSymbols.length)
				{
					if (toShow == unformattedSymbols[i])
					{
						toShow = formattedSymbols[i];
						break;
					}
				}
				if (FlxG.keys.pressed.SHIFT)
				{
					toShow = toShow.toUpperCase();
				}
				curCommand += toShow;
			}
			UpdateText(curCommand);
		}
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.BACKSPACE)
		{
			curCommand = "";
		}
		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.switchState(new MainMenuState());
		}
	}
}

class TerminalCommand {
	public var commandName:String = "undefined";
	public var commandHelp:String = "if you see this you are very homosexual and dumb.";
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