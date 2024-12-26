package options;

import objects.Bar;
import objects.Character;
import flixel.util.FlxDestroyUtil;

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
	var defaultCamZoom:Float = .7;

	var boyfriendGroup:FlxSpriteGroup;
	var gfGroup:FlxSpriteGroup;

	var boyfriend:Character;
	var gf:Character;

	var rating:FlxSprite;
	var comboNums:FlxSpriteGroup;

	var dumbTexts:FlxTypedGroup<FlxText>;

	var modeConfigText:FlxText;
	var holdTimeText:FlxText;

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
		rating = new FlxSprite(Paths.image('judgements/sick'));
		rating.camera = camHUD;
		rating.setGraphicSize(rating.width * .7);
		rating.updateHitbox();
		add(rating);

		comboNums = new FlxSpriteGroup();
		comboNums.camera = camHUD;
		add(comboNums);

		var daLoop:Int = 0;
		for (i in [for (_ in 0...FlxG.random.int(3, 4)) FlxG.random.int(0, 9)]) {
			var numScore:FlxSprite = new FlxSprite(rating.x + (43 * daLoop++), Paths.image('number/num$i'));
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
		timeBar.gameCenter(X);
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

		modeConfigText = new FlxText(0, 4, FlxG.width, "", 32);
		modeConfigText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		modeConfigText.antialiasing = ClientPrefs.data.antialiasing;
		modeConfigText.scrollFactor.set();
		modeConfigText.camera = camHUD;
		add(modeConfigText);

		holdTimeText = new FlxText(0, 500, FlxG.width, "", 32);
		holdTimeText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		holdTimeText.scrollFactor.set();
		holdTimeText.cameras = [camHUD];
		holdTimeText.antialiasing = ClientPrefs.data.antialiasing;
		add(holdTimeText);

		// mouse
		mouse = new FlxSprite().makeGraphic(1, 1);
		mouse.setGraphicSize(18);
		mouse.updateHitbox();
		mouse.gameCenter();
		mouse.camera = camHUD;
		add(mouse);

		holdingObjectOffset = FlxPoint.get();
		mousePointer = FlxPoint.get();

		updateMode();

		Conductor.bpm = 128;
		FlxG.sound.playMusic(Paths.music('offsetSong'));

		super.create();
	}

	var acceptTime:Float = 0;
	override function update(elapsed:Float) {
		Conductor.songPosition = FlxG.sound.music.time;
		super.update(elapsed);

		camGame.zoom = FlxMath.lerp(defaultCamZoom, camGame.zoom, Math.exp(-elapsed * 3.125));

		if (Controls.pressed("accept") && holdingObject == -1) acceptTime += elapsed;
		else acceptTime = 0;

		if (acceptTime > .5) {
			acceptTime = -999999;
			onComboMenu = !onComboMenu;
			updateMode();
		}

		updateInput(elapsed);

		if (Controls.justPressed('back')) {
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

		holdTimeText.text = Std.string(holdTime);
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

		rating.gameCenter(Y).y -= 60 + comboOffset[0][1];
		rating.x = placement - 40 + comboOffset[0][0];

		comboNums.x = placement - 50 + comboOffset[1][0];
		comboNums.y = rating.y + 100 - comboOffset[1][1];

		reloadTexts();
	}

	function createTexts(i:Int) {
		var text:FlxText = new FlxText(10, 48 + (i * 30), 0, '', 24);
		text.setFormat(Paths.font("vcr.ttf"), 24);
		text.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		text.scrollFactor.set();
		text.camera = camHUD;

		dumbTexts.add(text);
		text.y += Math.floor(i / 2) * 24;
	}

	function reloadTexts() {
		var num:Int = 0;
		for (i in ['Rating', 'Number']) {
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
		for (i in 0...2) setObjectAlpha(i, onComboMenu ? 1 : .5);

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
		var addNum:Float = (FlxG.keys.pressed.SHIFT || Controls.pressed("pause")) ? 2.5 : (FlxG.keys.pressed.CONTROL && !byPixel) ? 0 : 1;
		var left:Bool = Controls.justPressed('ui_left'), right:Bool = Controls.justPressed('ui_right');
		var down:Bool = Controls.justPressed('ui_down'), up:Bool = Controls.justPressed('ui_up');

		FlxG.mouse.getViewPosition(camOther, mousePointer);

		if (onComboMenu) {
			mouse.x += (left ? -1 : right ? 1 : 0) * addNum * (byPixel ? 1 : elapsed * 300);
			mouse.y += (down ? 1 : up ? -1 : 0) * addNum * (byPixel ? 1 : elapsed * 300);
			mouse.alpha = Controls.pressed("accept") ? .8 : .5;
			if (left || right || down || up) mouse.visible = true;
			else if (FlxG.mouse.justPressed) mouse.visible = false;

			var justpressed:Bool = false;
			final lastaccepted:Bool = Controls.justPressed('accept');
			if (holdingObject != -1 && (justpressed = (Controls.justPressed('reset') || (nativeHoldingObject ? FlxG.mouse.justReleased : lastaccepted)))) {
				if (nativeHoldingObject) mouse.setPosition(mousePointer.x, mousePointer.y);
				modeConfigText.alpha = 1;
				for (i in 0...2) {
					setDumbTextAlpha(i, 1);
					setObjectAlpha(i, 1);
				}

				holdingObject = -1;
			}

			if (!justpressed && (FlxG.mouse.justPressed || lastaccepted)) {
				nativeHoldingObject = !lastaccepted;
				if (nativeHoldingObject) mouse.setPosition(mousePointer.x, mousePointer.y);

				var overlappedObj:Int = getOverlappedObject(mouse);
				if (overlappedObj != -1) {
					holdingObject = overlappedObj;
					modeConfigText.alpha = .5;
					for (i in 0...2) {
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

			if (Controls.justPressed('reset')) for (i in 0...comboOffset.length) for (j in 0...comboOffset[i].length) comboOffset[i][j] = 0;
		} else {
			var pix:Bool = Controls.pressed('ui_left') || Controls.pressed('ui_right');
			mouse.visible = false;

			if (left || right) holdTime += elapsed;
			else holdTime = 0;

			barPercent += (holdTime > .27 || pix) ? (left ? -1 : right ? 1 : 0) * addNum * (pix ? 1 : 100 * elapsed) : 0;
			if (Controls.justPressed('reset')) barPercent = holdTime = 0;
			updateNoteDelay();
		}
	}

	function setObjectAlpha(i:Int, alpha:Float) {
		var obj:Null<FlxSprite> = i == 0 ? rating : null;
		if (obj != null) obj.alpha = alpha;
		if (i == 1 && comboNums != null) for (v in comboNums) v.alpha = alpha;
	}

	function getOverlappedObject(pos:flixel.FlxObject):Int {
		if (rating != null && rating.overlaps(pos)) return 0;
		if (comboNums != null) for (v in comboNums) if (v.overlaps(pos)) return 1;
		return -1;
	}

	override function destroy() {
		holdingObjectOffset = FlxDestroyUtil.put(holdingObjectOffset);
		mousePointer = FlxDestroyUtil.put(mousePointer);
		super.destroy();
	}
}