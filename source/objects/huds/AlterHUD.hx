package objects.huds;

import haxe.extern.EitherType;
import objects.Bar;
import objects.HealthIcon;
import utils.MathUtil;
import flixel.util.FlxStringUtil;

class AlterHUD extends HUD {
	var timeBar:Bar;
	var timeTxt:FlxText;
	var healthBar:Bar;
	var iconP1:HealthIcon;
	var iconP2:HealthIcon;
	var scoreTxt:FlxText;
	var botplayTxt:FlxText;
	var songPercent:Float = 0;

	var iconSpacing:Float = 20;
	public var botplaySine:Float = 0;
	public var botplayFade:Bool = true;
	var grade:String;
	var clearType:String;
	var updateTime:Bool;

	public var hideHud:Bool = false;
	public var timeType:String;

	public static var ratingStuff:Array<Array<EitherType<String, Float>>> = [
		['Skill issue', .2], // From 0% to 19%
		['Ok', .4], // From 20% to 39%
		['Bad', .5], // From 40% to 49%
		['Bruh', .6], // From 50% to 59%
		['Meh', .69], // From 60% to 68%
		['Nice', .7], // 69%
		['Good', .8], // From 70% to 79%
		['Great', .9], // From 80% to 89%
		['Sick!', 1.], // From 90% to 99%
		['Superb!!', 1.]
	];

	public function new(songName:String) {
		super(songName);

		var showTime:Bool = timeType != 'Disabled';

		add(timeTxt = new FlxText(FlxG.width / 4, 19, FlxG.width / 2, "", 16));
		timeTxt.setFormat(Paths.font("babyshark.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.visible = updateTime = showTime;
		if (downscroll) timeTxt.y = FlxG.height - 35;
		if (timeType == 'Song Name') timeTxt.text = songName + (playbackRate != 1 ? ' (${playbackRate}x)' : '');

		add(timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', () -> return songPercent, 0, 1));
		timeBar.scrollFactor.set();
		timeBar.gameCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;

		add(healthBar = new Bar(0, 0, 'healthBar', function() return game.health, 0, 100));
		setHealthColors(Util.getColor(game.dad.healthColorArray), Util.getColor(game.boyfriend.healthColorArray));
		healthBar.gameCenter(X);
		healthBar.leftToRight = false;

		iconP1 = new HealthIcon(game.boyfriend.healthIcon, true);
		iconP2 = new HealthIcon(game.dad.healthIcon);
		for (icon in [iconP1, iconP2]) {
			icon.y = healthBar.y - (icon.height / 2);
			icon.visible = !game.hideHud;
			icon.alpha = Settings.data.healthBarAlpha;
			if (Settings.data.healthTypes == 'Psych') icon.iconType = 'psych';
			if (!game.instakillOnMiss) add(icon);
		}
		updateIconPositions();

		add(scoreTxt = new FlxText(FlxG.width / 2, Math.floor(healthBar.y + 35), FlxG.width));
		scoreTxt.setFormat(Paths.font("babyshark.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		scoreTxt.visible = !hideHud;
		scoreTxt.scrollFactor.set();
		scoreTxt.gameCenter(X);

		botplayTxt = new FlxText(400, healthBar.y + (downscroll ? 70 : -90), FlxG.width - 800, Language.getPhrase("Botplay", "BOTPLAY"), 32);
		botplayTxt.setFormat(Paths.font("babyshark.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		add(botplayTxt);

		updateGrade();
	}

	function updateIconPositions():Void {
		iconP1.x = (iconP1.iconType == 'psych' ? healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconSpacing : healthBar.barCenter - iconSpacing);
		iconP2.x = (iconP2.iconType == 'psych' ? healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconSpacing * 2 : healthBar.barCenter - (iconP2.width - iconSpacing));
	}

	// override function eventTriggered(event:Event) {
	// 	switch event.name {
	// 		case 'Change Character':
	// 			var type:Int = Std.parseInt(event.args[0]);
	// 			var name:String = Std.string(event.args[1]);

	// 			if (type == 0) iconP2.change(name);
	// 			else if (type == 2) iconP1.change(name);
	// 	}
	// }

	override function setTimeBarColors(a:FlxColor, ?b:FlxColor) {
		super.setTimeBarColors(a, b);
		timeBar.setColors(a, FlxColor.GRAY);
	}

	override function setHealthColors(a:FlxColor, ?b:FlxColor) {
		super.setHealthColors(a, b);
		healthBar.setColors(a, b);
	}

	override function healthChange(value:Float) {
		healthBar.percent = FlxMath.remapToRange(healthBar.bounded, healthBar.bounds.min, healthBar.bounds.max, 0, 100);

		if (healthBar.percent < 20) {
			iconP1.setState(1);
			iconP2.setState(2);
		} else if (healthBar.percent > 80) {
			iconP1.setState(2);
			iconP2.setState(1);
		} else {
			iconP1.setState(0);
			iconP2.setState(0);
		}
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		updateTimeBar();
		for (icon in [iconP1, iconP2]) icon.bopUpdate(elapsed, game.playbackRate);
		updateIconPositions();

		if (botplayTxt != null && botplayTxt.visible && botplayFade) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}
	}

	override function beatHit(beat:Int):Void {
		for (i => icon in [iconP1, iconP2])
			icon.bop({
				curBeat: beat,
				playbackRate: game.playbackRate,
				gfSpeed: game.gfSpeed,
				percent: healthBar.bounded
			}, "Settings", i);
	}

	public function updateGrade():Void {
		grade = getGrade();
		clearType = updateClearType();
		updateScoreTxt();
	}


	dynamic function updateScoreTxt():Void {
		var tempText:String = '${!Settings.data.showNPS ? '' : Language.getPhrase('nps_text', 'NPS: {1}/{2}', [game.bfNpsVal, game.bfNpsMax])}';
		tempText += Settings.data.showNPS ? ' | ' : '';
		if (!botplay) {
			tempText += Language.getPhrase('score_text', 'Score: {1} ', [flixel.util.FlxStringUtil.formatMoney(game.songScore, false)]);
			if (!game.instakillOnMiss) tempText += Language.getPhrase('miss_text', '| Misses: {1} ', [game.songMisses]); 
			tempText += Language.getPhrase('accuracy_text', '| Accuracy: {1}% |', [ratingAccuracy]) + (totalPlayed != 0 ? ' (${Language.getPhrase(ratingFC)}) ${Language.getPhrase('rating_$ratingName', ratingName)}' : ' ?');
		} else tempText += Language.getPhrase('hits_text', 'Hits: {1}', [game.combo]);
		scoreTxt.text = tempText;
	}

	var _lastSeconds:Int = -1;
	dynamic function updateTimeBar() {
		if (paused || !updateTime) return;

		var curTime:Float = Math.max(0, Conductor.rawTime);

		songPercent = (curTime / Conductor.length);

		var songCalc:Float = (Conductor.length - curTime);
		if (Settings.data.timeBarType == 'Time Elapsed') songCalc = curTime;

		var seconds:Int = Math.floor((songCalc / Conductor.rate) * 0.001);
		if (seconds < 0) seconds = 0;

		if (seconds == _lastSeconds) return;

		var textToShow:String = '$songName';
		if (Conductor.rate != 1) textToShow += ' (${Conductor.rate}x)';
		if (Settings.data.timeBarType != 'Song Name') textToShow += ' - ${FlxStringUtil.formatTime(seconds, false)}';

		timeTxt.text = textToShow;
		_lastSeconds = seconds;
	}

	override function set_downscroll(v:Bool):Bool {
		timeBar.y = v ? FlxG.height - 30 : 15;
		timeTxt.setPosition(timeBar.getMidpoint().x - (timeTxt.width * 0.5), timeBar.getMidpoint().y - (timeTxt.height * 0.5));
		healthBar.y = v ? 55 : 640;
		for (icon in [iconP1, iconP2]) icon.y = healthBar.y - (icon.height * .5);
		scoreTxt.y = v ? 21 : FlxG.height - 39;
		botplayTxt.y = v ? FlxG.height - 115 : 85;

		return super.set_downscroll(v);
	}

	override function set_botplay(v:Bool):Bool {
		botplayTxt.visible = v;
		return super.set_botplay(v);
	}

	dynamic function updateClearType():String {
		var fullhits:Array<Int> = [for (judge in game.judgeData) judge.hits];

		var type:String = 'N/A';

		if (game.songMisses == 0) {
			if (fullhits[3] > 0 || fullhits[4] > 0) type = 'FC';
			else if (fullhits[2] > 0) type = 'GFC';
			else if (fullhits[1] > 0) type = 'SFC';
			else if (fullhits[0] > 0) type = "PFC";
		} else {
			if (game.songMisses < 10) type = 'SDCB';
			else type = 'Clear';
		}

		return type;
	}

	dynamic function getGrade():String {
		game.ratingName = '?';
		if (game.totalPlayed == 0) return game.ratingName;

		game.ratingAccuracy = Math.min(1, Math.max(0, game.totalNotesHit / game.totalPlayed));
		game.ratingPercent = MathUtil.floorDecimal(game.ratingAccuracy * 100, 2);
		if (game.ratingAccuracy < 1) // Rating Name
			for (i in 0...ratingStuff.length - 1) {
				final daRating:Array<EitherType<String, Float>> = ratingStuff[i];
				if (game.ratingAccuracy < cast daRating[1]) {
					game.ratingName = daRating[0];
					break;
				}
			}
		else game.ratingName = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
		
		return game.ratingName;
	}
}