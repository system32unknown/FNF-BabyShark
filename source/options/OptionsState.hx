package options;

#if desktop
import utils.Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import utils.ClientPrefs;
import states.MusicBeatState;
import states.MainMenuState;
import states.LoadingState;
import ui.Alphabet;

using StringTools;

class OptionsState extends MusicBeatState
{
	var options:Map<Int, Array<Dynamic>> = [
		0 => ['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics', 'Visuals and UI', 'Gameplay'],
		1 => ['Saves', 'Miscellaneous']
	];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;

	function openSelectedSubstate(label:String) {
		switch(label) {
			case 'Note Colors': openSubState(new options.NotesSubState());
			case 'Controls': openSubState(new options.ControlsSubState());
			case 'Graphics': openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI': openSubState(new options.VisualsUISubState());
			case 'Gameplay': openSubState(new options.GameplaySettingsSubState());
			case 'Miscellaneous': openSubState(new options.MiscellaneousSubState());
			case 'Saves': openSubState(new options.MiscellaneousSubState());
			case 'Adjust Delay and Combo': LoadingState.loadAndSwitchState(new options.NoteOffsetState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	var curPage:Int = 0;
	var pageBG:FlxSprite;
	var pageText:FlxText;

	override function create() {
		#if desktop
		DiscordClient.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.updateHitbox();

		bg.screenCenter();
		bg.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		reload();

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		pageText = new FlxText(FlxG.width * .82, 5, 0, "", 32);
		pageText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		
		pageBG = new FlxSprite(pageText.x - 6, FlxG.height - 40).makeGraphic(260, 40, FlxColor.BLACK);
		pageBG.alpha = 0.6;

		pageText.y = pageBG.y;
		pageBG.updateHitbox();

		add(pageBG);
		add(pageText);

		changeSelection();
		ClientPrefs.saveSettings();

		super.create();
	}

	function reload(re:Bool = false) {
		if (re) grpOptions.clear();
		for (i in 0...options[curPage].length) {
			var optionText:Alphabet = new Alphabet(0, 0, options[curPage][i], true);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options[curPage].length / 2))) + 50;
			grpOptions.add(optionText);
		}
	}

	override function closeSubState() {
		super.closeSubState();
		ClientPrefs.saveSettings();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_UP_P) {
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P) {
			changeSelection(1);
		}

		if(controls.UI_LEFT_P) changePage(-1);
		if(controls.UI_RIGHT_P) changePage(1);

		pageText.text = '<PAGE: $curPage / ${Lambda.count(options) - 1}>';

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if (controls.ACCEPT) {
			openSelectedSubstate(options[curPage][curSelected]);
		}
	}
	
	function changeSelection(change:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + change, 0, options[curPage].length - 1);

		var bullShit:Int = 0;
		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changePage(change:Int = 0) {
		curPage = FlxMath.wrap(curPage + change, 0, Lambda.count(options) - 1);
		curSelected = 0;
		reload(true);

		var bullShit:Int = 0;
		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}