package states;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import states.editors.MasterEditorMenu;
import options.OptionsState;

class MainMenuState extends MusicBeatState {
	public static var curSelected:Int = 0;

	var menuOptions:Array<String> = [
		"Story Mode",
		"Freeplay",
		"Mods",
		"Credits",
		"Options"
	];
	var menuDescription:Array<String> = [
		"Play the story mode to understand the story!",
		"Play any song as you wish and get new scores!",
		"Choose any mods as you can play mods!",
		"Look at the people who have worked or contributed to the mod!",
		"Adjust game settings."
	];

	var menuItems:FlxTypedGroup<FlxSprite>;
	
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		'credits',
		'options'
	];

	var bg:FlxSprite;
	var magenta:FlxSprite;

	//Stolen from Kade Engine
	public static var firstStart:Bool = true;
	public static var finishedFunnyMove:Bool = false;

	var bigIcons:FlxSprite;
	var curOptText:FlxText;
	var curOptDesc:FlxText;

	override function create() {
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if discord_rpc
		// Updating Discord Rich Presence
		Discord.changePresence("In the Menus", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.color = 0xFFFDE871;
		add(bg);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set();
		magenta.setGraphicSize(Std.int(magenta.width * 1.1));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		var menuCover:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width), FlxG.height - 500);
		menuCover.alpha = .5;
		menuCover.color = FlxColor.WHITE;
		menuCover.scrollFactor.set();
		menuCover.screenCenter();
		menuCover.y += 200;
		add(menuCover);

		var menuCoverAlt:FlxSprite = new FlxSprite().makeGraphic(Std.int(menuCover.width), Std.int(menuCover.height  - 20));
		menuCoverAlt.setPosition(menuCover.x, menuCover.y + 10);
		menuCoverAlt.alpha = .7;
		menuCoverAlt.color = FlxColor.BLACK;
		menuCoverAlt.scrollFactor.set();
		add(menuCoverAlt);

		bigIcons = new FlxSprite();
		bigIcons.frames = Paths.getSparrowAtlas('mainmenu/menu_big_icons');
		for (i in 0...optionShit.length)
			bigIcons.animation.addByPrefix(optionShit[i], optionShit[i] == 'freeplay' ? 'freeplay0' : optionShit[i], 24);
		bigIcons.scrollFactor.set();
		bigIcons.antialiasing = true;
		bigIcons.updateHitbox();
		bigIcons.animation.play(optionShit[0]);
		bigIcons.screenCenter(X);
		add(bigIcons);

		curOptText = new FlxText(0, 0, FlxG.width, menuOptions[curSelected], 48);
		curOptText.setFormat("VCR OSD Mono", 48, FlxColor.WHITE, CENTER);
		curOptText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2.5);
		curOptText.scrollFactor.set();
		curOptText.screenCenter(X);
		curOptText.y = FlxG.height / 2 + 28;
		add(curOptText);

		curOptDesc = new FlxText(0, 0, FlxG.width, menuDescription[curSelected], 24);
		curOptDesc.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, CENTER);
		curOptDesc.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		curOptDesc.scrollFactor.set();
		curOptDesc.screenCenter(X);
		curOptDesc.y = FlxG.height - 58;
		add(curOptDesc);

		add(menuItems = new FlxTypedGroup<FlxSprite>());

		for (i in 0...optionShit.length) {
			var currentOptionShit = optionShit[i];
			var menuItem:FlxSprite = new FlxSprite(FlxG.width * 1.6, FlxG.height / 2 + 130);
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/main_menu_icons');
			menuItem.animation.addByPrefix('idle', '$currentOptionShit basic', 24);
			menuItem.animation.addByPrefix('selected', '$currentOptionShit white', 24);
			menuItem.animation.play('idle');
			menuItem.antialiasing = false;
			menuItem.setGraphicSize(128, 128);
			menuItem.ID = i;
			menuItem.updateHitbox();
			menuItems.add(menuItem);
			menuItem.scrollFactor.set(0, 1);
			if (firstStart)
				FlxTween.tween(menuItem, {x: FlxG.width / 2 - 450 + (i * 160)}, 1 + (i * .25), {
					ease: FlxEase.expoInOut,
					onComplete: (flxTween:FlxTween) -> {
						finishedFunnyMove = true;
						changeItem();
					}
				});
			else {
				menuItem.x = FlxG.width / 2 - 450 + (i * 160);
				changeItem();
			}
		}
		firstStart = false;

		var versionShit:FlxText = new FlxText(0, 0, 0, 
			'Alter Engine v${Main.engineVer.version} (${Main.engineVer.COMMIT_HASH.trim().substring(0, 7)})\n' +
			'Baby Shark\'s Funkin\' v${FlxG.stage.application.meta.get('version')}\n', 16);
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, RIGHT);
		versionShit.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		versionShit.scrollFactor.set();
		versionShit.setPosition(FlxG.width - versionShit.width, FlxG.height - versionShit.height);
		add(versionShit);

		changeItem();

		super.create();
	}

	var selectedSomethin:Bool = false;
	override function update(elapsed:Float) {
		if (FlxG.sound.music.volume < .8) {
			FlxG.sound.music.volume += .5 * elapsed;
			if(FreeplayState.vocals != null) FreeplayState.vocals.volume += .5 * elapsed;
		}
		FlxG.camera.followLerp = FlxMath.bound(elapsed * 9 / (FlxG.updateFramerate / 60), 0, 1);
		
		if (!selectedSomethin && finishedFunnyMove) {
			if (controls.UI_LEFT_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'), .7);
				changeItem(-1);
			}
			if (controls.UI_RIGHT_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'), .7);
				changeItem(1);
			}

			if(FlxG.mouse.wheel != 0) {
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				changeItem(-FlxG.mouse.wheel);
			}

			if (controls.BACK) {
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'), .7);
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT) {
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'), .7);

				if(ClientPrefs.getPref('flashing')) FlxFlicker.flicker(magenta, 1.1, .15, false);

				menuItems.forEach(function(spr:FlxSprite) {
					if (curSelected != spr.ID) {
						FlxTween.tween(spr, {alpha: 0}, 1.3, {
							ease: FlxEase.quadOut, onComplete: (twn:FlxTween) -> spr.kill()
						});
					} else {
						FlxFlicker.flicker(spr, 1, .06, false, false, (flick:FlxFlicker) -> {
							var daChoice:String = optionShit[curSelected];
							switch (daChoice) {
								case 'story_mode': MusicBeatState.switchState(new StoryMenuState());
								case 'freeplay': MusicBeatState.switchState(new FreeplayState());
								#if MODS_ALLOWED
								case 'mods': MusicBeatState.switchState(new ModsMenuState());
								#end
								case 'credits': MusicBeatState.switchState(new CreditsState());
								case 'options':
									LoadingState.loadAndSwitchState(new OptionsState());
									OptionsState.onPlayState = false;
									if (PlayState.SONG != null) {
										PlayState.SONG.arrowSkin = null;
										PlayState.SONG.splashSkin = null;
									}
							}
						});
					}
				});
			} else if (controls.justPressed('debug_1')) {
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
		}

		super.update(elapsed);
	}

	function changeItem(huh:Int = 0) {
		if (finishedFunnyMove) curSelected = FlxMath.wrap(curSelected + huh, 0, menuItems.length - 1);
		menuItems.forEach(function(spr:FlxSprite) {
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected && finishedFunnyMove)
				spr.animation.play('selected');
			spr.updateHitbox();
		});

		bigIcons.animation.play(optionShit[curSelected]);
		curOptText.text = menuOptions[curSelected];
		curOptDesc.text = menuDescription[curSelected];
	}
}
