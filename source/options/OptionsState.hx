package options;

import states.MainMenuState;
import states.LoadingState;
import ui.Alphabet;

class OptionsState extends MusicBeatState
{
	var options:Array<Array<Dynamic>> = [
		['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics', 'Visuals and UI', 'Gameplay'],
		['Saves', 'Miscellaneous']
	];
	var grpOptions:FlxTypedGroup<Alphabet>;
	static var curSelected:Int = 0;

	function openSelectedSubstate(label:String) {
		switch(label) {
			case 'Note Colors': openSubState(new NotesSubState());
			case 'Controls': openSubState(new ControlsSubState());
			case 'Graphics': openSubState(new GraphicsSettingsSubState());
			case 'Visuals and UI': openSubState(new VisualsUISubState());
			case 'Gameplay': openSubState(new GameplaySettingsSubState());
			case 'Miscellaneous': openSubState(new MiscellaneousSubState());
			case 'Saves': openSubState(new SaveSubState());
			case 'Adjust Delay and Combo': LoadingState.loadAndSwitchState(new options.NoteOffsetState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	var curPage:Int = 0;
	var descTxt:FlxText;

	override function create() {
		#if discord_rpc
		Discord.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		add(grpOptions = new FlxTypedGroup<Alphabet>());

		reload();

		add(selectorLeft = new Alphabet(0, 0, '>', true));
		add(selectorRight = new Alphabet(0, 0, '<', true));

		#if MODS_ALLOWED
		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		descTxt = new FlxText(textBG.x, textBG.y + 4, FlxG.width, "Press RESET to access the Modpacks Options saves Reset menu.", 18);
		descTxt.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, RIGHT);
		descTxt.scrollFactor.set();
		add(descTxt);
		#end

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
		#if desktop
		Discord.changePresence("Options Menu", null);
		#end
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_UP_P) changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(1);

		if(controls.UI_LEFT_P) changePage(-1);
		if(controls.UI_RIGHT_P) changePage(1);

		descTxt.text = '($curPage / ${Lambda.count(options) - 1}) Press RESET to access the Modpacks Options saves Reset menu.';

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if (controls.ACCEPT) {
			openSelectedSubstate(options[curPage][curSelected]);
		}

		#if MODS_ALLOWED
		if (controls.RESET) openSubState(new DeleteSavesSubState());
		#end
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
				selectorLeft.setPosition(item.x - 63, item.y);
				selectorRight.setPosition(item.x + item.width + 15, item.y);
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
				selectorLeft.setPosition(item.x - 63, item.y);
				selectorRight.setPosition(item.x + item.width + 15, item.y);
			}
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy() {
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}