package states;

import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import options.OptionsState;

class MainMenuState extends MusicBeatState {
	public static var curSelected:Int = 0;

	var menuOptions:Array<String> = [
		"Story Mode",
		"Freeplay",
		#if MODS_ALLOWED "Mods", #end
		"Credits",
		"Options"
	];

	var menuItems:FlxTypedGroup<FlxSprite>;

	var bg:FlxSprite;
	var magenta:FlxSprite;

	//Stolen from Kade Engine
	public static var firstStart:Bool = true;
	public static var finishedFunnyMove:Bool = false;

	var bigIcons:FlxSprite;
	var curOptText:FlxText;

	override function create() {
		FlxG.mouse.visible = true;
		#if MODS_ALLOWED Mods.pushGlobalMods(); #end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED DiscordClient.changePresence("In the Menus"); #end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		bg = new FlxSprite(-80, Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.color = 0xFFFDE871;
		add(bg);
		
		magenta = new FlxSprite(-80, bg.graphic);
		magenta.antialiasing = ClientPrefs.getPref('Antialiasing');
		magenta.scrollFactor.set();
		magenta.active = false;
		magenta.setGraphicSize(Std.int(magenta.width * 1.1));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		var menuCover:FlxSprite = new FlxSprite().makeGraphic(FlxG.width - 1130, Std.int(FlxG.height));
		menuCover.alpha = .5;
		menuCover.color = FlxColor.WHITE;
		menuCover.scrollFactor.set();
		menuCover.x += 8;
		add(menuCover);

		var menuCoverAlt:FlxSprite = new FlxSprite().makeGraphic(Std.int(menuCover.width - 20), Std.int(menuCover.height));
		menuCoverAlt.setPosition(menuCover.x + 10, menuCover.y);
		menuCoverAlt.alpha = .7;
		menuCoverAlt.color = FlxColor.BLACK;
		menuCoverAlt.scrollFactor.set();
		add(menuCoverAlt);

		bigIcons = new FlxSprite();
		bigIcons.frames = Paths.getSparrowAtlas('mainmenu/menu_big_icons');
		for (i in 0...menuOptions.length)
			bigIcons.animation.addByPrefix(menuOptions[i].toLowerCase(), menuOptions[i].toLowerCase(), 24);
		bigIcons.scrollFactor.set();
		bigIcons.antialiasing = true;
		bigIcons.updateHitbox();
		bigIcons.animation.play(menuOptions[0].toLowerCase());
		bigIcons.screenCenter(X);
		add(bigIcons);

		curOptText = new FlxText(0, 0, FlxG.width, menuOptions[curSelected], 48);
		curOptText.setFormat(Paths.font('babyshark.ttf'), 48, FlxColor.WHITE, CENTER);
		curOptText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2.5);
		curOptText.scrollFactor.set();
		curOptText.screenCenter(X);
		curOptText.y = FlxG.height / 2 + 28;
		add(curOptText);

		add(menuItems = new FlxTypedGroup<FlxSprite>());

		for (i in 0...menuOptions.length) {
			var currentOptionShit = menuOptions[i].toLowerCase();
			var menuItem:FlxSprite = new FlxSprite(-160, (i * 140));
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/main_menu_icons');
			menuItem.animation.addByPrefix('idle', '$currentOptionShit basic', 24);
			menuItem.animation.addByPrefix('selected', '$currentOptionShit white', 24);
			menuItem.animation.play('idle');
			menuItem.antialiasing = false;
			menuItem.setGraphicSize(128, 128);
			menuItem.updateHitbox();
			menuItems.add(menuItem);
			menuItem.scrollFactor.set();
			if (firstStart)
				FlxTween.tween(menuItem, {x: 20}, 1 + (i * .25), {
					ease: FlxEase.expoInOut,
					onComplete: (flxTween:FlxTween) -> finishedFunnyMove = true
				});
			else menuItem.x = 20;
		}
		firstStart = false;

		changeItem();
		super.create();
	}

	var selectedSomethin:Bool = false;
	override function update(elapsed:Float) {
		if (FlxG.sound.music.volume < .8) {
			FlxG.sound.music.volume += .5 * elapsed;
			if(FreeplayState.vocals != null) FreeplayState.vocals.volume += .5 * elapsed;
		}
		
		if (!selectedSomethin && finishedFunnyMove) {
			if (controls.UI_UP_P || controls.UI_DOWN_P)
				changeItem(controls.UI_UP_P ? -1 : 1);

			for (item in menuItems.members) {
				final itemIndex:Int = menuItems.members.indexOf(item);

				if (FlxG.mouse.overlaps(item) && curSelected != itemIndex) {
					curSelected = itemIndex;
					changeItem();
					break;
				}
			}

			if (controls.BACK) {
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'), .7);
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT || (FlxG.mouse.overlaps(menuItems.members[curSelected]) && FlxG.mouse.justPressed)) {
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'), .7);

				if(ClientPrefs.getPref('flashing')) FlxFlicker.flicker(magenta, 1.1, .15, false);

				for (item in menuItems.members) {
					final itemIndex:Int = menuItems.members.indexOf(item);

					if (curSelected != itemIndex)
						FlxTween.tween(item, {alpha: 0}, 1.3, {ease: FlxEase.quadOut, onComplete: (twn:FlxTween) -> item.destroy()});
					else {
						FlxFlicker.flicker(item, 1, .06, false, false, (flicker:FlxFlicker) -> {
							switch (menuOptions[curSelected].toLowerCase()) {
								case 'story_mode': MusicBeatState.switchState(new StoryMenuState());
								case 'freeplay': MusicBeatState.switchState(new FreeplayState());
								#if MODS_ALLOWED case 'mods': MusicBeatState.switchState(new ModsMenuState()); #end
								case 'credits': MusicBeatState.switchState(new CreditsState());
								case 'options':
									MusicBeatState.switchState(new OptionsState());
									OptionsState.onPlayState = false;
									if (PlayState.SONG != null) {
										PlayState.SONG.arrowSkin = null;
										PlayState.SONG.splashSkin = null;
										PlayState.stageUI = 'normal';
									}
							}
							FlxG.mouse.visible = false;
						});
					}
				}
			} else if (controls.justPressed('debug_1')) {
				selectedSomethin = true;
				MusicBeatState.switchState(new states.editors.MasterEditorMenu());
			}
		}

		super.update(elapsed);
	}

	function changeItem(huh:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'));
		if (finishedFunnyMove) curSelected = FlxMath.wrap(curSelected + huh, 0, menuItems.length - 1);

		for (item in menuItems.members) {
			final itemIndex:Int = menuItems.members.indexOf(item);

			if (curSelected != itemIndex) {
				item.animation.play('idle', true);
				item.updateHitbox();
			} else {
				item.animation.play('selected');
				item.centerOffsets();
			}
		}

		bigIcons.animation.play(menuOptions[curSelected].toLowerCase());
		curOptText.text = menuOptions[curSelected];
	}
}
