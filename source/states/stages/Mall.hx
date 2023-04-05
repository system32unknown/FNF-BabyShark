package states.stages;

class Mall extends BaseStage
{
	var upperBoppers:BGSprite;
	var bottomBoppers:MallCrowd;
	var santa:BGSprite;

	override function create()
	{
		var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
		bg.setGraphicSize(Std.int(bg.width * 0.8));
		bg.updateHitbox();
		add(bg);

		if(!lowQuality) {
			upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
			upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
			upperBoppers.updateHitbox();
			add(upperBoppers);

			var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
			bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
			bgEscalator.updateHitbox();
			add(bgEscalator);
		}

		add(new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40));

		bottomBoppers = new MallCrowd(-300, 140);
		add(bottomBoppers);

		add(new BGSprite('christmas/fgSnow', -600, 700));

		santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
		add(santa);
		setDefaultGF('gf-christmas');

		if(isStoryMode && !seenCutscene) {
			setEndCallback(eggnogEndCutscene);
		}
	}

	override function countdownTick(count:BaseStage.Countdown, num:Int) everyoneDance();
	override function beatHit() everyoneDance();

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float) {
		switch(eventName) {
			case "Hey!":
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						return;
				}
				bottomBoppers.animation.play('hey', true);
				bottomBoppers.heyTimer = flValue2;
		}
	}

	function everyoneDance() {
		if(!lowQuality)
			upperBoppers.dance(true);

		bottomBoppers.dance(true);
		santa.dance(true);
	}

	function eggnogEndCutscene() {
		if(PlayState.storyPlaylist[1] == null) {
			endSong();
			return;
		}
	}
}