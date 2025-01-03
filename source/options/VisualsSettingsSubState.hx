package options;

import objects.Note;
import objects.NoteSplash;
import objects.NoteSplash.NoteSplashAnim;
import objects.StrumNote;

class VisualsSettingsSubState extends BaseOptionsMenu {
	var notes:FlxTypedGroup<StrumNote>;
	var splashes:FlxTypedGroup<NoteSplash>;
	var noteY:Float = 90;
	var changedMusic:Bool = false;
	public function new() {
		title = Language.getPhrase('visuals_menu', 'Visuals Settings');
		rpcTitle = 'Visuals Settings Menu'; //for Discord Rich Presence

		// for note skins and splash skins
		notes = new FlxTypedGroup<StrumNote>();
		splashes = new FlxTypedGroup<NoteSplash>();
		for (i in 0...EK.colArray.length) {
			var note:StrumNote = new StrumNote(45 + 140 * i, -200, i, 0);
			changeNoteSkin(note);
			note.setGraphicSize(112);
			notes.add(note);

			var splash:NoteSplash = new NoteSplash(0, 0, NoteSplash.defaultNoteSplash + NoteSplash.getSplashSkinPostfix());
			splash.inEditor = true;
			splash.babyArrow = note;
			splash.ID = i;
			splash.kill();
			splashes.add(splash);
		}

		// options
		var noteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');
		if (noteSkins.length > 0) {
			if (!noteSkins.contains(ClientPrefs.data.noteSkin))
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
		}
		
		var noteSplashes:Array<String> = Mods.mergeAllTextsNamed('images/noteSplashes/list.txt');
		if (noteSplashes.length > 0) {
			if (!noteSplashes.contains(ClientPrefs.data.splashSkin))
				ClientPrefs.data.splashSkin = ClientPrefs.defaultData.splashSkin; //Reset to default if saved splashskin couldnt be found

			noteSplashes.insert(0, ClientPrefs.defaultData.splashSkin); //Default skin always comes first
			var option:Option = new Option('Note Splashes:', "Select your prefered Note Splash variation.", 'splashSkin', STRING, noteSplashes);
			addOption(option);
			option.onChange = onChangeSplashSkin;
		}

		var option:Option = new Option('Note Splash Opacity:', 'How transparent should the Note Splashes be?', 'splashAlpha', PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = .01;
		option.decimals = 2;
		addOption(option);
		option.onChange = playNoteSplashes;

		var option:Option = new Option('Note Splash Count:', 'How many Note Splashes should spawn every note hit?\n0 = No Limit.', 'splashCount', INT);
		option.scrollSpeed = 30;
		option.minValue = 0;
		option.maxValue = 15;
		option.changeValue = 1;
		addOption(option);
		option.onChange = playNoteSplashes;

		addOption(new Option('Light Strums', 'If checked, the light-up animation of strum will play every time a note is hit.', 'lightStrum'));
		addOption(new Option('Play Animation on Sustain Hit', "If unchecked, the animaiton when sustain notes are hit will not play.", 'holdAnim'));
		addOption(new Option('Hide HUD', 'If checked, hides most HUD elements.', 'hideHud'));
		addOption(new Option('Time Bar:', "What should the Time Bar display?", 'timeBarType', STRING, ['Time Left', 'Time Elapsed', 'Song Name', 'Time Position', 'Name Left', 'Name Elapsed', 'Name Time Position', 'Disabled']));
		addOption(new Option('Flashing Lights', "Uncheck this if you're sensitive to flashing lights!", 'flashing'));
		addOption(new Option('Icon Bounce:', "What should the Icon Bounces?", 'iconBounceType', STRING, ['Old', 'Psych', 'Dave', 'GoldenApple', 'Custom']));
		addOption(new Option('Health Bar Type:', "What should the Health Bar Types?", 'healthTypes', STRING, ['Vanilla', 'Psych']));
		addOption(new Option('Smooth Health', '', 'smoothHealth'));
		var option:Option = new Option('Health Bar Opacity', 'How transparent should the Health Bar and icons be?', 'healthBarAlpha', PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = .01;
		option.decimals = 2;
		addOption(option);
		addOption(new Option('Camera Zooms', "If unchecked, the camera won't zoom in on a beat hit.", 'camZooms'));
		addOption(new Option('Show NPS Display', 'If checked, Shows your current Notes Per Second on the info bar.', 'showNPS'));
		addOption(new Option('Rating Display:', 'Choose the type of rating you want to see.', 'ratingDisplay', STRING, ['Hud', 'World']));

		var option:Option = new Option('Pause Music:', "What song do you prefer for the Pause Screen?", 'pauseMusic', STRING, ['None', 'Breakfast', 'Tea Time', 'Breakfast (Dave)', 'Breakfast (Pico)']);
		addOption(option);
		option.onChange = () -> {
			if (ClientPrefs.data.pauseMusic == 'None') FlxG.sound.music.volume = 0;
			else FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));
			changedMusic = true;
		};
		#if CHECK_FOR_UPDATES addOption(new Option('Check for Updates', 'On Release builds, turn this on to check for updates when you start the game.', 'checkForUpdates')); #end
		#if desktop addOption(new Option('Discord Rich Presence', "Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord", 'discordRPC')); #end
		super();
		add(notes);
		add(splashes);
	}

	var notesShown:Bool = false;
	override function changeSelection(change:Int = 0) {
		super.changeSelection(change);
		
		switch(curOption.variable) {
			case 'noteSkin', 'splashSkin', 'splashAlpha', 'splashCount':
				if (!notesShown) {
					for (note in notes.members) {
						FlxTween.cancelTweensOf(note);
						FlxTween.tween(note, {y: noteY}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
					}
				}
				notesShown = true;
				if (curOption.variable.startsWith('splash') && Math.abs(notes.members[0].y - noteY) < 25) playNoteSplashes();
			default:
				if (notesShown)  {
					for (note in notes.members) {
						FlxTween.cancelTweensOf(note);
						FlxTween.tween(note, {y: -200}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
					}
				}
				notesShown = false;
		}
	}

	function changeNoteSkin(note:StrumNote) {
		var skin:String = Note.defaultNoteSkin;
		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if (Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

		note.texture = skin; //Load texture and anims
		note.reloadNote();
		note.playAnim('static');
	}

	function onChangeSplashSkin() {
		var skin:String = NoteSplash.defaultNoteSplash + NoteSplash.getSplashSkinPostfix();
		for (splash in splashes) splash.loadSplash(skin);
		playNoteSplashes();
	}

	function playNoteSplashes() {
		var rand:Int = 0;
		if (splashes.members[0] != null && splashes.members[0].maxAnims > 1)
			rand = FlxG.random.int(0, splashes.members[0].maxAnims - 1); // For playing the same random animation on all 4 splashes
		for (splash in splashes) {
			splash.revive();
			splash.spawnSplashNote(0, 0, splash.ID, null, false);
			if (splash.maxAnims > 1) splash.noteData = splash.noteData % EK.colArray.length + (rand * EK.colArray.length);
			var anim:String = splash.playDefaultAnim();
			var conf:NoteSplashAnim = splash.config.animations.get(anim);
			var offsets:Array<Float> = [0, 0];

			var minFps:Int = 22;
			var maxFps:Int = 26;
			if (conf != null) {
				offsets = conf.offsets;

				minFps = conf.fps[0];
				if (minFps < 0) minFps = 0;
				maxFps = conf.fps[1];
				if (maxFps < 0) maxFps = 0;
			}
			splash.offset.set(10, 10);
			if (offsets != null) splash.offset.add(offsets[0], offsets[1]);
			if (splash.animation.curAnim != null) splash.animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
		}
	}

	override function destroy() {
		if (changedMusic && !OptionsState.onPlayState) FlxG.sound.playMusic(Paths.music('freakyMenu'));
		Note.globalRgbShaders = [];
		super.destroy();
	}
}