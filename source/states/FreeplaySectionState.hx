package states;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
#if desktop
import utils.Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import data.WeekData;
import utils.CoolUtil;
import utils.MathUtil;
import utils.ClientPrefs;
import game.Conductor;

/**
* State used to decide which selection of songs should be loaded in `FreeplayState`.
*/
class FreeplaySectionState extends MusicBeatState
{
	public static var daSection:String = '';
	var counter:Int = 0;
	var sectionArray:Array<String> = [];

	var sectionSpr:FlxSprite;
	var sectionTxt:FlxText;

    var camGame:FlxCamera;

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	var bg:FlxSprite;
	var transitioning:Bool = false;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Selecting a Freeplay Section", null);
		#end

		persistentUpdate = true;
		WeekData.reloadWeekFiles(false);

		var doFunnyContinue = false;

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			if(leWeek.hideFreeplay) continue;
			if (leWeek.sections != null) {
				var fuck:Int = 0;
				if (leWeek.sections.toLowerCase() != sectionArray[fuck].toLowerCase()) {
					sectionArray.push(leWeek.sections);
				}
				fuck++;
			} else doFunnyContinue = true;
			if (doFunnyContinue) {
				doFunnyContinue = false;
				continue;
			}

			WeekData.setDirectoryFromWeek(leWeek);
		}
		sectionArray = CoolUtil.removeDuplicates(sectionArray);
		WeekData.loadTheFirstEnabledMod();

		daSection = sectionArray[0];

		camGame = new FlxCamera();

		FlxG.cameras.reset(camGame);
		FlxG.cameras.setDefaultDrawTarget(camGame, true); //new EPIC code

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set(0, 0);
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		add(bg);

		sectionSpr = new FlxSprite(0,0).loadGraphic(Paths.image('freeplaysections/' + daSection.toLowerCase()));
		sectionSpr.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		sectionSpr.scrollFactor.set();
		sectionSpr.screenCenter(XY);
		add(sectionSpr);

		sectionTxt = new FlxText(0, 0, 0, "");
		sectionTxt.scrollFactor.set();
		sectionTxt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		sectionTxt.screenCenter(X);
		sectionTxt.y += 620;
		add(sectionTxt);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, null, 1);

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8) {
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (controls.UI_LEFT_P && !transitioning)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			if (counter > 0)
				counter -= 1;
			else counter = sectionArray.length - 1;

            daSection = sectionArray[counter];
            sectionSpr.loadGraphic(Paths.image('freeplaysections/' + daSection.toLowerCase()));
            sectionSpr.scale.set(1.1, 1.1);
            sectionSpr.updateHitbox();
		}

		if (controls.UI_RIGHT_P && !transitioning) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
			if (counter < sectionArray.length - 1)
				counter += 1;
			else counter = 0;
            
            daSection = sectionArray[counter];
			trace(daSection);
            sectionSpr.loadGraphic(Paths.image('freeplaysections/' + daSection.toLowerCase()));
            sectionSpr.scale.set(1.1, 1.1);
            sectionSpr.updateHitbox();
		}
		
		if (controls.BACK && !transitioning) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if (controls.ACCEPT && !transitioning) {
			FlxG.sound.play(Paths.sound('confirmMenu'));
			transitioning = true;
			sectionTxt.visible = false;
			FlxTween.tween(bg, {'scale.x': .003, 'scale.y': .003, alpha: 0}, 1.1, {
				ease: FlxEase.expoIn,
				onComplete: function(twn:FlxTween) {
					FlxTransitionableState.skipNextTransIn = true;
					MusicBeatState.switchState(new FreeplayState());
				}
			});
		}

		sectionTxt.text = daSection.toUpperCase();
		sectionTxt.screenCenter(X);
		
		if(transitioning) {
			bg.screenCenter(XY);
		} 
		
		var lerpVal:Float = MathUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		super.update(elapsed);
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}
}