package options;

import flixel.FlxObject;
import flixel.math.FlxPoint;
import objects.Bar;
import objects.Character;

import states.stages.StageWeek1 as BackgroundStage;

class NoteOffsetState extends MusicBeatState {
	var delayMin:Int = -500;
	var delayMax:Int = 500;
	var timeBar:Bar;

	var BF_X:Float = 770;
	var BF_Y:Float = 100;
	var GF_X:Float = 400;
	var GF_Y:Float = 130;
	
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var defaultCamZoom:Float = 1;

	var boyfriendGroup:FlxSpriteGroup;
	var gfGroup:FlxSpriteGroup;

	var boyfriend:Character;
	var gf:Character;

	var coolText:FlxText;
	var combo:FlxSprite;
	var rating:FlxSprite;
	var lateEarly:FlxSprite;
	var comboNums:FlxSpriteGroup;

	var dumbTexts:FlxTypedGroup<FlxText>;

	var barPercent:Float = 0;
	var timeTxt:FlxText;

	var changeModeText:FlxText;
	var comboOffset:Array<Array<Int>> = ClientPrefs.getPref('comboOffset');

	override public function create() {
		#if discord_rpc
		Discord.changePresence('Adjusting Offsets and Combos', null);
		#end

		FlxG.fixedTimestep = false;
		persistentUpdate = true;

		FlxG.sound.destroy(true);
		Paths.clearUnusedCache();
		// Cameras
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camGame.bgColor = 0xFF000000;
		camHUD.bgColor = 0x00000000;
		camOther.bgColor = 0x00000000;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		// Stage
		Paths.setCurrentLevel('week1');
		new BackgroundStage();
		camGame.scroll.set(120, 130);
		defaultCamZoom = 0.7;

		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);

		// Characters
		gf = new Character(0, 0, 'gf');
		gf.x += gf.positionArray[0];
		gf.y += gf.positionArray[1];
		gf.scrollFactor.set(0.95, 0.95);
		gf.danceEveryNumBeats = 2;
		gfGroup.add(gf);
		
		boyfriend = new Character(0, 0, 'bf', true);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		boyfriendGroup.add(boyfriend);

		add(gfGroup);
		add(boyfriendGroup);

		// Combo stuff
		coolText = new FlxText(0, 0, 0, '', 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;

		rating = new FlxSprite().loadGraphic(Paths.image('ratings/sick'));
		rating.camera = camHUD;
		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.updateHitbox();
		add(rating);

		comboNums = new FlxSpriteGroup();
		comboNums.camera = camHUD;
		add(comboNums);

		combo = new FlxSprite().loadGraphic(Paths.image('ratings/combo'));
		combo.camera = camHUD;
		combo.setGraphicSize(Std.int(combo.width * 0.7));
		combo.updateHitbox();
		add(combo);

		lateEarly = new FlxSprite().loadGraphic(Paths.image('ratings/early'));
		lateEarly.camera = camHUD;
		lateEarly.setGraphicSize(Std.int(combo.width * 0.7));
		lateEarly.updateHitbox();
		add(lateEarly);

		var seperatedScore:Array<Int> = [for (_ in 0...3) FlxG.random.int(0, 9)];

		var daLoop:Int = 0;
		for (i in seperatedScore) {
			var numScore:FlxSprite = new FlxSprite(43 * daLoop).loadGraphic(Paths.image('number/num$i'));
			numScore.camera = camHUD;
			numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			numScore.updateHitbox();
			comboNums.add(numScore);
			daLoop++;
		}

		timeTxt = new FlxText(0, 600, FlxG.width, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.borderSize = 2;

		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 3), 'healthBar', () -> return barPercent, delayMin, delayMax);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.leftBar.color = FlxColor.LIME;

		barPercent = ClientPrefs.getPref('noteOffset');
		updateNoteDelay();

		dumbTexts = new FlxTypedGroup<FlxText>();
		dumbTexts.camera = camHUD;
		add(dumbTexts);
		for (i in 0...8) createTexts(i);

		repositionCombo();

		timeBar.camera = camHUD; add(timeBar);
		timeTxt.camera = camHUD; add(timeTxt);

		var bar:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 40, FlxColor.BLACK);
		bar.scrollFactor.set();
		bar.alpha = 0.6;
		bar.camera = camHUD;
		add(bar);

		changeModeText = new FlxText(0, 4, FlxG.width, "", 32).setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		changeModeText.scrollFactor.set();
		changeModeText.camera = camHUD;
		add(changeModeText);

		updateMode();

		Conductor.usePlayState = false;
		Conductor.mapBPMChanges(true);
		Conductor.bpm = 128;
		FlxG.sound.playMusic(Paths.music('offsetSong'));

		super.create();
	}

	var holdTime:Float = 0;
	var onComboMenu:Bool = true;
	var holdingObjectType:String = '';

	var startMousePos:FlxPoint = FlxPoint.get();
	var startComboOffset:FlxPoint = FlxPoint.get();

	override function update(elapsed:Float) {
		Conductor.songPosition = FlxG.sound.music.time;
		super.update(elapsed);

		camGame.zoom = FlxMath.lerp(camGame.zoom, defaultCamZoom, FlxMath.bound(elapsed * 3.125, 0, 1));

		var addNum:Int = 1;
		if(FlxG.keys.pressed.SHIFT)
			addNum = onComboMenu ? 10 : 3;

		if(onComboMenu) {
			var controlArray:Array<Bool> = [
				FlxG.keys.justPressed.LEFT,
				FlxG.keys.justPressed.RIGHT,
				FlxG.keys.justPressed.UP,
				FlxG.keys.justPressed.DOWN,
			
				FlxG.keys.justPressed.A,
				FlxG.keys.justPressed.D,
				FlxG.keys.justPressed.W,
				FlxG.keys.justPressed.S,

				FlxG.keys.justPressed.F,
				FlxG.keys.justPressed.H,
				FlxG.keys.justPressed.T,
				FlxG.keys.justPressed.G,

				FlxG.keys.justPressed.J,
				FlxG.keys.justPressed.L,
				FlxG.keys.justPressed.K,
				FlxG.keys.justPressed.I
			];

			if(controlArray.contains(true)) {
				for (i in 0...controlArray.length) {
					if(controlArray[i]) {
						switch(i) {
							case 0: comboOffset[0][0] -= addNum;
							case 1: comboOffset[0][0] += addNum;
							case 2: comboOffset[0][1] += addNum;
							case 3: comboOffset[0][1] -= addNum;

							case 4: comboOffset[1][0] -= addNum;
							case 5: comboOffset[1][0] += addNum;
							case 6: comboOffset[1][1] += addNum;
							case 7: comboOffset[1][1] -= addNum;

							case 8: comboOffset[2][0] -= addNum;
							case 9: comboOffset[2][0] += addNum;
							case 10: comboOffset[2][1] += addNum;
							case 11: comboOffset[2][1] -= addNum;

							case 12: comboOffset[3][0] -= addNum;
							case 13: comboOffset[3][0] += addNum;
							case 14: comboOffset[3][1] += addNum;
							case 15: comboOffset[3][1] -= addNum;
						}
					}
				}
				repositionCombo();
			}

			// probably there's a better way to do this but, oh well.
			if (FlxG.mouse.justPressed) {
				holdingObjectType = null;
				FlxG.mouse.getScreenPosition(camHUD, startMousePos);
				if (selectObj(startMousePos, rating)) {
					holdingObjectType = 'rating';
					startComboOffset.set(comboOffset[0][0], comboOffset[0][1]);
				} else if (selectObj(startMousePos, comboNums)) {
					holdingObjectType = 'numscore';
					startComboOffset.set(comboOffset[1][0], comboOffset[1][1]);
				} else if (selectObj(startMousePos, combo)) {
					holdingObjectType = 'combo';
					startComboOffset.set(comboOffset[2][0], comboOffset[2][1]);
				} else if (selectObj(startMousePos, lateEarly)) {
					holdingObjectType = 'lateearly';
					startComboOffset.set(comboOffset[3][0], comboOffset[3][1]);
		   		}
			}
			if(FlxG.mouse.justReleased) {
				holdingObjectType = null;
			}

			if(holdingObjectType != null) {
				if(FlxG.mouse.justMoved) {
					var mousePos:FlxPoint = FlxG.mouse.getScreenPosition(camHUD);
					switch (holdingObjectType) {
						case 'rating':
							comboOffset[0][0] = Math.round((mousePos.x - startMousePos.x) + startComboOffset.x);
							comboOffset[0][1] = -Math.round((mousePos.y - startMousePos.y) - startComboOffset.y);
						case 'numscore':
							comboOffset[1][0] = Math.round((mousePos.x - startMousePos.x) + startComboOffset.x);
							comboOffset[1][1] = -Math.round((mousePos.y - startMousePos.y) - startComboOffset.y);
						case 'combo':
							comboOffset[2][0] = Math.round((mousePos.x - startMousePos.x) + startComboOffset.x);
							comboOffset[2][1] = -Math.round((mousePos.y - startMousePos.y) - startComboOffset.y);
						case 'lateearly':
							comboOffset[3][0] = Math.round((mousePos.x - startMousePos.x) + startComboOffset.x);
							comboOffset[3][1] = -Math.round((mousePos.y - startMousePos.y) - startComboOffset.y);
					}
					repositionCombo();
				}
			}

			if(controls.RESET) {
				for (i in 0...comboOffset.length) {
					for (j in 0... comboOffset[i].length) {
						comboOffset[i][j] = 0;
					}
				}
				repositionCombo();
			}
		} else {
			if(controls.UI_LEFT_P) {
				barPercent = Math.max(delayMin, Math.min(ClientPrefs.getPref('noteOffset') - 1, delayMax));
				updateNoteDelay();
			} else if(controls.UI_RIGHT_P) {
				barPercent = Math.max(delayMin, Math.min(ClientPrefs.getPref('noteOffset') + 1, delayMax));
				updateNoteDelay();
			}

			var mult:Int = 1;
			if(controls.UI_LEFT || controls.UI_RIGHT) {
				holdTime += elapsed;
				if(controls.UI_LEFT) mult = -1;
			}

			if(controls.UI_LEFT_R || controls.UI_RIGHT_R) holdTime = 0;

			if(holdTime > 0.5) {
				barPercent += 100 * addNum * elapsed * mult;
				barPercent = Math.max(delayMin, Math.min(barPercent, delayMax));
				updateNoteDelay();
			}

			if(controls.RESET) {
				holdTime = 0;
				barPercent = 0;
				updateNoteDelay();
			}
		}

		if(controls.ACCEPT) {
			onComboMenu = !onComboMenu;
			updateMode();
		}

		if(controls.BACK) {
			persistentUpdate = false;
			CustomFadeTransition.nextCamera = camOther;
			MusicBeatState.switchState(new options.OptionsState());
			if(OptionsState.onPlayState) {
				if(ClientPrefs.getPref('pauseMusic') != 'None')
					FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.getPref('pauseMusic'))));
				else FlxG.sound.music.volume = 0;
			}
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 1, true);
			FlxG.mouse.visible = false;
		}
	}

	inline function selectObj(obj1:FlxPoint, obj2:FlxObject):Bool {
		return obj1.x - obj2.x >= 0 && obj1.x - obj2.x <= obj2.width && obj1.y - obj2.y >= 0 && obj1.y - obj2.y <= obj2.height;
	}

	override public function beatHit() {
		super.beatHit();

		if(curBeat % 2 == 0) boyfriend.dance();
		gf.dance();
		
		if (!onComboMenu && camGame.zoom < 1.35)
			camGame.zoom += .0075;
	}

	override function sectionHit() {
		super.sectionHit();
		if (camGame.zoom < 1.35) camGame.zoom += .015;
	}

	function repositionCombo() {
		rating.screenCenter();
		rating.x = coolText.x - 40 + comboOffset[0][0];
		rating.y -= 60 + comboOffset[0][1];

		comboNums.screenCenter();
		comboNums.x = coolText.x - 90 + comboOffset[1][0];
		comboNums.y += 80 - comboOffset[1][1];

		combo.screenCenter();
		combo.x = coolText.x + comboOffset[2][0];
		combo.y -= comboOffset[2][1];

		lateEarly.screenCenter();
		lateEarly.setPosition(coolText.x - 130 + comboOffset[3][0], coolText.y - comboOffset[3][1]);

		reloadTexts();
	}

	function createTexts(i:Int) {
		var text:FlxText = new FlxText(10, 48 + (i * 30), 0, '', 24);
		text.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.scrollFactor.set();
		text.borderSize = 2;
		text.camera = camHUD;

		dumbTexts.add(text);
		text.y += Math.floor(i / 2) * 24;
	}

	function reloadTexts()
	{
		for (i in 0...dumbTexts.length) {
			switch(i) {
				case 0: dumbTexts.members[i].text = 'Rating Offset:';
				case 1: dumbTexts.members[i].text = '[' + comboOffset[0][0] + ', ' + comboOffset[0][1] + ']';
				case 2: dumbTexts.members[i].text = 'Numbers Offset:';
				case 3: dumbTexts.members[i].text = '[' + comboOffset[1][0] + ', ' + comboOffset[1][1] + ']';
				case 4: dumbTexts.members[i].text = 'Combo Offset:';
				case 5: dumbTexts.members[i].text = '[' + comboOffset[2][0] + ', ' + comboOffset[2][1] + ']';
				case 6: dumbTexts.members[i].text = 'Late/Early Offset:';
				case 7: dumbTexts.members[i].text = '[' + comboOffset[3][0] + ', ' + comboOffset[3][1] + ']';
			}
		}
	}

	function updateNoteDelay() {
		ClientPrefs.prefs.set('noteOffset', Math.round(barPercent));
		timeTxt.text = 'Current offset: ' + Math.floor(barPercent) + ' ms';
	}

	function updateMode() {
		rating.visible = onComboMenu;
		comboNums.visible = onComboMenu;
		combo.visible = onComboMenu;
		lateEarly.visible = onComboMenu;
		dumbTexts.visible = onComboMenu;
		
		timeBar.visible = timeTxt.visible = !onComboMenu;

		var str:String;
		var str2:String = '(Press Accept to Switch)';
		str = onComboMenu ? 'Combo Offset' : 'Note/Beat Delay';

		changeModeText.text = '< ${str.toUpperCase()} ${str2.toUpperCase()} >';

		changeModeText.text = changeModeText.text.toUpperCase();
		FlxG.mouse.visible = onComboMenu;
	}

	override function destroy() {
		super.destroy();

		startMousePos.put();
		startComboOffset.put();
	}
}
