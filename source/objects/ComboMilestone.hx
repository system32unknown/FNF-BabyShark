package objects;

class ComboMilestone extends FlxSpriteGroup {
	var effectStuff:FlxSprite;

	var wasComboSetup:Bool = false;
	var daCombo:Int = 0;

	var grpNumbers:FlxTypedGroup<ComboMilestoneNumber>;
	var onScreenTime:Float = 0;

	public function new(x:Float, y:Float, daCombo:Int = 0) {
		super(x, y);
		this.daCombo = daCombo;

		effectStuff = new FlxSprite();
		effectStuff.frames = Paths.getSparrowAtlas('comboMilestone');
		effectStuff.animation.addByPrefix('funny', 'NOTE COMBO animation', 24, false);
		effectStuff.animation.play('funny');
		effectStuff.animation.finishCallback = (name:String) -> kill();
		effectStuff.setGraphicSize(Std.int(effectStuff.width * 0.7));
		add(effectStuff);

		grpNumbers = new FlxTypedGroup<ComboMilestoneNumber>();
	}

	public function forceFinish():Void {
		if (onScreenTime < 0.9)
			FlxTimer.wait((Conductor.crochet / 1000) * .25, () -> forceFinish());
		else effectStuff.animation.play('funny', true, false, 18);
	}

	override function update(elapsed:Float) {
		onScreenTime += elapsed;

		if (effectStuff.animation.curAnim.curFrame == 17)
			effectStuff.animation.pause();

		if (effectStuff.animation.curAnim.curFrame == 2 && !wasComboSetup) {
			setupCombo(daCombo);
		}

		if (effectStuff.animation.curAnim.curFrame == 18) grpNumbers.forEach((spr:ComboMilestoneNumber) -> spr.animation.reset());
		if (effectStuff.animation.curAnim.curFrame == 20) grpNumbers.forEach((spr:ComboMilestoneNumber) -> spr.kill());

		super.update(elapsed);
	}

	function setupCombo(daCombo:Int) {
        FlxG.sound.play(Paths.sound('comboSound'));

		wasComboSetup = true;
		var loopNum:Int = 0;

		while (daCombo > 0) {
			var comboNumber:ComboMilestoneNumber = new ComboMilestoneNumber(450 - (100 * loopNum), 20 + 14 * loopNum, daCombo % 10);
			comboNumber.setGraphicSize(Std.int(comboNumber.width * .7));
			grpNumbers.add(comboNumber);
			add(comboNumber);

			loopNum += 1;
			daCombo = Math.floor(daCombo / 10);
		}
	}
}

class ComboMilestoneNumber extends FlxSprite {
	public function new(x:Float, y:Float, digit:Int) {
		super(x - 20, y);

		var stringNum:String = Std.string(digit);
		frames = Paths.getSparrowAtlas('comboMilestoneNumbers');
		animation.addByPrefix(stringNum, stringNum, 24, false);
		animation.play(stringNum);
		updateHitbox();
	}

	var shiftedX:Bool = false;
	override function update(elapsed:Float) {
		if (animation.curAnim.curFrame == 2 && !shiftedX) {
			shiftedX = true;
			x += 20;
		}

		super.update(elapsed);
	}
}
