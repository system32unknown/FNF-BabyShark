package states;

import flixel.FlxObject;
import objects.Bar;
import utils.MathUtil;

#if AWARDS_ALLOWED
class AwardsState extends MusicBeatState {
	public var grpAwards:FlxSpriteGroup;
	public var nameTxt:FlxText;
	var descText:FlxText;
	public var progressTxt:FlxText;
	public var progressBar:Bar;
	public var options:Array<Dynamic> = [];

	var camFollow:FlxObject;

	var MAX_PER_ROW:Int = 4;
	public var curSelected:Int = 0;

	override function create():Void {
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Awards Menu");
		#end

		super.create();

		// prepare award lists
		for (award => data in Awards.list) {
			var unlocked:Bool = Awards.isUnlocked(award);
			if (data.hidden && !unlocked) continue;
			options.push(makeAward(award, data, unlocked, data.mod));
		}

		var menuBG:FlxSprite = new FlxSprite(Paths.image('menuDesat'));
		menuBG.antialiasing = Settings.data.antialiasing;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.gameCenter();
		menuBG.scrollFactor.set();
		menuBG.color = 0xFF9271FD;
		add(menuBG);

		grpAwards = new FlxSpriteGroup();
		grpAwards.scrollFactor.x = 0;
		add(camFollow = new FlxObject(0, 0, 1, 1));

		options.sort(utils.SortUtil.byID);
		for (id in options) {
			var graphic:flixel.graphics.FlxGraphic = null;
			var path:String = 'awards/$id';
			var antialiasing:Bool = true;
			if (Awards.isUnlocked(id)) {
				#if MODS_ALLOWED Mods.currentModDirectory = id.mod; #end
				if (Paths.fileExists('images/$path-pixel.png', IMAGE)) {
					graphic = Paths.image('$path-pixel');
					antialiasing = false;
				} else graphic = Paths.image(path);

				if (graphic == null) graphic = Paths.image('unknownMod');
			} else graphic = Paths.image('awards/locked');

			var spr:FlxSprite = new FlxSprite(0, Math.floor(grpAwards.members.length / MAX_PER_ROW) * 180, graphic);
			spr.scrollFactor.x = 0;
			spr.gameCenter(X).x += 180 * ((grpAwards.members.length % MAX_PER_ROW) - MAX_PER_ROW / 2) + spr.width / 2 + 15;
			spr.antialiasing = antialiasing;
			spr.ID = grpAwards.members.length;
			grpAwards.add(spr);
		}
		#if MODS_ALLOWED Mods.loadTopMod(); #end

		
		var awardBox:FlxSprite = new FlxSprite(0, -30).makeGraphic(1, 1, FlxColor.BLACK);
		awardBox.scale.set(grpAwards.width + 60, grpAwards.height + 60);
		awardBox.updateHitbox();
		awardBox.alpha = .6;
		awardBox.scrollFactor.x = 0;
		awardBox.gameCenter(X);
		add(awardBox);
		add(grpAwards);

		var box:FlxSprite = new FlxSprite(0, 570).makeSolid(FlxG.width, Std.int(FlxG.height - awardBox.y), FlxColor.BLACK);
		box.alpha = 0.6;
		box.scrollFactor.set();
		add(box);

		add(nameTxt = new FlxText(50, box.y + 10, FlxG.width - 100, ''));
		nameTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		nameTxt.scrollFactor.set();

		add(descText = new FlxText(50, nameTxt.y + 38, FlxG.width - 100, ''));
		descText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
		descText.scrollFactor.set();

		add(progressBar = new Bar(0, descText.y + 52));
		progressBar.gameCenter(X);
		progressBar.scrollFactor.set();
		progressBar.active = false;

		add(progressTxt = new FlxText(50, progressBar.y - 6, FlxG.width - 100, '0 / 0'));
		progressTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		progressTxt.scrollFactor.set();
		progressTxt.borderSize = 2;

		changeSelection();
		FlxG.camera.follow(camFollow, null, .15);
		FlxG.camera.scroll.y = -FlxG.height;
	}

	function makeAward(award:String, data:Award, unlocked:Bool, mod:String = null) {
		return {
			name: award,
			displayName: unlocked ? Language.getPhrase('award_$award', data.name) : '???',
			description: Language.getPhrase('description_$award', data.description),
			curProgress: data.maxScore > 0 ? Awards.getScore(award) : 0,
			maxProgress: data.maxScore > 0 ? data.maxScore : 0,
			decProgress: data.maxScore > 0 ? data.maxDecimals : 0,
			unlocked: unlocked,
			ID: data.ID,
			mod: mod
		};
	}

	var goingBack:Bool = false;
	override function update(delta:Float):Void {
		if (!goingBack && options.length > 1) {
			var add:Int = 0;
			if (Controls.justPressed('ui_left')) add = -1;
			else if (Controls.justPressed('ui_right')) add = 1;

			if (add != 0) {
				var oldRow:Int = Math.floor(curSelected / MAX_PER_ROW);
				var rowSize:Int = Std.int(Math.min(MAX_PER_ROW, options.length - oldRow * MAX_PER_ROW));

				curSelected += add;
				var curRow:Int = Math.floor(curSelected / MAX_PER_ROW);
				if (curSelected >= options.length) curRow++;

				if (curRow != oldRow) {
					if (curRow < oldRow) curSelected += rowSize;
					else curSelected = curSelected -= rowSize;
				}
				changeSelection();
			}

			if (options.length > MAX_PER_ROW) {
				var add:Int = 0;
				if (Controls.justPressed('ui_up')) add = -1;
				else if (Controls.justPressed('ui_down')) add = 1;

				if (add != 0) {
					var diff:Int = curSelected - (Math.floor(curSelected / MAX_PER_ROW) * MAX_PER_ROW);
					curSelected += add * MAX_PER_ROW;
					if (curSelected < 0) {
						curSelected += Math.ceil(options.length / MAX_PER_ROW) * MAX_PER_ROW;
						if (curSelected >= options.length) curSelected -= MAX_PER_ROW;
					}
					if (curSelected >= options.length) curSelected = diff;
					changeSelection();
				}
			}

			if (Controls.justPressed('reset') && (options[curSelected].unlocked || options[curSelected].curProgress > 0))
				openSubState(new ResetAwardSubstate());
		}

		if (Controls.justPressed('back')) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(() -> new MainMenuState());
			goingBack = true;
		}
		super.update(delta);
	}

	function changeSelection():Void {
		var award:Dynamic = options[curSelected];
		nameTxt.text = award.displayName;
		descText.text = award.description;
		progressBar.visible = progressTxt.visible = award.maxProgress > 0;

		if (progressTxt.visible) {
			var currentProgress:Float = MathUtil.floorDecimal(award.curProgress, award.decProgress);
			var maxProgress:Float = MathUtil.floorDecimal(award.maxProgress, award.decProgress);
			progressTxt.text = '$currentProgress / $maxProgress';
		}

		var maxRows:Int = Math.floor(grpAwards.members.length / MAX_PER_ROW);
		if (maxRows > 0) camFollow.setPosition(0, FlxG.height / 2 + (Math.floor(curSelected / MAX_PER_ROW) / maxRows) * Math.max(0, grpAwards.height - FlxG.height / 2 - 50) - 100);
		else camFollow.setPosition(0, grpAwards.members[curSelected].getGraphicMidpoint().y - 100);

		grpAwards.forEach((spr:FlxSprite) -> {
			spr.alpha = .6;
			if (spr.ID == curSelected) spr.alpha = 1;
		});
	}
}

class ResetAwardSubstate extends MusicBeatSubstate {
	var onYes:Bool = false;
	var yesText:Alphabet;
	var noText:Alphabet;

	public function new():Void {
		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);
		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		var text:Alphabet = new Alphabet(0, 180, Language.getPhrase('reset_award', 'Reset Award:'));
		text.gameCenter(X);
		text.scrollFactor.set();
		add(text);

		var state:AwardsState = cast FlxG.state;
		var text:FlxText = new FlxText(50, text.y + 90, FlxG.width - 100, state.options[state.curSelected].displayName, 40);
		text.setFormat(Paths.font("babyshark.ttf"), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.scrollFactor.set();
		text.borderSize = 2;
		add(text);

		yesText = new Alphabet(0, text.y + 120, Language.getPhrase('yes'));
		yesText.gameCenter(X).x -= 200;
		yesText.scrollFactor.set();
		yesText.color = FlxColor.RED;
		add(yesText);

		noText = new Alphabet(0, text.y + 120, Language.getPhrase('no'));
		noText.gameCenter(X).x += 200;
		noText.scrollFactor.set();
		add(noText);
		updateOptions();
	}

	override function update(elapsed:Float):Void {
		if (Controls.justPressed('back')) {
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}

		super.update(elapsed);

		if (Controls.justPressed('ui_left') || Controls.justPressed('ui_right')) {
			onYes = !onYes;
			updateOptions();
		}

		if (Controls.justPressed('accept')) {
			if (onYes) {
				var state:AwardsState = cast FlxG.state;
				var option:Dynamic = state.options[state.curSelected];

				option.unlocked = false;
				option.curProgress = 0;
				option.name = state.nameTxt.text = '???';
				if (option.maxProgress > 0) state.progressTxt.text = '0 / ' + option.maxProgress;
				state.grpAwards.members[state.curSelected].loadGraphic(Paths.image('awards/locked'));
				state.grpAwards.members[state.curSelected].antialiasing = Settings.data.antialiasing;
				state.progressBar.percent = 0;

				Awards.reset(true);

				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
			close();
			return;
		}
	}

	function updateOptions():Void {
		var scales:Array<Float> = [.75, 1];
		var alphas:Array<Float> = [.6, 1.25];
		var confirmInt:Int = onYes ? 1 : 0;

		yesText.alpha = alphas[confirmInt];
		yesText.scale.set(scales[confirmInt], scales[confirmInt]);
		noText.alpha = alphas[1 - confirmInt];
		noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}
#end