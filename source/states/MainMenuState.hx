package states;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.display.FlxBackdrop;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import game.Achievements;
import editors.MasterEditorMenu;
import utils.ClientPrefs;
import utils.MathUtil;
#if desktop
import utils.Discord.DiscordClient;
#end
import data.WeekData;

class MainMenuState extends MusicBeatState
{
	final BabySharkVersion:String = '1.0'; //This is also used for Discord RPC
	public static var alterEngineVersion:String = '1.0'; //This is also used for Discord RPC
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
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	//Stolen from Kade Engine
	public static var firstStart:Bool = true;
	public static var finishedFunnyMove:Bool = false;

	override function create()
	{
		#if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end
		WeekData.loadTheFirstEnabledMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.keyBinds.get('debug_1').copy();

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var globalAntialiasing:Bool = ClientPrefs.getPref('globalAntialiasing');

		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = globalAntialiasing;
		add(bg);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);
		
		var bg:FlxBackdrop = new FlxBackdrop(Paths.image('thechecker'));
		bg.scrollFactor.set(0, yScroll);
		bg.velocity.set(30, 110);
		bg.alpha = .3;
		bg.color = FlxColor.PURPLE;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = globalAntialiasing;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		var menuCover:FlxSprite = new FlxSprite().makeGraphic(FlxG.width - 680, Std.int(FlxG.height * 1.5));
		menuCover.x = 30;
		menuCover.screenCenter(Y);
		menuCover.alpha = 0.5;
		menuCover.color = FlxColor.WHITE;
		menuCover.angle = -15;
		menuCover.scrollFactor.set(0, yScroll);
		add(menuCover);

		var menuCoverAlt:FlxSprite = new FlxSprite().makeGraphic(Std.int(menuCover.width - 20), Std.int(menuCover.height));
		menuCoverAlt.setPosition(menuCover.x + 10, menuCover.y);
		menuCoverAlt.angle = menuCover.angle;
		menuCoverAlt.alpha = 0.7;
		menuCoverAlt.color = FlxColor.BLACK;
		menuCoverAlt.scrollFactor.set(0, yScroll);
		add(menuCoverAlt);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

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
			menuItem.antialiasing = globalAntialiasing;
			menuItem.updateHitbox();
			menuItem.scale.set(.7, .7);
			var offsetMenuItem:Float = (20 + (i * 80)) - offset;
			if (firstStart)
				FlxTween.tween(menuItem, {x: offsetMenuItem, y: (i * 140) + offset}, 1 + (i * 0.25), {
					ease: FlxEase.expoInOut,
					onComplete: function(flxTween:FlxTween) {
						finishedFunnyMove = true;
						changeItem();
					}
				});
			else menuItem.setPosition(offsetMenuItem, (i * 140) + offset);
		}

		firstStart = false;

		FlxG.camera.follow(camFollowPos, null, 1);

		var versionShit:FlxText = new FlxText(0, 0, 0, 
			'Alter Engine v$alterEngineVersion (${Main.COMMIT_HASH.trim().substring(0, 7)})\n' +
			'Baby Shark\'s Funkin\' v$BabySharkVersion\n',
			12);
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
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
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float) {
		if (FlxG.sound.music.volume < 0.8) {
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			if(FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		var lerpVal:Float = MathUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin && finishedFunnyMove) {
			if (controls.UI_UP_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK) {
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			var numMenu = 0;
			if (controls.ACCEPT) {
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));

				if(ClientPrefs.getPref('flashing')) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

				menuItems.forEach(function(spr:FlxSprite) {
					if (curSelected != spr.ID) {
						numMenu++;
						FlxTween.tween(spr, {alpha: 0, x: -100 + spr.x}, .1 * numMenu, {
							ease: FlxEase.quadOut,
							onComplete: function(twn:FlxTween) {
								spr.kill();
							}
						});
					} else {
						FlxTween.tween(spr, {"scale.x": .9, "scale.y": .9}, .4, {ease: FlxEase.sineInOut});
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
								case 'options': LoadingState.loadAndSwitchState(new options.OptionsState());
							}
						});
					}
				});
			} else if (FlxG.keys.anyJustPressed(debugKeys)) {
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
				if(menuItems.length > 4) {
					add = menuItems.length * 8;
				}
				var mid = spr.getGraphicMidpoint();
				camFollow.setPosition(mid.x, mid.y - add);
				mid.put();
				spr.centerOffsets();
			}
		});
	}
}
