package options;

import objects.Bar;
import objects.Character;

class NoteOffsetState extends MusicBeatState {
	var delayMin:Int = -500;
	var delayMax:Int = 500;
	var timeBar:Bar;
	var onComboMenu:Bool = true;

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
	var modeConfigText:FlxText;

	var barPercent:Float = 0;
	var timeTxt:FlxText;

	var mouse:FlxSprite;
	var holdingObjectOffset:FlxPoint;
	var mousePointer:FlxPoint;
	var nativeHoldingObject:Bool = false;
	var holdingObject:Int = -1;

	var comboOffset:Array<Array<Int>> = ClientPrefs.data.comboOffset;

	override function create() {
		#if DISCORD_ALLOWED DiscordClient.changePresence('Adjusting Offsets and Combos'); #end

		FlxG.fixedTimestep = false;
		persistentUpdate = true;

		FlxG.sound.destroy(true);
		Paths.clearUnusedMemory();
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
		for (i in 0...6) createTexts(i);

		repositionCombo();

		timeBar.camera = camHUD; add(timeBar);
		timeTxt.camera = camHUD; add(timeTxt);

		var bar:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 40, FlxColor.BLACK);
		bar.scrollFactor.set();
		bar.alpha = 0.6;
		bar.camera = camHUD;
		add(bar);

		modeConfigText = new FlxText(0, 4, FlxG.width, "", 32).setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		modeConfigText.antialiasing = ClientPrefs.data.antialiasing;
		modeConfigText.scrollFactor.set();
		modeConfigText.camera = camHUD;
		add(modeConfigText);

		// mouse
		mouse = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		mouse.setGraphicSize(18);
		mouse.updateHitbox();
		mouse.screenCenter();
		mouse.camera = camHUD;
		add(mouse);

		holdingObjectOffset = FlxPoint.get();
		mousePointer = FlxPoint.get();

		updateMode();

		Conductor.usePlayState = false;
		Conductor.mapBPMChanges(true);
		Conductor.bpm = 128;
		FlxG.sound.playMusic(Paths.music('offsetSong'));

		super.create();
	}

	var acceptTime:Float = 0;
	override function update(elapsed:Float) {
		Conductor.songPosition = FlxG.sound.music.time;
		super.update(elapsed);

		camGame.zoom = FlxMath.lerp(defaultCamZoom, camGame.zoom, Math.exp(-elapsed * 3.125));

		if (controls.ACCEPT_P && holdingObject == -1) acceptTime += elapsed;
		else acceptTime = 0;

		if (acceptTime > .5) {
			acceptTime = -999999;
			onComboMenu = !onComboMenu;
			updateMode();
		}

		updateInput(elapsed);

		if (controls.BACK) {
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

		repositionCombo();
		reloadTexts();
	}

	override function beatHit() {
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
		for (i in ['Rating', 'Number', 'Combo']) {
			if (onComboMenu) setDumbText(num, '$i Offset:', '[${comboOffset[num][0]}, ${comboOffset[num][1]}]');
			else setDumbText(num, '', '');
			num++;
		}
	}

	function setDumbText(i:Int, text1:String, text2:String) {
		i = Math.floor(i * 2);

		var m:Array<FlxText> = dumbTexts.members;
		if (m[i] != null && m[i].text != text1) m[i].text = text1;
		if (m[i + 1] != null && m[i + 1].text != text2) m[i + 1].text = text2;
	}

	function updateNoteDelay() {
		ClientPrefs.data.noteOffset = Math.round(barPercent);
		timeTxt.text = 'Current offset: ' + Math.floor(barPercent) + ' ms';
	}

	var pussy:Bool = false;
	function updateMode() {
		for (i in 0...3) setObjectAlpha(i, onComboMenu ? 1 : .5);

		var str2:String = '(Hold Accept to Switch)';
		var str:String = onComboMenu ? 'Rating Pop-up Position' : 'Timing Offset';
		modeConfigText.text = '< ${str.toUpperCase()} ${str2.toUpperCase()} >';
		FlxG.mouse.visible = onComboMenu;

		timeTxt.visible = timeBar.visible = !onComboMenu;

		if (onComboMenu) mouse.visible = pussy;
		else pussy = mouse.visible;
	}

	function setDumbTextAlpha(i:Int, alpha:Float) {
		i = Math.floor(i * 2);

		var m:Array<FlxText> = dumbTexts.members;
		if (m[i] != null) m[i].alpha = alpha;
		if (m[i + 1] != null) m[i + 1].alpha = alpha;
	}

	var holdTime:Float = 0;
	function updateInput(elapsed:Float) {
		var byPixel:Bool = FlxG.keys.justPressed.CONTROL;
		var addNum:Float = (FlxG.keys.pressed.SHIFT || controls.PAUSE_P) ? 2.5 : (FlxG.keys.pressed.CONTROL && !byPixel) ? 0 : 1;
		var left:Bool = controls.UI_LEFT, right:Bool = controls.UI_RIGHT;
		var down:Bool = controls.UI_DOWN, up:Bool = controls.UI_UP;

		FlxG.mouse.getScreenPosition(camOther, mousePointer);

		if (onComboMenu) {
			mouse.x += (left ? -1 : right ? 1 : 0) * addNum * (byPixel ? 1 : elapsed * 300);
			mouse.y += (down ? 1 : up ? -1 : 0) * addNum * (byPixel ? 1 : elapsed * 300);
			mouse.alpha = controls.ACCEPT_P ? .8 : .5;
			if (left || right || down || up) mouse.visible = true;
			else if (FlxG.mouse.justPressed) mouse.visible = false;

			var justpressed:Bool = false;
			if (holdingObject != -1 && (justpressed = (controls.RESET || (nativeHoldingObject ? FlxG.mouse.justReleased : controls.ACCEPT)))) {
				if (nativeHoldingObject) mouse.setPosition(mousePointer.x, mousePointer.y);
				modeConfigText.alpha = 1;
				for (i in 0...3) {
					setDumbTextAlpha(i, 1);
					setObjectAlpha(i, 1);
				}

				holdingObject = -1;
			}

			if (!justpressed && (FlxG.mouse.justPressed || controls.ACCEPT)) {
				nativeHoldingObject = !controls.ACCEPT;
				if (nativeHoldingObject) mouse.setPosition(mousePointer.x, mousePointer.y);

				var overlappedObj:Int = getOverlappedObject(mouse);
				if (overlappedObj != -1) {
					holdingObject = overlappedObj;
					modeConfigText.alpha = .5;
					for (i in 0...3) {
						setDumbTextAlpha(i, i == holdingObject ? 1 : .35);
						setObjectAlpha(i, i == holdingObject ? 1 : .5);
					}

					var v:Int = holdingObject;
					holdingObjectOffset.set(comboOffset[v][0] - (nativeHoldingObject ? mousePointer.x : mouse.x), -comboOffset[v][1] - (nativeHoldingObject ? mousePointer.y : mouse.y));
				} else if (!nativeHoldingObject || holdingObject == -1) holdingObject = -1;
			}

			if (holdingObject != -1) {
				var v:Int = holdingObject;
				comboOffset[v][0] = Math.floor((nativeHoldingObject ? mousePointer.x : mouse.x) + holdingObjectOffset.x);
				comboOffset[v][1] = -Math.floor((nativeHoldingObject ? mousePointer.y : mouse.y) + holdingObjectOffset.y);
			}

			if (controls.RESET) for (i in 0...comboOffset.length) for (j in 0...comboOffset[i].length) comboOffset[i][j] = 0;
		} else {
			var pix:Bool = controls.UI_LEFT_P || controls.UI_RIGHT_P;
			mouse.visible = false;

			if (left || right) holdTime += elapsed;
			else holdTime = 0;

			barPercent += (holdTime > .27 || pix) ? (left ? -1 : right ? 1 : 0) * addNum * (pix ? 1 : 100 * elapsed) : 0;
			if (controls.RESET) barPercent = holdTime = 0;
			updateNoteDelay();
		}
	}

	function setObjectAlpha(i:Int, alpha:Float) {
		var obj:Null<FlxSprite> = i == 0 ? rating : (i == 2 ? combo : null);
		if (obj != null) obj.alpha = alpha;

		if (i == 1 && comboNums != null) for (v in comboNums) v.alpha = alpha;
	}

	function getOverlappedObject(pos:flixel.FlxObject):Int {
		if (rating != null && rating.overlaps(pos)) return 0;
		if (comboNums != null) for (v in comboNums) if (v.overlaps(pos)) return 1;
		if (combo != null && combo.overlaps(pos)) return 2;
		return -1;
	}

	override function destroy() {
		holdingObjectOffset = flixel.util.FlxDestroyUtil.put(holdingObjectOffset);
		mousePointer = flixel.util.FlxDestroyUtil.put(mousePointer);
		super.destroy();
	}
}