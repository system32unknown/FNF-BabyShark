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

	// Track last section to avoid doing expensive text/center work every frame
	var lastShownSection:String = null;

	override public function create() {
		super.create();

		WeekData.reloadWeekFiles();
		buildSections();

		Mods.loadTopMod();

		// Pick initial counter based on saved daSection (fallback to 0)
		counter = 0;
		for (i in 0...sectionArray.length) {
			if (sectionArray[i] == daSection) {
				counter = i;
				break;
			}
		}
		daSection = sectionArray.length > 0 ? sectionArray[counter] : daSection;

		bg = new FlxSprite(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.updateHitbox();
		bg.gameCenter();
		bg.antialiasing = Settings.data.antialiasing;
		bg.alpha = 0;
		add(bg);

		grid = Util.createBackDrop(80, 80, 160, 160, true, 0x8FFFFFFF, 0x0);
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		add(grid);

		sectionSpr = new FlxSprite();
		sectionSpr.antialiasing = Settings.data.antialiasing;
		sectionSpr.scrollFactor.set();
		sectionSpr.alpha = 0;
		add(sectionSpr);

		sectionTxt = new Alphabet(0, 0, "");
		sectionTxt.alpha = 0;
		add(sectionTxt);

		// Apply initial visuals
		applySectionVisuals();

		transitioning = true;
		FlxTween.tween(bg, {alpha: 1}, 1, {ease: FlxEase.expoOut});
		FlxTween.tween(grid, {alpha: 1}, 1, {ease: FlxEase.expoOut});
		FlxTween.tween(sectionSpr, {alpha: 1}, 1, {ease: FlxEase.expoOut});
		FlxTween.tween(sectionTxt, {alpha: 1}, 1, {ease: FlxEase.expoOut, onComplete: (_:FlxTween) -> transitioning = false});
	}

	function buildSections() {
		sectionArray = [];
		sectionImageMap = new Map();

		// Track seen sections case-insensitively
		var seen:Map<String, Bool> = new Map();

		for (weekName in WeekData.weeksList) {
			if (weekIsLocked(weekName)) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(weekName);
			if (leWeek == null || leWeek.hideFreeplay) continue;

			var sec:String = leWeek.section;
			if (sec == null) continue;

			var key:String = sec.toLowerCase();
			if (seen.exists(key)) continue;

			seen.set(key, true);
			sectionArray.push(sec);

			WeekData.setDirectoryFromWeek(leWeek);
			sectionImageMap.set(key, Paths.image('freeplaysections/$key'));
		}

		// If nothing found, keep at least the default so UI doesn't explode
		if (sectionArray.length == 0) {
			sectionArray.push(daSection);
			sectionImageMap.set(daSection.toLowerCase(), Paths.image('freeplaysections/${daSection.toLowerCase()}'));
		}
	}

	override function update(elapsed:Float) {
		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;

		if (sectionArray.length > 1) {
			var left:Bool = Controls.justPressed('ui_left');
			if (left || Controls.justPressed('ui_right')) changeSection(left ? -1 : 1);
		}

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

		super.update(elapsed);
	}

	function closeFreeplaysection(func:FlxTween->Void, onlyFade:Bool = false) {
		for (obj in [bg, grid, sectionTxt]) FlxTween.tween(obj, {alpha: 0}, .5, {ease: FlxEase.expoInOut});
		FlxTween.tween(sectionSpr, onlyFade ? {alpha: 0} : {alpha: 0, y: sectionSpr.y + 200}, .5, {ease: FlxEase.expoInOut, onComplete: func});
	}

	function changeSection(change:Int = 0) {
		if (sectionArray.length == 0) return;

		FlxG.sound.play(Paths.sound('scrollMenu'));
		counter = FlxMath.wrap(counter + change, 0, sectionArray.length - 1);
		daSection = sectionArray[counter];

		applySectionVisuals();
	}

	function applySectionVisuals() {
		// Load graphic
		var g:FlxGraphic = sectionImageMap.get(daSection.toLowerCase());
		if (g != null) sectionSpr.loadGraphic(g);

		sectionSpr.updateHitbox();
		sectionSpr.gameCenter();

		// Update text only when changed
		if (lastShownSection != daSection) {
			lastShownSection = daSection;
			sectionTxt.text = daSection.toUpperCase();
			sectionTxt.gameCenter(X).y = sectionSpr.y;
		} else sectionTxt.y = sectionSpr.y;
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		if (leWeek == null) return true;

		var prereq:String = leWeek.weekBefore;
		if (leWeek.startUnlocked || prereq == null || prereq.length == 0) return false;

		return !StoryMenuState.weekCompleted.exists(prereq) || !StoryMenuState.weekCompleted.get(prereq);
	}
}
