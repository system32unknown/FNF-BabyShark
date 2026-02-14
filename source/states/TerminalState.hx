package states;

import flixel.input.keyboard.FlxKey;

/**
 * Ubuntu-style terminal theme container.
 * Abstract over Int so it can still be used as a raw color.
 */
enum abstract TerminalTheme(Int) from Int to Int {
	// Background
	var COL_BG:Int = 0xFF0C0C0C;

	// Default terminal text
	var COL_TEXT:Int = 0xFFEDEDED;

	// Prompt color (user@host:~$)
	var COL_PROMPT:Int = 0xFF7CFC00;

	// Errors (command not found, access denied, etc)
	var COL_ERROR:Int = 0xFFFF5555;

	// Muted / intro / system info
	var COL_MUTED:Int = 0xFFAAAAAA;

	// Optional helpers if you want later:
	var COL_SUCCESS:Int = 0xFF55FF55;
	var COL_WARNING:Int = 0xFFFFC107;
}

class TerminalState extends MusicBeatState {
	static inline var MAX_LINES:Int = 22;

	var curCmd:String = "";
	var adminUnlocked:Bool = false;
	var displayText:FlxText;

	var cmdList:Array<TerminalCommand> = [];
	var cmdMap:Map<String, TerminalCommand> = [];

	var typeSound:FlxSound;

	var lines:Array<TermLine> = [];

	// Faster than parallel arrays + loops each keypress
	static final SYMBOL_MAP:Map<String, String> = (function() {
		var m:Map<String, String> = new Map<String, String>();
		m.set("period", ".");
		m.set("backslash", "/");
		m.set("one", "1");
		m.set("two", "2");
		m.set("three", "3");
		m.set("four", "4");
		m.set("five", "5");
		m.set("six", "6");
		m.set("seven", "7");
		m.set("eight", "8");
		m.set("nine", "9");
		m.set("zero", "0");
		m.set("shift", "");
		m.set("semicolon", ";");
		m.set("alt", "");
		m.set("lbracket", "[");
		m.set("rbracket", "]");
		m.set("comma", ",");
		m.set("plus", "=");
		return m;
	})();

	var showCursor:Bool = true;
	override public function create():Void {
		Main.fpsVar.visible = false;
		PlayState.isStoryMode = false;

		displayText = new FlxText(0, 0, FlxG.width, '', 16);
		displayText.setFormat(Paths.font("CascadiaCode.ttf"), displayText.size);
		displayText.antialiasing = false;
		displayText.scrollFactor.set();

		typeSound = FlxG.sound.load(Paths.sound("terminal_space"), .6);
		FlxG.sound.playMusic(Paths.music("TheAmbience"), .7);
		registerCommands();

		pushPrompt();
		render();

		add(displayText);
		super.create();
	}

	inline function promptString():String {
		return 'dave@console:~$ ';
	}

	function pushPrompt():Void {
		pushLine(promptString() + curCmd + (showCursor ? "█" : ""), COL_PROMPT);
	}

	function pushLine(text:String, color:Dynamic):Void {
		if (!Std.isOfType(color, Int)) return;
		// split multi-line input into individual line entries
		for (part in text.split("\n")) lines.push({text: part, color: color});
		clampScrollback();
	}

	function replaceLastLine(text:String, color:Int):Void {
		if (lines.length == 0) lines.push({text: text, color: color});
		else lines[lines.length - 1] = {text: text, color: color};
	}

	function clampScrollback():Void {
		if (lines.length <= MAX_LINES) return;
		lines = lines.slice(lines.length - MAX_LINES, lines.length);
	}

	function render():Void {
		var buf:StringBuf = new StringBuf();
		for (i in 0...lines.length) {
			buf.add(lines[i].text);
			if (i < lines.length - 1) buf.add("\n");
		}
		displayText.text = buf.toString();
		displayText.clearFormats();

		var pos:Int = 0;
		for (i in 0...lines.length) {
			var s:String = lines[i].text;
			displayText.addFormat(new FlxTextFormat(lines[i].color), pos, pos + s.length);
			pos += s.length + 1; // + newline
		}
	}

	// Updates the prompt line live while typing
	function refreshPromptLine():Void {
		replaceLastLine(promptString() + curCmd + (showCursor ? "█" : ""), COL_PROMPT);
		render();
	}

	function registerCommands():Void {
		addCmd(new TerminalCommand("help", "Displays this menu.", (args:Array<String>) -> {
			lines.pop();
			var helpText:StringBuf = new StringBuf();
			for (v in cmdList) {
				if (!v.showInHelp) continue;
				helpText.add(v.commandName);
				helpText.add(" - ");
				helpText.add(Language.getPhrase('termcommand_${v.commandName}', v.commandHelp));
				helpText.add("\n");
			}
			pushLine(helpText.toString().trim(), COL_TEXT);
			curCmd = "";
			pushPrompt();
			render();
		}));

		addCmd(new TerminalCommand("clear", "Clears the screen.", _ -> {
			lines = [];
			curCmd = "";
			pushPrompt();
			render();
		}));

		addCmd(new TerminalCommand("admin", "Shows the admin list, use grant to grant rights.", (args:Array<String>) -> {
			lines.pop();

			if (args.length == 2 && args[0] == "unlock" && args[1] == "expunged") {
				adminUnlocked = true;
				pushLine("Unlocked.", COL_TEXT);
			} else if (args.length == 0) {
				pushLine(Language.getPhrase("term_admlist_ins", "To add extra users, add the grant parameter and the name.\n(Example: admin grant expungo.dat)\nNOTE: ADDING CHARACTERS AS ADMINS CAN CAUSE UNEXPECTED CHANGES."), COL_TEXT);
			} else {
				pushLine("Invalid Parameter", COL_ERROR);
			}

			curCmd = "";
			pushPrompt();
			render();
		}));

		addCmd(new TerminalCommand("open", "Searches for a text file with the specified ID, and if it exists, display it.", (args:Array<String>) -> {
			lines.pop();

			pushLine(switch ((args.length > 0 && args[0] != null) ? args[0].toLowerCase() : "") {
				case "dave": "Forever lost and adrift.\nTrying to change his destiny.\nDespite this, it pulls him by a lead.\nIt doesn't matter to him though.\nHe has a child to feed.";
				case "bambi": "A forgotten GOD.\nThe truth will never be known.\nThe extent of his POWERs won't ever unfold.";
				case "tristan": "The key to defeating the one whose name shall not be stated.\nA heart of gold that will never become faded.";
				case "expunged": "[FILE DELETED]\n[FUCK YOU!]";
				case "deleted": "The unnamable never was a god and never will be. Just an accident.";
				case "exbungo": "[EXBUNGOS FILE ARE THE ONLY ONES I HAVE ACCESS TO UNFORTUNATELY.]\n[I HATE HIM. HE'S UGLY AND FAT.]";
				case "ollie" | "babyshark": "[I HATE HIM. BECAUSE HE KEEPS FOLLOWING ME, AND WANTS FRIENDS. BUT I LIKE HIM.]";
				case "t5" | "t5mpler": "What the fuck are you doing in here?";
				case "": "Missing file id.";
				default: "File not found.";
			}, COL_TEXT);
			curCmd = "";
			pushPrompt();
			render();
		}));

		addCmd(new TerminalCommand("access", "Accesses the secret song.", _ -> {
			lines.pop();
			pushLine(adminUnlocked ? "Not Implemented." : "Access Denied.", adminUnlocked ? COL_TEXT : COL_ERROR);
			curCmd = "";
			pushPrompt();
			render();
		}));

		addCmd(new TerminalCommand("echo", '', (args:Array<String>) -> {
			lines.pop();
			pushLine(args.join(' '), COL_TEXT);
			curCmd = "";
			pushPrompt();
			render();
		}));
	}

	inline function addCmd(cmd:TerminalCommand):Void {
		cmdList.push(cmd);
		cmdMap.set(cmd.commandName, cmd);
	}

	function runCommand(raw:String):Void {
		var trimmed:String = raw.trim();
		var parts:Array<String> = (trimmed.length == 0) ? [] : trimmed.split(" ");
		var cmdName:String = (parts.length > 0) ? parts[0] : "";

		if (cmdName.length == 0) {
			lines.pop();
			pushPrompt();
			render();
			return;
		}

		var cmd:Null<TerminalCommand> = cmdMap.get(cmdName);
		if (cmd != null) {
			parts.shift();
			cmd.funcToCall(parts);
			return;
		}

		// unknown
		lines.pop();
		pushLine('bash: command "$cmdName" not found', COL_ERROR);
		curCmd = "";
		pushPrompt();
		render();
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE) {
			Main.fpsVar.visible = true;
			FlxG.switchState(() -> new FreeplayState());
			FlxG.sound.playMusic(Paths.music("freakyMenu"));
			return;
		}

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.BACKSPACE) {
			curCmd = "";
			typeSound.play();
			refreshPromptLine();
			return;
		}

		var key:FlxKey = cast FlxG.keys.firstJustPressed();
		if (key == FlxKey.NONE) return;

		switch (key) {
			case FlxKey.ENTER:
				runCommand(curCmd);
				return;

			case FlxKey.BACKSPACE:
				if (curCmd.length > 0) curCmd = curCmd.substr(0, curCmd.length - 1);
				typeSound.play();

			case FlxKey.SPACE:
				curCmd += " ";
				typeSound.play();

			default:
				var s:String = keyToChar(key);
				if (s.length > 0) {
					curCmd += (FlxG.keys.pressed.SHIFT ? s.toUpperCase() : s);
					typeSound.play();
				}
		}

		refreshPromptLine();
	}

	inline function keyToChar(key:FlxKey):String {
		var raw:String = key.toString().toLowerCase();
		var mapped:String = SYMBOL_MAP.get(raw);
		return mapped != null ? mapped : raw;
	}
}

// Small struct for colored lines
typedef TermLine = {
	var text:String;
	var color:Int;
};

class TerminalCommand {
	public var commandName:String;
	public var commandHelp:String;
	public var funcToCall:Array<String>->Void;

	public var showInHelp:Bool;
	public var oneCommand:Bool;

	public function new(name:String, help:String, func:Array<String>->Void, showInHelp:Bool = true, oneCommand:Bool = false) {
		commandName = name;
		commandHelp = help;
		funcToCall = func;
		this.showInHelp = showInHelp;
		this.oneCommand = oneCommand;
	}
}