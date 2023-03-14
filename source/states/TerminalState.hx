package states;

import shaders.VCRDistortionEffect.VCRDistortionEffect;
import openfl.filters.ShaderFilter;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.sound.FlxSound;
import flixel.FlxG;

class TerminalState extends MusicBeatState
{
    //dont just yoink this code and use it in your own mod. this includes you, psych engine porters.
    //if you ingore this message and use it anyway, atleast give credit.

    public var curCommand:String = "";
    public var previousText:String = "FNF Developer Console [Version 1.0.0]\nAll Rights Reserved.\n[WARNING] \\bin\\Sys\\system.bin not found!\n> ";
    public var displayText:FlxText;
    public var CommandList:Array<TerminalCommand> = new Array<TerminalCommand>();
    public var typeSound:FlxSound;

    var shaderVCR:VCRDistortionEffect;

    // [BAD PERSON] was too lazy to finish this lol.
    final unformattedSymbols:Array<String> = [
        "period", "backslash",
        "one", "two", "three", "four", "five", 
        "six", "seven", "eight", "nine", "zero",
        "shift", "semicolon", "alt", "lbracket",
        "rbracket", "comma", "plus"
    ];

    final formattedSymbols:Array<String> = [
        ".", "/",
        "1", "2", "3", "4", "5",
        "6", "7", "8", "9", "0",
        "", ";", "", "[", "]",
        ",", "="
    ];

    override public function create():Void
    {
        Main.overlayVar.alpha = .5;
		#if discord_rpc
		DiscordClient.changePresence("The Terminal", null);
		#end

        shaderVCR = new VCRDistortionEffect();
        shaderVCR.distortionOn = true;
        if (ClientPrefs.getPref('shaders'))
            FlxG.camera.setFilters([new ShaderFilter(shaderVCR.shader)]);

        displayText = new FlxText(0, 0, FlxG.width, previousText, 14);
		displayText.setFormat(Paths.font("vcr.ttf"), 14);
        displayText.size *= 2;
		displayText.antialiasing = false;
        typeSound = FlxG.sound.load(Paths.sound('terminal_space'), 0.6);
        FlxG.sound.playMusic(Paths.music('TheAmbience', 'shared'), 0.7);

        CommandList.push(new TerminalCommand("help", "Displays this menu.", function(arguments:Array<String>) {
            UpdatePreviousText(); //resets the text
            var helpText:String = "";
            for (v in CommandList) {
                if (v.showInHelp) {
                    helpText += (v.commandName + " - " + v.commandHelp + "\n");
                }
            }
            UpdateText("\n" + helpText);
        }));

        CommandList.push(new TerminalCommand("clear", "Clears the screen.", function(arguments:Array<String>) {
            previousText = "";
            UpdateText("");
        }));

        CommandList.push(new TerminalCommand("open", "Searches for a text file with the specified ID, and if it exists, display it.", function(arguments:Array<String>) {
            UpdatePreviousText(); //resets the text
            var tx = "";
            switch (arguments[0].toLowerCase()) {
                default: tx = "File not found.";
                case "dave": tx = "Forever lost and adrift.\nTrying to change his destiny.\nDespite this, it pulls him by a lead.\nIt doesn't matter to him though.\nHe has a child to feed.";
                case "bambi": tx = "A forgotten GOD.\nThe truth will never be known.\nThe extent of his POWERs won't ever unfold.";
                case "tristan": tx = "The key to defeating the one whose name shall not be stated.\nA heart of gold that will never become faded.";
                case "expunged": tx = "[FILE DELETED]\n[FUCK YOU!]";
            }
            UpdateText("\n" + tx);
        }));

        add(displayText);
        super.create();
    }

	override function destroy() {
		super.destroy();
		Main.overlayVar.alpha = 1;
	}

    public function UpdateText(val:String) {
        displayText.text = previousText + val;
    }

    //after all of my work this STILL DOESNT COMPLETELY STOP THE TEXT SHIT FROM GOING OFF THE SCREEN IM GONNA DIE
    public function UpdatePreviousText(reset:Bool = false)
    {
        previousText = displayText.text + (reset ? "\n> " : "");
        displayText.text = previousText;
        curCommand = "";
        var finalthing:String = "";
        var splits:Array<String> = displayText.text.split("\n");
        if (splits.length <= 22) {
            return;
        }
        var split_end:Int = Math.round(Math.max(splits.length - 22,0));
        for (i in split_end...splits.length) {
            var split:String = splits[i];
            if (split == "") {
                finalthing = finalthing + "\n";
            } else {
                finalthing = finalthing + split + (i < (splits.length - 1) ? "\n" : "");
            }
        }
        previousText = finalthing;
        displayText.text = finalthing;
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (shaderVCR != null) {
            shaderVCR.update(elapsed);
        }
        
        var keyJustPressed:FlxKey = cast(FlxG.keys.firstJustPressed(), FlxKey);
        if (keyJustPressed == FlxKey.ENTER) {
            var calledFunc:Bool = false;
            var arguments:Array<String> = curCommand.split(" ");
            for (v in CommandList) {
                if (v.commandName == arguments[0] || (v.commandName == curCommand && v.oneCommand)) { //argument 0 should be the actual command at the moment
                    arguments.shift();
                    calledFunc = true;
                    v.funcToCall(arguments);
                    break;
                }
            }
            if (!calledFunc) {
                UpdatePreviousText(); //resets the text
                UpdateText("\nUnknown command \"" + arguments[0] + "\"");
            }
            UpdatePreviousText(true);
            return;
        }

        if (keyJustPressed != FlxKey.NONE) {
            if (keyJustPressed == FlxKey.BACKSPACE) {
                curCommand = curCommand.substr(0, curCommand.length - 1);
                typeSound.play();
            } else if (keyJustPressed == FlxKey.SPACE) {
                curCommand += " ";
                typeSound.play();
            } else {
                var toShow:String = keyJustPressed.toString().toLowerCase();
                for (i in 0...unformattedSymbols.length) {
                    if (toShow == unformattedSymbols[i]) {
                        toShow = formattedSymbols[i];
                        break;
                    }
                }
                if (FlxG.keys.pressed.SHIFT) {
                    toShow = toShow.toUpperCase();
                }
                curCommand += toShow;
                typeSound.play();
            }
            UpdateText(curCommand);
        }
        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.BACKSPACE) {
            curCommand = "";
        }
        if (FlxG.keys.justPressed.ESCAPE) {
            MusicBeatState.switchState(new MainMenuState());
            FlxG.sound.playMusic(Paths.music('freakyMenu'));
        }
    }
}

class TerminalCommand
{
    public var commandName:String = "undefined";
    public var commandHelp:String = "if you see this you are very homosexual and dumb."; //hey im not homosexual. kinda mean ngl
    public var funcToCall:Dynamic;
    public var showInHelp:Bool;
    public var oneCommand:Bool;

    public function new(name:String, help:String, func:Dynamic, showInHelp = true, oneCommand:Bool = false)
    {
        commandName = name;
        commandHelp = help;
        funcToCall = func;
        this.showInHelp = showInHelp;
        this.oneCommand = oneCommand;
    }
}