package substates;

import flixel.graphics.FlxGraphic;
import data.WeekData;
import states.StoryMenuState;

class FreeplaySectionSubstate extends FlxSubState {
	public static var daSection:String = 'Vanilla';

	var counter:Int = 0;

	var sectionArray:Array<String> = [];
	var sectionImageMap:Map<String, FlxGraphic> = new Map<String, FlxGraphic>();

	var sectionSpr:FlxSprite;
	var sectionTxt:Alphabet;

	var grid:flixel.addons.display.FlxBackdrop;
	var bg:FlxSprite;
	var transitioning:Bool = false;

	override public function new() {
		super();
		WeekData.reloadWeekFiles();

		for (i in 0...WeekData.weeksList.length) {
			if (weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			if (leWeek.hideFreeplay || leWeek.section == null) continue;
			WeekData.setDirectoryFromWeek(leWeek);
			if (leWeek.section != null) {
				var curSection:String = leWeek.section;
				if (curSection.toLowerCase() != sectionArray[0].toLowerCase()) {
					sectionArray.push(curSection);
					sectionImageMap.set(curSection.toLowerCase(), Paths.image('freeplaysections/${curSection.toLowerCase()}'));
				}
			}
		}
		sectionArray = CoolUtil.removeDupString(sectionArray);
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
		bg.gameCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.alpha = 0;
		add(bg);

		grid = CoolUtil.createBackDrop(80, 80, 160, 160, true, 0x8FFFFFFF, 0x0);
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		add(grid);

		sectionSpr = new FlxSprite(sectionImageMap.get(daSection.toLowerCase()));
		sectionSpr.antialiasing = ClientPrefs.data.antialiasing;
		sectionSpr.scrollFactor.set();
		sectionSpr.gameCenter();
		sectionSpr.alpha = 0;
		add(sectionSpr);

		sectionTxt = new Alphabet(0, 0, daSection.toUpperCase());
		sectionTxt.gameCenter(X).y = sectionSpr.y;
		sectionTxt.alpha = 0;
		add(sectionTxt);

		transitioning = true;
		FlxTween.tween(bg, {alpha: 1}, 1, {ease: FlxEase.expoOut});
		FlxTween.tween(grid, {alpha: 1}, 1, {ease: FlxEase.expoOut});
		FlxTween.tween(sectionSpr, {alpha: 1}, 1, {ease: FlxEase.expoOut});
		FlxTween.tween(sectionTxt, {alpha: 1}, 1, {ease: FlxEase.expoOut, onComplete: (_:FlxTween) -> transitioning = false});
	}

	override function update(elapsed:Float) {
		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;

		final leftjustPressed:Bool = Controls.justPressed('ui_left');
		if (leftjustPressed || Controls.justPressed('ui_right')) changeSection(leftjustPressed ? -1 : 1);

		if (Controls.justPressed('back') && !transitioning) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			transitioning = true;
			closeFreeplaysection((_:FlxTween) -> {
				daSection = states.FreeplayState.section;
				close();
			}, true);
		}

		if (Controls.justPressed('accept') && !transitioning) {
			FlxG.sound.play(Paths.sound('confirmMenu'));
			transitioning = true;
			closeFreeplaysection((_:FlxTween) -> {
				close();
				FlxG.resetState();
			});
		}

		sectionTxt.text = daSection.toUpperCase();
		sectionTxt.gameCenter(X).y = sectionSpr.y;

		super.update(elapsed);
	}

	function closeFreeplaysection(func:FlxTween->Void, onlyFade:Bool = false) {
		for (obj in [bg, grid, sectionTxt]) FlxTween.tween(obj, {alpha: 0}, .5, {ease: FlxEase.expoInOut});
		FlxTween.tween(sectionSpr, onlyFade ? {alpha: 0} : {alpha: 0, y: sectionSpr.y + 200}, .5, {ease: FlxEase.expoInOut, onComplete: func});
	}

	function changeSection(change:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'));
		counter = FlxMath.wrap(counter + change, 0, sectionArray.length - 1);

		daSection = sectionArray[counter];
		sectionSpr.loadGraphic(sectionImageMap.get(daSection.toLowerCase()));
		sectionSpr.gameCenter();
		sectionSpr.updateHitbox();
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}
}
