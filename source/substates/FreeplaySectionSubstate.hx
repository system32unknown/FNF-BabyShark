package substates;

import flixel.addons.display.FlxBackdrop;
import flixel.graphics.FlxGraphic;
import data.WeekData;
import states.StoryMenuState;

class FreeplaySectionSubstate extends MusicBeatSubstate {
	public static var daSection:String = 'Vanilla';
	var counter:Int = 0;

	var sectionArray:Array<String> = [];
	var sectionImageMap:Map<String, FlxGraphic> = new Map<String, FlxGraphic>();

	var sectionSpr:FlxSprite;
	var sectionTxt:FlxText;

	var grid:FlxBackdrop;
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

		bg = new FlxSprite(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.getPref('Antialiasing');
		bg.alpha = 0;
		add(bg);

		grid = CoolUtil.createBackDrop(80, 80, 160, 160, true, 0x8FFFFFFF, 0x0);
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		add(grid);

		sectionSpr = new FlxSprite(sectionImageMap.get(daSection.toLowerCase()));
		sectionSpr.antialiasing = ClientPrefs.getPref('Antialiasing');
		sectionSpr.scrollFactor.set();
		sectionSpr.screenCenter();
		sectionSpr.y -= 200;
		sectionSpr.alpha = 0;
		add(sectionSpr);

		sectionTxt = new FlxText(0, 620, 0, "", 32);
		sectionTxt.setFormat(Paths.font("babyshark.ttf"), 32, FlxColor.WHITE, CENTER);
		sectionTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		sectionTxt.scrollFactor.set();
		sectionTxt.screenCenter(X);
		sectionTxt.y -= 200;
		sectionTxt.alpha = 0;
		add(sectionTxt);

		transitioning = true;
		FlxTween.tween(bg, {alpha: 1}, 1, {ease: FlxEase.expoOut, onComplete: (_:FlxTween) -> transitioning = false});
		FlxTween.tween(grid, {alpha: 1}, 1, {ease: FlxEase.expoOut});
		FlxTween.tween(sectionSpr, {alpha: 1, y: sectionSpr.y + 200}, 1, {ease: FlxEase.expoOut});
		FlxTween.tween(sectionTxt, {alpha: 1, y: sectionTxt.y + 200}, 1, {ease: FlxEase.expoOut});
		#if DISCORD_ALLOWED DiscordClient.changePresence("Selecting a Freeplay Section", '${sectionArray.length} Sections'); #end
	}

	override function update(elapsed:Float) {
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if ((controls.UI_LEFT_P || controls.UI_RIGHT_P) && !transitioning) changeSection(controls.UI_LEFT_P ? -1 : 1);
		
		if (controls.BACK && !transitioning) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxTween.tween(bg, {alpha: 0}, .5, {ease: FlxEase.expoInOut});
			FlxTween.tween(grid, {alpha: 0}, .5, {ease: FlxEase.expoInOut});
			FlxTween.tween(sectionTxt, {alpha: 0, y: sectionTxt.y - 200}, .5, {ease: FlxEase.expoInOut});
			FlxTween.tween(sectionSpr, {alpha: 0, y: sectionSpr.y - 200}, .5, {ease: FlxEase.expoInOut,
				onComplete: (tween:FlxTween) -> {
					daSection = states.FreeplayState.section;
					close();
				}
			});
		}

		if (controls.ACCEPT && !transitioning) {
			FlxG.sound.play(Paths.sound('confirmMenu'));
			transitioning = true;
			FlxTween.tween(bg, {alpha: 0}, .5, {ease: FlxEase.expoInOut});
			FlxTween.tween(grid, {alpha: 0}, .5, {ease: FlxEase.expoInOut});
			FlxTween.tween(sectionTxt, {alpha: 0, y: sectionTxt.y - 200}, .5, {ease: FlxEase.expoInOut});
			FlxTween.tween(sectionSpr, {alpha: 0, y: sectionSpr.y - 200}, .5, {ease: FlxEase.expoInOut,
				onComplete: (tween:FlxTween) -> {
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