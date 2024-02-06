package states;

import objects.Character;
import objects.HealthIcon;

/**
    This is not from the D&B source code, it's completely made by me (Delta).
    Modified by Altertoriel. (Ported to Psych 0.7.1b)
**/
class CharacterSelectionState extends MusicBeatState {
	//["character name", [["form 1 name", 'character json name'], ["form 2 name (can add more than just one)", 'character json name 2']], true], 
    public static var characterData:Array<Dynamic> = [
        ["Boyfriend", [["Boyfriend", 'bf'], ["Boyfriend (Pixel)", 'bf-pixel'], ["Boyfriend (Christmas)", 'bf-christmas'], ["Boyfriend and Girlfriend", 'bf-holding-gf']], false],
        ["Ollie", [["Baby Shark Ollie", 'bs'], ["Baby Shark Ollie (Pixel)", 'bs-pixel'], ["Baby Shark Ollie And Altertoriel", 'alter-holding-bs']], false], 
		["Dave", [["Dave", 'dave']], false],
		["Bambi", [["Bambi", 'bambi'], ["Bambi (Angry)", 'bambi-mad']], false],
		["Tristan", [["Tristan", 'tristan'], ["Golden Tristan", 'golden-tristan']], false],
		["Expunged", [["Expunged (Cheating)", 'cheating-expunged'], ["Expunged (Unfair)", 'unfair-expunged'], ["True Expunged", 'true-Expunged']], false],
    ];

	var characterSprite:Character;

	public static var characterFile:String = 'bf';

	var curSelected:Int = 0;
	var curSelectedForm:Int = 0;
	var curText:FlxText;
	var curIcon:HealthIcon;
	var controlsText:FlxText;
	var entering:Bool = false;

	var previewMode:Bool = false;
	var unlocked:Bool = true;

	public var camHUD:FlxCamera;

    final assetFolder = 'week1';
	override function create() {
		initPsychCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD);

		Conductor.usePlayState = false;
		Conductor.mapBPMChanges(true);
		Conductor.bpm = 110;
		FlxG.sound.playMusic(Paths.music('good-ending'));

		var lastLoaded:String = Paths.currentLevel;
		Paths.currentLevel = assetFolder;
		new states.stages.StageWeek1();

		FlxG.camera.zoom = .75;
		camHUD.zoom = .75;

		spawnSelection();
        Paths.currentLevel = lastLoaded;
		super.create();
	}

	var selectionStart:Bool = false;
	function spawnSelection() {
		selectionStart = true;
		var tutorialThing:FlxSprite = new FlxSprite(-125, -100).loadGraphic(Paths.image('charSelectGuide'));
		tutorialThing.setGraphicSize(Std.int(tutorialThing.width * 1.25));
		tutorialThing.antialiasing = true;
		add(tutorialThing);

		curText = new FlxText(0, -100, 0, characterData[curSelected][1][0][0], 50);
		curText.setFormat(Paths.font("comic.ttf"), 50, FlxColor.WHITE, CENTER);
		curText.setBorderStyle(OUTLINE, FlxColor.BLACK, 5);

		controlsText = new FlxText(-125, 125, 0, 'Press P to enter preview mode.', 20);
		controlsText.setFormat(Paths.font("comic.ttf"), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);

		characterSprite = new Character(0, 0, "bf", true);
		add(characterSprite);
		characterSprite.dance();
		characterSprite.screenCenter().y += 250;

		curIcon = new HealthIcon(characterSprite.healthIcon, true);
		curIcon.antialiasing = true;
		curIcon.y = curText.y + curIcon.height;

		add(curText);
		add(curIcon);
		add(controlsText);
		curText.camera = camHUD;
		controlsText.camera = camHUD;
		tutorialThing.camera = camHUD;
		curIcon.camera = camHUD;

		curText.screenCenter(X);
		curIcon.screenCenter(X);
		changeCharacter(0);
	}

	function checkPreview() {
		if (previewMode) controlsText.text = "PREVIEW MODE\nPress I to play idle animation.\nPress your controls to play an animation.\n";
		else {
			controlsText.text = "Press P to enter preview mode.";
			characterSprite.playAnim('idle');
		}
	}

	override function update(elapsed) {
		if (FlxG.keys.justPressed.P && selectionStart && unlocked && !entering) {
			previewMode = !previewMode;
			checkPreview();
		}
		if (selectionStart && !previewMode) {
			if (controls.UI_RIGHT_P || controls.UI_LEFT_P) changeCharacter(controls.UI_RIGHT_P ? 1 : -1);
			if ((controls.UI_DOWN_P || controls.UI_UP_P) && unlocked) changeForm(controls.UI_DOWN_P ? 1 : -1);
			if (controls.ACCEPT && unlocked) acceptCharacter();
		} else if (!previewMode) {
			if (controls.UI_RIGHT_P) {
				curSelected += 1;
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_LEFT_P) {
				curSelected = -1;
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (curSelected < 0) curSelected = 0;
			if (curSelected >= 2) curSelected = 0;
			if (controls.ACCEPT) {
				switch (curSelected) {
					case 0:
						FlxG.sound.music.stop();
						FlxTween.tween(camHUD, {alpha: 0}, .25, {ease: FlxEase.circOut});

                        LoadingState.prepareToSong();
						LoadingState.loadAndSwitchState(new PlayState());
					case 1:
						curSelected = 0;
						spawnSelection();
				}
			}
		} else {
			if (controls.NOTE_LEFT_P) if (characterSprite.animOffsets.exists('singLEFT')) characterSprite.playAnim('singLEFT');
			if (controls.NOTE_DOWN_P) if (characterSprite.animOffsets.exists('singDOWN')) characterSprite.playAnim('singDOWN');
			if (controls.NOTE_UP_P) if (characterSprite.animOffsets.exists('singUP')) characterSprite.playAnim('singUP');
			if (controls.NOTE_RIGHT_P) if (characterSprite.animOffsets.exists('singRIGHT')) characterSprite.playAnim('singRIGHT');
			if (FlxG.keys.justPressed.I) characterSprite.playAnim('idle');
		}

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new FreeplayState());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}
		super.update(elapsed);
	}

	function changeCharacter(change:Int, playSound:Bool = true) {
		if (!entering) {
			if (playSound) FlxG.sound.play(Paths.sound('scrollMenu'));
			curSelectedForm = 0;
            curSelected = FlxMath.wrap(curSelected + change, 0, characterData.length - 1);
			var unlockedChrs:Array<String> = ClientPrefs.getPref('unlockedCharacters');
			if (unlockedChrs.contains(characterData[curSelected][0]))
				unlocked = true;
			else unlocked = #if debug true #else false #end;

			characterFile = characterData[curSelected][1][0][1];

			if (unlocked) {
				curText.text = characterData[curSelected][1][0][0];
				reloadCharacter();
			} else if (!characterData[curSelected][3]) {
				curText.text = "???";
				reloadCharacter();
			} else changeCharacter(change, false);

			curText.screenCenter(X);
		}
	}

	function changeForm(change:Int) {
		if (!entering) {
			if (characterData[curSelected][1].length >= 2) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				curSelectedForm += change;

				if (curSelectedForm < 0) {
					curSelectedForm = characterData[curSelected][1].length;
					curSelectedForm -= 1;
				}
				if (curSelectedForm >= characterData[curSelected][1].length) curSelectedForm = 0;

				curText.text = characterData[curSelected][1][curSelectedForm][0];
				characterFile = characterData[curSelected][1][curSelectedForm][1];
				reloadCharacter();
				curText.screenCenter(X);
			}
		}
	}

	function reloadCharacter() {
		characterSprite.destroy();
		characterSprite = new Character(0, 0, characterFile, true);
		add(characterSprite);
		characterSprite.updateHitbox();
		characterSprite.dance();

		curIcon.changeIcon(characterSprite.healthIcon);
		curIcon.y = curText.y + curIcon.height;

		characterSprite.screenCenter().y += 250;
		if (!unlocked) characterSprite.color = FlxColor.BLACK;
		curIcon.color = unlocked ? FlxColor.WHITE : FlxColor.BLACK;
	}

	function acceptCharacter() {
		if (!entering) {
			entering = true;
			if (characterSprite.animOffsets.exists('hey') && characterSprite.animation.getByName('hey') != null)
				characterSprite.playAnim('hey');
			else characterSprite.playAnim('singUP');

			FlxG.sound.playMusic(Paths.music('gameOverEnd'));
			new FlxTimer().start(1.5, (tmr:FlxTimer) -> {
				var lastGF:String = PlayState.SONG.gfVersion;
				PlayState.SONG.gfVersion = switch (characterFile) {
					case 'bf-pixel': 'gf-pixel';
					case 'bf-christmas': 'gf-christmas';
					case 'bs': 'gfbf';
					default: lastGF;
				}

				PlayState.SONG.player1 = characterFile;
                LoadingState.prepareToSong();
				LoadingState.loadAndSwitchState(new PlayState());
			});
		}
	}
}

class CharacterUnlockObject extends flixel.group.FlxSpriteGroup {
	public var onFinish:Void->Void = null;

	var alphaTween:FlxTween;

	public function new(name:String, ?camera:FlxCamera = null, characterIcon:String, color:FlxColor = FlxColor.BLACK) {
		super(x, y);
		ClientPrefs.saveSettings();

		var characterBG:FlxSprite = new FlxSprite(60, 50).makeGraphic(420, 120, color);
		characterBG.scrollFactor.set();

		var characterIcon:HealthIcon = new HealthIcon(characterIcon, false);
		characterIcon.animation.curAnim.curFrame = 2;
        characterIcon.setPosition(characterBG.x + 10, characterBG.y + 10);
		characterIcon.scrollFactor.set();
		characterIcon.setGraphicSize(Std.int(characterIcon.width * (2 / 3)));
		characterIcon.updateHitbox();
		characterIcon.antialiasing = ClientPrefs.getPref('Antialiasing');

		var characterName:FlxText = new FlxText(characterIcon.x + characterIcon.width + 20, characterIcon.y + 16, 280, name, 16);
		characterName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		characterName.scrollFactor.set();

		var characterText:FlxText = new FlxText(characterName.x, characterName.y + 32, 280, "Play as this character in freeplay!", 16);
		characterText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		characterText.scrollFactor.set();

		add(characterBG);
		add(characterName);
		add(characterText);
		add(characterIcon);

		var cam:Array<FlxCamera> = @:privateAccess FlxCamera._defaultCameras;
		if (camera != null) cam = [camera];
		alpha = 0;
		characterBG.cameras = characterName.cameras = characterText.cameras = characterIcon.cameras = cam;
		alphaTween = FlxTween.tween(this, {alpha: 1}, 0.5, {
			onComplete: (twn:FlxTween) -> {
				alphaTween = FlxTween.tween(this, {alpha: 0}, 0.5, {
					startDelay: 2.5,
					onComplete: (twn:FlxTween) -> {
						alphaTween = null;
						remove(this);
						if (onFinish != null) onFinish();
					}
				});
			}
		});
	}

	override function destroy() {
		if (alphaTween != null) alphaTween.cancel();
		super.destroy();
	}
}
