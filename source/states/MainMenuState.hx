package states;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import game.Achievements;

class MainMenuState extends MusicBeatState
{
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	var camGame:FlxCamera;
	var camAchievement:FlxCamera;
	
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		'options'
	];

	var bg:FlxSprite;
	var magenta:FlxSprite;

	var camFollow:FlxObject;

	//Stolen from Kade Engine
	public static var firstStart:Bool = true;
	public static var finishedFunnyMove:Bool = false;

	override function create()
	{
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if discord_rpc
		// Updating Discord Rich Presence
		Discord.changePresence("In the Menus", null);
		#end

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(.25 - (.05 * (optionShit.length - 4)), .1);

		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.color = 0xFFFDE871;
		add(bg);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		add(camFollow = new FlxObject(0, 0, 1, 1));

		var menuCover:FlxSprite = new FlxSprite().makeGraphic(FlxG.width - 680, Std.int(FlxG.height * 1.5));
		menuCover.x = 30;
		menuCover.screenCenter(Y);
		menuCover.alpha = .5;
		menuCover.color = FlxColor.WHITE;
		menuCover.scrollFactor.set(0, yScroll);
		add(menuCover);

		var menuCoverAlt:FlxSprite = new FlxSprite().makeGraphic(Std.int(menuCover.width - 20), Std.int(menuCover.height));
		menuCoverAlt.setPosition(menuCover.x + 10, menuCover.y);
		menuCoverAlt.alpha = .7;
		menuCoverAlt.color = FlxColor.BLACK;
		menuCoverAlt.scrollFactor.set(0, yScroll);
		add(menuCoverAlt);

		add(menuItems = new FlxTypedGroup<FlxSprite>());

		for (i in 0...optionShit.length) {
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(100, FlxG.height * 1.6);
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItems.add(menuItem);

			var scr:Float = (optionShit.length - 4) * 0.135;
			if(optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.updateHitbox();
			menuItem.scale.set(.7, .7);
			if (firstStart)
				FlxTween.tween(menuItem, {y: (i * 140) + offset}, 1 + (i * 0.25), {
					ease: FlxEase.expoInOut,
					onComplete: function(flxTween:FlxTween) {
						finishedFunnyMove = true;
						changeItem();
					}
				});
			else menuItem.setPosition(100, (i * 140) + offset);
		}
		firstStart = false;

		FlxG.camera.follow(camFollow, null, 0);

		var versionShit:FlxText = new FlxText(0, 0, 0, 
			'Alter Engine v${Main.engineVersion.version} (${Main.COMMIT_HASH.trim().substring(0, 7)})\n' +
			'Baby Shark\'s Funkin\' v${FlxG.stage.application.meta.get('version')}\n' +
			'${FlxG.VERSION.toString()}\n', 16);
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, RIGHT);
		versionShit.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		versionShit.scrollFactor.set();
		versionShit.setPosition(FlxG.width - versionShit.width, FlxG.height - versionShit.height);
		add(versionShit);

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), .7);
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float) {
		if (FlxG.sound.music.volume < .8) {
			FlxG.sound.music.volume += .5 * elapsed;
			if(FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
		}
		FlxG.camera.followLerp = FlxMath.bound(elapsed * 9 / (FlxG.updateFramerate / 60), 0, 1);
		
		if (!selectedSomethin && finishedFunnyMove) {
			if (controls.UI_UP_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'), .7);
				changeItem(-1);
			}

			if (controls.UI_DOWN_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'), .7);
				changeItem(1);
			}

			if (controls.BACK) {
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'), .7);
				MusicBeatState.switchState(new TitleState());
			}

			var numMenu = 0;
			if (controls.ACCEPT) {
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'), .7);

				if(ClientPrefs.getPref('flashing')) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

				menuItems.forEach(function(spr:FlxSprite) {
					if (curSelected != spr.ID) {
						numMenu++;
						FlxTween.tween(spr, {alpha: 0, y: spr.y + 40}, .1 * numMenu, {
							ease: FlxEase.quadOut,
							onComplete: function(twn:FlxTween) {
								spr.kill();
							}
						});
					} else {
						FlxFlicker.flicker(spr, 1, .06, false, false, function(flick:FlxFlicker) {
							var daChoice:String = optionShit[curSelected];
							switch (daChoice) {
								case 'story_mode': MusicBeatState.switchState(new StoryMenuState());
								case 'freeplay': MusicBeatState.switchState(new FreeplayState());
								#if MODS_ALLOWED
								case 'mods': MusicBeatState.switchState(new ModsMenuState());
								#end
								case 'awards': MusicBeatState.switchState(new AchievementsMenuState());
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
		if (finishedFunnyMove) {
			curSelected = FlxMath.wrap(curSelected + huh, 0, menuItems.length - 1);
		}
		menuItems.forEach(function(spr:FlxSprite) {
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected && finishedFunnyMove) {
				spr.animation.play('selected');
				var add:Float = 0;
				if(menuItems.length > 4)
					add = menuItems.length * 8;
				var mid = spr.getGraphicMidpoint();
				camFollow.setPosition(mid.x, mid.y - add);
				mid.put();
				spr.centerOffsets();
			}
		});
	}
}
