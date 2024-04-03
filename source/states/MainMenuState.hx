package states;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import options.OptionsState;

enum MainMenuColumn {
	CENTER;
	RIGHT;
}

class MainMenuState extends MusicBeatState {
	public static var curSelected:Int = 0;
	public static var curColumn:MainMenuColumn = CENTER;

	var menuItems:FlxTypedGroup<FlxSprite>;
	var rightItem:FlxSprite;

	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		'credits'
	];


	var rightOption:String = 'options';

	var magenta:FlxSprite;
	var camFollow:FlxObject;

	// Stolen from Kade Engine
	public static var firstStart:Bool = true;
	public static var finishedFunnyMove:Bool = false;

	override function create() {
		#if MODS_ALLOWED Mods.pushGlobalMods(); #end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED DiscordClient.changePresence("In the Menus"); #end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = .25;
		var bg:FlxSprite = new FlxSprite(-80, Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.color = 0xFFFDE871;
		add(bg);
		
		add(camFollow = new FlxObject(0, 0, 1, 1));

		magenta = new FlxSprite(-80, bg.graphic);
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scrollFactor.set(0, yScroll);
		magenta.active = false;
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		var menuCover:FlxSprite = new FlxSprite().makeGraphic(FlxG.width - 500, Std.int(FlxG.height));
		menuCover.alpha = .5;
		menuCover.color = FlxColor.WHITE;
		menuCover.scrollFactor.set();
		menuCover.screenCenter(X);
		add(menuCover);

		var menuCoverAlt:FlxSprite = new FlxSprite().makeGraphic(Std.int(menuCover.width - 20), Std.int(menuCover.height));
		menuCoverAlt.setPosition(menuCover.x + 10, menuCover.y);
		menuCoverAlt.alpha = .7;
		menuCoverAlt.color = FlxColor.BLACK;
		menuCoverAlt.scrollFactor.set();
		add(menuCoverAlt);

		add(menuItems = new FlxTypedGroup<FlxSprite>());

		for (num => option in optionShit) {
			var menuY:Float = (num * 140) + 90;
			var item:FlxSprite = createMenuItem(option, 0, FlxG.height * 1.6);
			item.screenCenter(X);

			if (firstStart) FlxTween.tween(item, {y: menuY}, 1 + (num * .25), {ease: FlxEase.expoInOut, onComplete: (flxTween:FlxTween) -> finishedFunnyMove = true});
			else item.y = menuY;
			item.y += (4 - optionShit.length) * 70;
		}

		if (rightOption != null) {
			rightItem = createMenuItem(rightOption, FlxG.width - 60, 490);
			rightItem.x -= rightItem.width;
		}
		firstStart = false;

		var version:FlxText = new FlxText(0, 0, 0, 'Alter Engine v${Main.engineVer.version} (${Main.engineVer.COMMIT_HASH}, ${Main.engineVer.COMMIT_NUM})\nBaby Shark\'s Big Funkin! v${FlxG.stage.application.meta.get('version')}', 16);
		version.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, RIGHT);
		version.setBorderStyle(OUTLINE, FlxColor.BLACK);
		version.scrollFactor.set();
		version.setPosition(FlxG.width - version.width, FlxG.height - version.height);
		add(version);
		changeItem();

		super.create();
		FlxG.camera.follow(camFollow, null, 9);
	}

	function createMenuItem(name:String, x:Float, y:Float):FlxSprite {
		var menuItem:FlxSprite = new FlxSprite(x, y);
		menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_$name');
		menuItem.animation.addByPrefix('idle', '$name idle', 24, true);
		menuItem.animation.addByPrefix('selected', '$name selected', 24, true);
		menuItem.animation.play('idle');
		menuItem.updateHitbox();
		
		menuItem.antialiasing = ClientPrefs.data.antialiasing;
		menuItem.scrollFactor.set();
		menuItems.add(menuItem);
		return menuItem;
	}

	var selectedSomethin:Bool = false;
	override function update(elapsed:Float) {
		if (FlxG.sound.music.volume < .8) {
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + .5 * elapsed, .8);
			if(FreeplayState.vocals != null) FreeplayState.vocals.volume += .5 * elapsed;
		}
		
		if (!selectedSomethin && finishedFunnyMove) {
			if (controls.UI_UP_P || controls.UI_DOWN_P) changeItem(controls.UI_UP_P ? -1 : 1);

			switch(curColumn) {
				case CENTER:
					if(controls.UI_RIGHT_P && rightOption != null) {
						curColumn = RIGHT;
						changeItem();
					}

				case RIGHT:
					if(controls.UI_LEFT_P) {
						curColumn = CENTER;
						changeItem();
					}
			}

			if (controls.BACK) {
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'), .7);
				FlxG.switchState(() -> new TitleState());
			}

			if (controls.ACCEPT) {
				FlxG.sound.play(Paths.sound('confirmMenu'));
				selectedSomethin = true;

				if(ClientPrefs.data.flashing) FlxFlicker.flicker(magenta, 1.1, .15, false);

				var item:FlxSprite;
				var option:String;
				switch(curColumn) {
					case CENTER:
						option = optionShit[curSelected];
						item = menuItems.members[curSelected];
					case RIGHT:
						option = rightOption;
						item = rightItem;
				}

				FlxFlicker.flicker(item, 1, .06, false, false, (flicker:FlxFlicker) -> {
					switch (option) {
						case 'story_mode': FlxG.switchState(() -> new StoryMenuState());
						case 'freeplay': FlxG.switchState(() -> new FreeplayState());
						#if MODS_ALLOWED case 'mods': FlxG.switchState(() -> new ModsMenuState()); #end
						case 'credits': FlxG.switchState(() -> new CreditsState());
						case 'options':
							FlxG.switchState(() -> new OptionsState());
							OptionsState.onPlayState = false;
							if (PlayState.SONG != null) {
								PlayState.SONG.arrowSkin = null;
								PlayState.SONG.splashSkin = null;
								PlayState.stageUI = 'normal';
							}
					}
				});

				for (memb in menuItems) {
					if(memb == item) continue;
					FlxTween.tween(memb, {alpha: 0}, .4, {ease: FlxEase.quadOut});
				}
			}
			if (controls.justPressed('debug_1')) {
				selectedSomethin = true;
				FlxG.switchState(() -> new states.editors.MasterEditorMenu());
			}
		}

		super.update(elapsed);
	}

	function changeItem(change:Int = 0) {
		if(change != 0) curColumn = CENTER;
		if (finishedFunnyMove) curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'));

		for (item in menuItems) {
			item.animation.play('idle');
			item.centerOffsets();
		}

		var selectedItem:FlxSprite;
		switch(curColumn) {
			case CENTER: selectedItem = menuItems.members[curSelected];
			case RIGHT: selectedItem = rightItem;
		}
		selectedItem.animation.play('selected');
		selectedItem.centerOffsets();
		camFollow.y = selectedItem.getGraphicMidpoint().y;
	}
}
