package states;

import shaders.WiggleEffect.WiggleEffect;
import shaders.WiggleEffect.WiggleEffectType;
#if desktop
import utils.Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import game.Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var BabySharkVersion:String = '0.1 BETA'; //This is also used for Discord RPC
	public static var psychEngineVersion:String = '0.6.2'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		'options'
	];

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	var WShader:WiggleEffect = new WiggleEffect();

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
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		WShader.effectType = WiggleEffectType.HEAT_WAVE_HORIZONTAL;
		WShader.waveAmplitude = 0.007;
		WShader.waveFrequency = 70;
		WShader.waveSpeed = 0.9;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var globalAntialiasing:Bool = ClientPrefs.getPref('globalAntialiasing');

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('3dMenu'));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		if (ClientPrefs.getPref('shaders'))
			bg.shader = WShader.shader;
		bg.antialiasing = globalAntialiasing;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		var menuCover:FlxSprite = new FlxSprite().makeGraphic(FlxG.width - 480, FlxG.height * 2);
		menuCover.alpha = 0.5;
		menuCover.color = FlxColor.WHITE;
		menuCover.scrollFactor.set();
		add(menuCover);

		var menuCover:FlxSprite = new FlxSprite().makeGraphic(FlxG.width - 500, FlxG.height * 2);
		menuCover.alpha = 0.7;
		menuCover.color = FlxColor.BLACK;
		menuCover.scrollFactor.set();
		add(menuCover);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
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
			if (firstStart)
				FlxTween.tween(menuItem, {y: (i * 140) + offset}, 1 + (i * 0.25), {
					ease: FlxEase.expoInOut,
					onComplete: function(flxTween:FlxTween)
					{
						finishedFunnyMove = true;
						changeItem();
					}
				});
			else
				menuItem.y = (i * 140) + offset;
		}

		firstStart = false;

		FlxG.camera.follow(camFollowPos, null, 1);

		var versionShit:FlxText = new FlxText(FlxG.width - 280, FlxG.height - 36, 0, 
			'Alter Engine (PE v$psychEngineVersion)\n' +
			'Baby Shark\'s Funkin\' v$BabySharkVersion\n',
			12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
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

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			if(FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (ClientPrefs.getPref('shaders'))
			WShader.update(elapsed * 2);

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT) {
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));
				menuItems.forEach(function(spr:FlxSprite) {
					if (curSelected != spr.ID) {
						FlxTween.tween(spr, {alpha: 0}, 0.4, {
							ease: FlxEase.quadOut,
							onComplete: function(twn:FlxTween) {
								spr.kill();
							}
						});
					} else {
						FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker) {
							var daChoice:String = optionShit[curSelected];
							switch (daChoice) {
								case 'story_mode':
									MusicBeatState.switchState(new StoryMenuState());
								case 'freeplay':
									MusicBeatState.switchState(new FreeplayState());
								#if MODS_ALLOWED
								case 'mods':
									MusicBeatState.switchState(new ModsMenuState());
								#end
								case 'awards':
									MusicBeatState.switchState(new AchievementsMenuState());
								case 'credits':
									MusicBeatState.switchState(new CreditsState());
								case 'options':
									LoadingState.loadAndSwitchState(new options.OptionsState());
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

	function changeItem(huh:Int = 0)
	{
		if (finishedFunnyMove) {
			curSelected += huh;

			if (curSelected >= menuItems.length)
				curSelected = 0;
			if (curSelected < 0)
				curSelected = menuItems.length - 1;
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
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
			}
		});
	}
}
