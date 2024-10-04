package options;

import objects.Note;
import objects.StrumNote;

class VisualsSettingsSubState extends BaseOptionsMenu {
	var noteOptionID:Int = -1;
	var notes:FlxTypedGroup<StrumNote>;
	var notesTween:Array<FlxTween> = [];
	var noteY:Float = 90;
	var changedMusic:Bool = false;
	public function new() {
		title = Language.getPhrase('visuals_menu', 'Visuals Settings');
		rpcTitle = 'Visuals Settings Menu'; //for Discord Rich Presence

		// for note skins
		notes = new FlxTypedGroup<StrumNote>();
		for (i in 0...Note.colArray.length) {
			var note:StrumNote = new StrumNote(370 + (560 / Note.colArray.length) * i, -200, i, 0);
			note.centerOffsets();
			note.centerOrigin();
			note.playAnim('static');
			notes.add(note);
		}

		// options
		var noteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');
		if(noteSkins.length > 0) {
			if(!noteSkins.contains(ClientPrefs.data.noteSkin))
				ClientPrefs.data.noteSkin = ClientPrefs.defaultData.noteSkin; //Reset to default if saved noteskin couldnt be found

			noteSkins.insert(0, ClientPrefs.defaultData.noteSkin); //Default skin always comes first
			var option:Option = new Option('Note Skins:', "Select your prefered Note skin.", 'noteSkin', STRING, noteSkins);
			addOption(option);
			option.onChange = () -> notes.forEachAlive((note:StrumNote) -> {
				changeNoteSkin(note);
				note.setGraphicSize(112);
				note.centerOffsets();
				note.centerOrigin();
			});
			noteOptionID = optionsArray.length - 1;
		}
		
		var noteSplashes:Array<String> = Mods.mergeAllTextsNamed('images/noteSplashes/list.txt');
		if(noteSplashes.length > 0) {
			if(!noteSplashes.contains(ClientPrefs.data.splashSkin))
				ClientPrefs.data.splashSkin = ClientPrefs.defaultData.splashSkin; //Reset to default if saved splashskin couldnt be found

			noteSplashes.insert(0, ClientPrefs.defaultData.splashSkin); //Default skin always comes first
			addOption(new Option('Note Splashes:', "Select your prefered Note Splash variation or turn it off.", 'splashSkin', STRING, noteSplashes));
		}

		var option:Option = new Option('Note Splashes', "Set the alpha for the Note Splashes, usually shown when hitting \"Epic!\" or \"Sick!\" notes.", 'splashAlpha', PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		addOption(new Option('Hide HUD', 'If checked, hides most HUD elements.', 'hideHud', BOOL));
		addOption(new Option('Time Bar:', "What should the Time Bar display?", 'timeBarType', STRING, ['Time Left', 'Time Elapsed', 'Song Name', 'Time Position', 'Name Left', 'Name Elapsed', 'Name Time Position', 'Disabled']));
		addOption(new Option('Flashing Lights', "Uncheck this if you're sensitive to flashing lights!", 'flashing', BOOL));
		addOption(new Option('Icon Bounce:', "What should the Icon Bounces?", 'iconBounceType', STRING, ['Old', 'Psych', 'Dave', 'GoldenApple', 'Custom']));
		addOption(new Option('Health Bar Type:', "What should the Health Bar Types?", 'healthTypes', STRING, ['Vanilla', 'Psych']));
		addOption(new Option('Smooth Health', '', 'smoothHealth', BOOL));
		addOption(new Option('Light Strums', '', 'lightStrum', BOOL));
		var option:Option = new Option('Health Bar Opacity', 'How much opacity should the health bar and icons be.', 'healthBarAlpha', PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);
		addOption(new Option('Camera Zooms', "If unchecked, the camera won't zoom in on a beat hit.", 'camZooms', BOOL));
		addOption(new Option('Show Combo Counter', 'If checked, the combo counter will be shown.', 'showComboCounter', BOOL));
		addOption(new Option('Show ms Timing', 'If checked, the ms timing will be shown.', 'showMsTiming', BOOL));
		addOption(new Option('Show NPS Display', 'If checked, Shows your current Notes Per Second on the info bar.', 'showNPS', BOOL));
		addOption(new Option('Show Judgements Counter', 'If checked, the Judgements counter will be shown.', 'showJudgement', BOOL));
		addOption(new Option('Rating Display:', 'Choose the type of rating you want to see.', 'ratingDisplay', STRING, ['Hud', 'World']));
		
		var option:Option = new Option('Pause Music:', "What song do you prefer for the Pause Screen?", 'pauseMusic', STRING, ['None', 'Breakfast', 'Tea Time', 'Breakfast (Dave)', 'Breakfast (Pico)']);
		addOption(option);
		option.onChange = () -> {
			if(ClientPrefs.data.pauseMusic == 'None') FlxG.sound.music.volume = 0;
			else FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));
			changedMusic = true;
		};
		#if CHECK_FOR_UPDATES addOption(new Option('Check for Updates', 'On Release builds, turn this on to check for updates when you start the game.', 'checkForUpdates', BOOL)); #end
		#if desktop addOption(new Option('Discord Rich Presence', "Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord", 'discordRPC', BOOL)); #end
		addOption(new Option('Combo Stacking', "If unchecked, Ratings and Combo won't stack, saving on System Memory and making them easier to read", 'comboStacking', BOOL));

		super();
		add(notes);
	}

	override function changeSelection(change:Int = 0) {
		super.changeSelection(change);
		
		if(noteOptionID < 0) return;

		for (i in 0...Note.colArray.length) {
			var note:StrumNote = notes.members[i];
			if(notesTween[i] != null) notesTween[i].cancel();
			if(curSelected == noteOptionID)
				notesTween[i] = FlxTween.tween(note, {y: noteY}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
			else notesTween[i] = FlxTween.tween(note, {y: -200}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
		}
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