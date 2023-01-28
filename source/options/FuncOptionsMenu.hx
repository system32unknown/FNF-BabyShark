package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import utils.Controls;
import utils.ClientPrefs;
#if desktop
import utils.Discord.DiscordClient;
#end
import substates.MusicBeatSubstate;
import ui.Alphabet;

class FuncOptionsMenu extends MusicBeatSubstate
{
	private var curOption:OptionFunc = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<OptionFunc>;

	private var grpOptions:FlxTypedGroup<Alphabet>;

	private var descBox:FlxSprite;
	private var descText:FlxText;

	public var title:String;
	public var rpcTitle:String;

	public function new()
	{
		super();

		if(title == null) title = 'Options';
		if(rpcTitle == null) rpcTitle = 'Options Menu';
		
		#if desktop
		DiscordClient.changePresence(rpcTitle, null);
		#end
		
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		add(bg);

		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		descBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		var titleText:Alphabet = new Alphabet(75, 40, title, true);
		titleText.scaleX = 0.6;
		titleText.scaleY = 0.6;
		titleText.alpha = 0.4;
		add(titleText);

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		for (i in 0...optionsArray.length)
		{
			var optionText:Alphabet = new Alphabet(290, 260, optionsArray[i].name, false);
			optionText.isMenuItem = true;
			optionText.x += 220;
			optionText.targetY = i;
			grpOptions.add(optionText);
			optionText.startPosition.x -= 80;
		}

		changeSelection();
	}

	public function addOptionFunc(option:OptionFunc) {
		if(optionsArray == null || optionsArray.length < 1) optionsArray = [];
		optionsArray.push(option);
	}

	var nextAccept:Int = 5;
	override function update(elapsed:Float)
	{
		if (controls.UI_UP_P) {
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P) {
			changeSelection(1);
		}

		if (controls.BACK) {
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if(nextAccept <= 0) {
			if(controls.ACCEPT) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				if (curOption.funcs != null) curOption.funcs();
			}
		}

		if (nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}
	
	function changeSelection(change:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + change, 0, optionsArray.length - 1);

		var descString:String = "";
		var checkIfEmpty:Bool = optionsArray[curSelected].description != "";
		if (checkIfEmpty) descString = optionsArray[curSelected].description;
		descBox.visible = checkIfEmpty;
		descText.text = descString;
		descText.screenCenter(Y);
		descText.y += 270;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}

		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();

		curOption = optionsArray[curSelected]; //shorter lol
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}