package substates;

import flixel.graphics.FlxGraphic;
import data.WeekData;
import utils.CoolUtil;
import states.StoryMenuState;
import states.FreeplayState;
import game.Conductor;

/**
* State used to decide which selection of songs should be loaded in `FreeplayState`.
*/
class FreeplaySectionSubstate extends MusicBeatSubstate {
	public static var daSection:String = 'Vanilla';
	var counter:Int = 0;

	var sectionArray:Array<String> = [];
	var sectionImageMap:Map<String, FlxGraphic> = new Map<String, FlxGraphic>();

	var sectionSpr:FlxSprite;
	var sectionTxt:FlxText;

	var bg:FlxSprite;
	var transitioning:Bool = false;

	override public function new() {
		super();
		WeekData.reloadWeekFiles(false);

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			if(leWeek.hideFreeplay || leWeek.sections == null) continue;
			WeekData.setDirectoryFromWeek(leWeek);
			if (leWeek.sections != null) {
				for (fuck => section in leWeek.sections) {
					if (section.toLowerCase() != sectionArray[fuck].toLowerCase()) {
						sectionArray.push(section);
						sectionImageMap.set(section.toLowerCase(), Paths.image('freeplaysections/${section.toLowerCase()}'));
					}
				}
			}
		}
		sectionArray = CoolUtil.removeDuplicates(sectionArray);
		Mods.loadTopMod();

        for (i in 0...sectionArray.length) {
            if (sectionArray[i] == daSection) {
                counter = i;
                break;
            }
        }
		daSection = sectionArray[counter];

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.updateHitbox();
		bg.screenCenter();
		bg.alpha = 0;
		add(bg);

		sectionSpr = new FlxSprite().loadGraphic(sectionImageMap.get(daSection.toLowerCase()));
		sectionSpr.scrollFactor.set();
		sectionSpr.screenCenter();
		sectionSpr.alpha = 0;
		add(sectionSpr);

		sectionTxt = new FlxText(0, 620, 0, "", 32);
		sectionTxt.setFormat("Comic Sans MS Bold", 32, FlxColor.WHITE, CENTER);
		sectionTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		sectionTxt.scrollFactor.set();
		sectionTxt.screenCenter(X);
		sectionTxt.alpha = 0;
		add(sectionTxt);

		#if discord_rpc
		Discord.changePresence("Selecting a Freeplay Section", null);
		#end

		FlxTween.tween(sectionSpr, {alpha: 1}, 1, {ease: FlxEase.expoOut});
		FlxTween.tween(sectionTxt, {alpha: 1}, 1, {ease: FlxEase.expoOut});
		FlxTween.tween(bg, {alpha: 1}, 1, {ease: FlxEase.expoOut});
	}

	override function update(elapsed:Float) {
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (controls.UI_LEFT_P && !transitioning) changeSection(-1);
		if (controls.UI_RIGHT_P && !transitioning) changeSection(1);
		
		if (controls.BACK && !transitioning) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxTween.tween(bg, {alpha: 0}, .5, {ease: FlxEase.expoInOut});
			FlxTween.tween(sectionTxt, {alpha: 0}, .5, {ease: FlxEase.expoInOut});
			FlxTween.tween(sectionSpr, {alpha: 0}, .5, {ease: FlxEase.expoInOut,
				onComplete: function(tween:FlxTween) {
					daSection = FreeplayState.section;
					close();
				}
			});
		}

		if (controls.ACCEPT && !transitioning) {
			FlxG.sound.play(Paths.sound('confirmMenu'));
			transitioning = true;
			FlxTween.tween(bg, {alpha: 0}, .5, {ease: FlxEase.expoInOut});
			FlxTween.tween(sectionTxt, {alpha: 0}, .5, {ease: FlxEase.expoInOut});
			FlxTween.tween(sectionSpr, {alpha: 0}, .5, {ease: FlxEase.expoInOut,
				onComplete: function(tween:FlxTween) {
					close();
					FlxG.resetState();
				}
			});
		}

		sectionTxt.text = daSection.toUpperCase();
		sectionTxt.screenCenter(X);
		
		super.update(elapsed);
	}

	function changeSection(change:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		counter = FlxMath.wrap(counter + change, 0, sectionArray.length - 1);

		daSection = sectionArray[counter];
		sectionSpr.loadGraphic(sectionImageMap.get(daSection.toLowerCase()));
		sectionSpr.screenCenter();
		sectionSpr.scale.set(1.1, 1.1);
		sectionSpr.updateHitbox();
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}
}