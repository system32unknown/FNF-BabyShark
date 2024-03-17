package options;

import objects.Bar;
import objects.Character;

class NoteOffsetState extends MusicBeatState {
	var delayMin:Int = -500;
	var delayMax:Int = 500;
	var timeBar:Bar;

	var BF_X:Float = 770;
	var BF_Y:Float = 100;
	var GF_X:Float = 400;
	var GF_Y:Float = 130;
	
	var camHUD:FlxCamera;
	var camGame:FlxCamera;
	var camOther:FlxCamera;
	public var defaultCamZoom:Float = 1;

	var boyfriendGroup:FlxSpriteGroup;
	var gfGroup:FlxSpriteGroup;

	var boyfriend:Character;
	var gf:Character;

	var combo:FlxSprite;
	var rating:FlxSprite;
	var comboNums:FlxSpriteGroup;

	var dumbTexts:FlxTypedGroup<FlxText>;

	var barPercent:Float = 0;
	var timeTxt:FlxText;

	var changeModeText:FlxText;
	var comboOffset:Array<Array<Int>> = ClientPrefs.getPref('comboOffset');

	override public function create() {
		#if DISCORD_ALLOWED DiscordClient.changePresence('Adjusting Offsets and Combos'); #end

		FlxG.fixedTimestep = false;
		persistentUpdate = true;

		FlxG.sound.destroy(true);
		Paths.clearUnusedCache();
		// Cameras
		camGame = initPsychCamera();

		camHUD = new FlxCamera();
		camHUD.bgColor = 0x00000000;
		FlxG.cameras.add(camHUD, false);

		camOther = new FlxCamera();
		camOther.bgColor = 0x00000000;
		FlxG.cameras.add(camOther, false);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		// Stage
		Paths.setCurrentLevel('week1');
		new states.stages.StageWeek1();
		camGame.scroll.set(120, 130);
		defaultCamZoom = .7;

		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);

		// Characters
		gf = new Character(0, 0, 'gf');
		gf.x += gf.positionArray[0];
		gf.y += gf.positionArray[1];
		gf.scrollFactor.set(.95, .95);
		gf.danceEveryNumBeats = 2;
		gfGroup.add(gf);
		
		boyfriend = new Character(0, 0, 'bf', true);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		boyfriendGroup.add(boyfriend);

		add(gfGroup);
		add(boyfriendGroup);

		// Combo stuff
		rating = new FlxSprite(Paths.image('ratings/sick'));
		rating.camera = camHUD;
		rating.setGraphicSize(rating.width * 0.7);
		rating.updateHitbox();
		add(rating);

		comboNums = new FlxSpriteGroup();
		comboNums.camera = camHUD;
		add(comboNums);

		combo = new FlxSprite(Paths.image('ratings/combo'));
		combo.camera = camHUD;
		combo.setGraphicSize(Std.int(combo.width * .7));
		combo.updateHitbox();
		add(combo);

		var daLoop:Int = 0;
		for (i in [for (_ in 0...FlxG.random.int(3, 4)) FlxG.random.int(0, 9)]) {
			var numScore:FlxSprite = new FlxSprite(43 * daLoop++, Paths.image('number/num$i'));
			numScore.camera = camHUD;
			numScore.setGraphicSize(numScore.width * .5);
			numScore.updateHitbox();
			comboNums.add(numScore);
		}

		timeTxt = new FlxText(0, 600, FlxG.width, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		timeTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		timeTxt.scrollFactor.set();

		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 3), 'healthBar', () -> return barPercent, delayMin, delayMax);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.leftBar.color = FlxColor.LIME;

		barPercent = ClientPrefs.data.noteOffset;
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

		camGame.zoom = FlxMath.lerp(defaultCamZoom, camGame.zoom, Math.exp(-elapsed * 3.125));

		var addNum:Int = 1;
		if(FlxG.keys.pressed.SHIFT) addNum = onComboMenu ? 10 : 3;

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
					}
					repositionCombo();
				}
			}

			if(controls.RESET) {
				for (i in 0...comboOffset.length) for (j in 0... comboOffset[i].length) comboOffset[i][j] = 0;
				repositionCombo();
			}
		} else {
			if(controls.UI_LEFT_P) {
				barPercent = Math.max(delayMin, Math.min(ClientPrefs.data.noteOffset - 1, delayMax));
				updateNoteDelay();
			} else if(controls.UI_RIGHT_P) {
				barPercent = Math.max(delayMin, Math.min(ClientPrefs.data.noteOffset + 1, delayMax));
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
			FlxG.switchState(() -> new options.OptionsState());
			if(OptionsState.onPlayState) {
				if(ClientPrefs.data.pauseMusic != 'None')
					FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));
				else FlxG.sound.music.volume = 0;
			}
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			FlxG.mouse.visible = false;
		}
	}

	inline function selectObj(obj1:FlxPoint, obj2:flixel.FlxObject):Bool {
		return obj1.x - obj2.x >= 0 && obj1.x - obj2.x <= obj2.width && obj1.y - obj2.y >= 0 && obj1.y - obj2.y <= obj2.height;
	}

	override public function beatHit() {
		super.beatHit();

		if(curBeat % 2 == 0) boyfriend.dance();
		gf.dance();
		
		if (!onComboMenu && camGame.zoom < 1.35) camGame.zoom += .0075;
	}

	override function sectionHit() {
		super.sectionHit();
		if (camGame.zoom < 1.35) camGame.zoom += .015;
	}

	function repositionCombo() {
		var placement:Float = FlxG.width * .35;

		rating.screenCenter(Y).y -= 60 + comboOffset[0][1];
		rating.x = placement - 40 + comboOffset[0][0];

		comboNums.screenCenter(Y).y += 80 - comboOffset[1][1];
		comboNums.x = placement - 90 + comboOffset[1][0];

		combo.screenCenter(Y).y -= comboOffset[2][1];
		combo.x = placement + comboOffset[2][0];

		reloadTexts();
	}

	function createTexts(i:Int) {
		var text:FlxText = new FlxText(10, 48 + (i * 30), 0, '', 24);
		text.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT);
		text.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		text.scrollFactor.set();
		text.camera = camHUD;

		dumbTexts.add(text);
		text.y += Math.floor(i / 2) * 24;
	}

	function reloadTexts() {
		var num:Int = 0;
		for (i in ['Rating', 'Number', 'Combo', 'Late/Early']) {
			if (onComboMenu) setDumbText(num, '$i Offset:', '[${comboOffset[num][0]}, ${comboOffset[num][1]}]');
			else setDumbText(num, '', '');
			num++;
		}
	}

	function setDumbText(i:Int, text1:String, text2:String) {
		i = Math.floor(i * 2);

		var m = dumbTexts.members;
		if (m[i] != null && m[i].text != text1) m[i].text = text1;
		if (m[i + 1] != null && m[i + 1].text != text2) m[i + 1].text = text2;
	}

	function updateNoteDelay() {
		ClientPrefs.prefs.set('noteOffset', Math.round(barPercent));
		timeTxt.text = 'Current offset: ' + Math.floor(barPercent) + ' ms';
	}

	function updateMode() {
		rating.visible = comboNums.visible = combo.visible = onComboMenu;
		dumbTexts.visible = onComboMenu;
		
		timeBar.visible = timeTxt.visible = !onComboMenu;

		var str2:String = '(Press Accept to Switch)';
		var str:String = onComboMenu ? 'Combo Offset' : 'Note/Beat Delay';

		changeModeText.text = '< ${str.toUpperCase()} ${str2.toUpperCase()} >';

		changeModeText.text = changeModeText.text.toUpperCase();
		FlxG.mouse.visible = onComboMenu;
	}

	override function destroy() {
		startMousePos = flixel.util.FlxDestroyUtil.put(startMousePos);
		startComboOffset = flixel.util.FlxDestroyUtil.put(startComboOffset);
		super.destroy();
	}
}
