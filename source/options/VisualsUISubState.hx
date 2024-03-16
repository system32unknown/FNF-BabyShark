package options;

import objects.Note;
import objects.StrumNote;

class VisualsUISubState extends BaseOptionsMenu {
	var noteOptionID:Int = -1;
	var notes:FlxTypedGroup<StrumNote>;
	var notesTween:Array<FlxTween> = [];
	var noteY:Float = 90;
	var changedMusic:Bool = false;
	public function new() {
		title = 'Visuals and UI';
		rpcTitle = 'Visuals & UI Settings Menu'; //for Discord Rich Presence

		// for note skins
		notes = new FlxTypedGroup<StrumNote>();
		for (i in 0...EK.colArray.length) {
			var note:StrumNote = new StrumNote(45 + 140 * i, -200, i, 0);
			note.setGraphicSize(112);
			note.centerOffsets();
			note.centerOrigin();
			note.playAnim('static');
			notes.add(note);
		}

		// options
		var noteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');
		if(noteSkins.length > 0) {
			if(!noteSkins.contains(ClientPrefs.getPref('noteSkin')))
				ClientPrefs.prefs.set('noteSkin', ClientPrefs.defaultprefs['noteSkin']); //Reset to default if saved noteskin couldnt be found

			noteSkins.insert(0, ClientPrefs.defaultprefs['noteSkin']); //Default skin always comes first
			var option:Option = new Option('Note Skins:', "Select your prefered Note skin.", 'noteSkin', 'string', noteSkins);
			addOption(option);
			option.onChange = onChangeNoteSkin;
			noteOptionID = optionsArray.length - 1;
		}
		
		var noteSplashes:Array<String> = Mods.mergeAllTextsNamed('images/noteSplashes/list.txt');
		if(noteSplashes.length > 0) {
			if(!noteSplashes.contains(ClientPrefs.getPref('splashSkin')))
				ClientPrefs.prefs.set('splashSkin', ClientPrefs.defaultprefs['splashSkin']); //Reset to default if saved splashskin couldnt be found

			noteSplashes.insert(0, ClientPrefs.defaultprefs['splashSkin']); //Default skin always comes first
			addOption(new Option('Note Splashes:', "Select your prefered Note Splash variation or turn it off.", 'splashSkin', 'string', noteSplashes));
		}

		var option:Option = new Option('Note Splashes', "Set the alpha for the Note Splashes, usually shown when hitting \"Sick!\" notes.", 'splashOpacity', 'percent');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		addOption(new Option('Hide HUD', 'If checked, hides most HUD elements.', 'hideHud', 'bool'));
		addOption(new Option('Time Bar:', "What should the Time Bar display?", 'timeBarType', 'string', ['Time Left', 'Time Elapsed', 'Song Name', 'Time Position', 'Name Left', 'Name Elapsed', 'Name Time Position', 'Name Percent', 'Disabled']));
		addOption(new Option('Flashing Lights', "Uncheck this if you're sensitive to flashing lights!", 'flashing', 'bool'));
		addOption(new Option('Icon Bounce:', "What should the Icon Bounces?", 'IconBounceType', 'string', ['Old', 'Psych', 'Dave', 'GoldenApple', 'Custom']));
		addOption(new Option('Health Bar Type:', "What should the Health Bar Types?", 'HealthTypes', 'string', ['Vanilla', 'Psych']));
		addOption(new Option('Smooth Health', '', 'SmoothHealth', 'bool'));
		addOption(new Option('Rating Display:', 'Choose the type of rating you want to see.', 'RatingDisplay', 'string', ['Hud', 'World']));
		addOption(new Option('Camera Zooms', "If unchecked, the camera won't zoom in on a beat hit.", 'camZooms', 'bool'));
		addOption(new Option('Show Combo Counter', 'If checked, the combo counter will be shown.', 'ShowComboCounter', 'bool'));
		addOption(new Option('Show ms Timing', 'If checked, the ms timing will be shown.', 'ShowMsTiming', 'bool'));
		addOption(new Option('Show NPS Display', 'If checked, Shows your current Notes Per Second on the info bar.', 'ShowNPS', 'bool'));
		addOption(new Option('Show Judgements Counter', 'If checked, the Judgements counter will be shown.', 'ShowJudgement', 'bool'));

		#if desktop addOption(new Option('Discord Rich Presence', "Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord", 'discordRPC', 'bool')); #end
		addOption(new Option('Combo Stacking', "If unchecked, Ratings and Combo won't stack, saving on System Memory and making them easier to read", 'comboStacking', 'bool'));
		addOption(new Option('Show Keybinds on Start Song', "If checked, your keybinds will be shown on the strum that they correspond to when you start a song.", 'showKeybindsOnStart', 'bool'));

		var option:Option = new Option('Health Bar Opacity', 'How much opacity should the health bar and icons be.', 'healthBarAlpha', 'percent');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);
		
		var option:Option = new Option('Pause Screen Song:', "What song do you prefer for the Pause Screen?", 'pauseMusic', 'string', ['None', 'Breakfast', 'Tea Time', 'Breakfast Dave']);
		addOption(option);
		option.onChange = () -> {
			if(ClientPrefs.getPref('pauseMusic') == 'None') FlxG.sound.music.volume = 0;
			else FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.getPref('pauseMusic'))));
	
			changedMusic = true;
		};

		super();
	}

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		
		if(noteOptionID < 0) return;

		for (i in 0...EK.colArray.length) {
			var note:StrumNote = notes.members[i];
			if(notesTween[i] != null) notesTween[i].cancel();
			if(curSelected == noteOptionID)
				notesTween[i] = FlxTween.tween(note, {y: noteY}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
			else notesTween[i] = FlxTween.tween(note, {y: -200}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
		}
	}

	function onChangeNoteSkin() {
		notes.forEachAlive((note:StrumNote) -> {
			changeNoteSkin(note);
			note.setGraphicSize(112);
			note.centerOffsets();
			note.centerOrigin();
		});
	}

	function changeNoteSkin(note:StrumNote) {
		var skin:String = Note.defaultNoteSkin;
		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

		note.texture = skin; //Load texture and anims
		note.reloadNote();
		note.playAnim('static');
	}

	override function destroy() {
		if(changedMusic && !OptionsState.onPlayState) FlxG.sound.playMusic(Paths.music('freakyMenu'));
		super.destroy();
	}
}