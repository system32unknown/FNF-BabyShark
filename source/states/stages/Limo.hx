package states.stages;

import states.stages.objects.*;

enum HenchmenKillState {
	WAIT;
	KILLING;
	SPEEDING_OFFSCREEN;
	SPEEDING;
	STOPPING;
}

class Limo extends BaseStage {
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;
	var fastCarCanDrive:Bool = true;

	// event
	var limoKillingState:HenchmenKillState = WAIT;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var dancersDiff:Float = 320;

	override function create() {
		var limoSunset:BGSprite;
		add(limoSunset = new BGSprite('limo/limoSunset', -120, -50, .1, .1));

		if (!lowQuality) {
			add(limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4));
			add(bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true));
			add(limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true));
			add(limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true));

			add(grpLimoDancers = new FlxTypedGroup<BackgroundDancer>());

			for (i in 0...5) {
				var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + dancersDiff + bgLimo.x, bgLimo.y - 400);
				dancer.scrollFactor.set(.4, .4);
				grpLimoDancers.add(dancer);
			}

			add(limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4));
			add(grpLimoParticles = new FlxTypedGroup<BGSprite>());

			// PRECACHE BLOOD
			var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood']);
			particle.alpha = 0.01;
			grpLimoParticles.add(particle);
			resetLimoKill();

			// PRECACHE SOUND
			Paths.sound('dancerdeath');
			setDefaultGF('gf-car');
		}

		fastCar = new BGSprite('limo/fastCarLol', -300, 160);
		fastCar.active = true;
	}
	override function createPost() {
		resetFastCar();
		addBehindGF(fastCar);
		addBehindGF(new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true)); // Shitty layering but whatev it works LOL
	}

	var limoSpeed:Float = 0;
	override function update(elapsed:Float) {
		if (!lowQuality) {
			grpLimoParticles.forEach((spr:BGSprite) -> {
				if (spr.animation.curAnim.finished) {
					spr.kill();
					grpLimoParticles.remove(spr, true);
					spr.destroy();
				}
			});

			switch (limoKillingState) {
				case KILLING:
					limoMetalPole.x += 5000 * elapsed;
					limoLight.x = limoMetalPole.x - 180;
					limoCorpse.x = limoLight.x - 50;
					limoCorpseTwo.x = limoLight.x + 35;

					var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
					for (i in 0...dancers.length) {
						if (dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 170) {
							switch (i) {
								case 0 | 3:
									if (i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

									var diffStr:String = i == 3 ? ' 2 ' : ' ';
									var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr]);
									grpLimoParticles.add(particle);
									var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr]);
									grpLimoParticles.add(particle);
									var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr]);
									grpLimoParticles.add(particle);

									var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood']);
									particle.flipX = true;
									particle.angle = -57.5;
									grpLimoParticles.add(particle);
								case 1: limoCorpse.visible = true;
								case 2: limoCorpseTwo.visible = true;
							} //Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
							dancers[i].x += FlxG.width * 2;
						}
					}

					if (limoMetalPole.x > FlxG.width * 2) {
						resetLimoKill();
						limoSpeed = 800;
						limoKillingState = SPEEDING_OFFSCREEN;
					}

				case SPEEDING_OFFSCREEN:
					limoSpeed -= 4000 * elapsed;
					bgLimo.x -= limoSpeed * elapsed;
					if (bgLimo.x > FlxG.width * 1.5) {
						limoSpeed = 3000;
						limoKillingState = SPEEDING;
					}

				case SPEEDING:
					limoSpeed -= 2000 * elapsed;
					if (limoSpeed < 1000) limoSpeed = 1000;

					bgLimo.x -= limoSpeed * elapsed;
					if (bgLimo.x < -275) {
						limoKillingState = STOPPING;
						limoSpeed = 800;
					}
					dancersParenting();

				case STOPPING:
					bgLimo.x = FlxMath.lerp(-150, bgLimo.x, Math.exp(-elapsed * 9));
					if (Math.round(bgLimo.x) == -150) {
						bgLimo.x = -150;
						limoKillingState = WAIT;
					}
					dancersParenting();

				default: //nothing
			}
		}
	}

	override function beatHit() {
		if (!lowQuality) grpLimoDancers.forEach((dancer:BackgroundDancer) -> dancer.dance());
		if (FlxG.random.bool(10) && fastCarCanDrive) fastCarDrive();
	}

	// Substates for pausing/resuming tweens and timers
	override function closeSubState() {
		if (paused && carTimer != null) carTimer.active = true;
	}

	override function openSubState(SubState:FlxSubState) {
		if (paused && carTimer != null) carTimer.active = false;
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float) {
		switch (eventName) {
			case "Kill Henchmen": killHenchmen();
		}
	}

	function dancersParenting():Void {
		var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
		for (i in 0...dancers.length) dancers[i].x = (370 * i) + dancersDiff + bgLimo.x;
	}

	function resetLimoKill():Void {
		limoMetalPole.x = -500;
		limoMetalPole.visible = false;
		limoLight.x = -500;
		limoLight.visible = false;
		limoCorpse.x = -500;
		limoCorpse.visible = false;
		limoCorpseTwo.x = -500;
		limoCorpseTwo.visible = false;
	}

	function resetFastCar():Void {
		fastCar.setPosition(-12600, FlxG.random.int(140, 250));
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;
	function fastCarDrive():Void {
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = FlxG.random.int(30600, 39600);
		fastCarCanDrive = false;
		carTimer = FlxTimer.wait(2, () -> {
			resetFastCar();
			carTimer = null;
		});
	}

	function killHenchmen():Void {
		if (!lowQuality) {
			if (limoKillingState == WAIT) {
				limoMetalPole.x = -400;
				limoMetalPole.visible = limoLight.visible = true;
				limoCorpse.visible = limoCorpseTwo.visible = false;
				limoKillingState = KILLING;
			}
		}
	}
}