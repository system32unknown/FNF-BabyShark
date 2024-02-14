package states;

import objects.Character;
import objects.HealthIcon;

/**
    This is not from the D&B source code, it's completely made by me (Delta), and Modified by Altertoriel.
**/
class CharacterSelectionState extends MusicBeatState {
	//["character name", [["form 1 name", 'character json name'], ["form 2 name (can add more than just one)", 'character json name 2']], true], 
    static var characterData:Array<Dynamic> = [
        ["Boyfriend", [["Boyfriend", 'bf'], ["Boyfriend (Pixel)", 'bf-pixel'], ["Boyfriend (Christmas)", 'bf-christmas'], ["Boyfriend and Girlfriend", 'bf-holding-gf']], false],
        ["Ollie", [["Baby Shark Ollie", 'bs'], ["Baby Shark Ollie (Pixel)", 'bs-pixel'], ["Baby Shark Ollie And Altertoriel", 'alter-holding-bs']], false], 
		["Dave", [["Dave", 'dave-playable']], false],
		["Bambi", [["Bambi", 'bambi-playable']], false],
		["Tristan", [["Tristan", 'tristan'], ["Golden Tristan", 'golden-tristan']], false],
		["Expunged", [["Expunged (Cheating)", 'cheating-expunged'], ["Expunged (Unfair)", 'unfair-expunged'], ["True Expunged", 'true-Expunged']], false],
    ];

	var boyfriendGroup:FlxSpriteGroup;
	var boyfriend:Character;

	var gfGroup:FlxSpriteGroup;
	var gf:Character;

	public static var characterFile:String = 'bf';

	final BF_POS:Array<Float> = [770, 100];
	final GF_POS:Array<Float> = [400, 130];

	var curSelected:Int = 0;
	var curSelectedForm:Int = 0;
	var curText:FlxText;
	var curIcon:HealthIcon;
	var controlsText:FlxText;
	var entering:Bool = false;

	var previewMode:Bool = false;
	var unlocked:Bool = true;

	var camGame:FlxCamera;
	var camHUD:FlxCamera;

	override function create() {
		#if DISCORD_ALLOWED DiscordClient.changePresence('Selecting Character'); #end

		FlxG.fixedTimestep = false;
		persistentUpdate = true;

		camGame = initPsychCamera();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		var lastLoaded:String = Paths.currentLevel;
		Paths.currentLevel = 'week1';
		new states.stages.StageWeek1();
		camGame.scroll.set(120, 130);

		camGame.zoom = .75;
		camHUD.zoom = .75;

		gfGroup = new FlxSpriteGroup(GF_POS[0], GF_POS[1]);
		boyfriendGroup = new FlxSpriteGroup(BF_POS[0], BF_POS[1]);
		
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
		
		var tutorialThing:FlxSprite = new FlxSprite(-125, -100).loadGraphic(Paths.image('charSelectGuide'));
		tutorialThing.setGraphicSize(Std.int(tutorialThing.width * 1.25));
		tutorialThing.scrollFactor.set();
		tutorialThing.camera = camHUD;
		add(tutorialThing);

		curText = new FlxText(0, -100, 0, characterData[curSelected][1][0][0], 50);
		curText.setFormat(Paths.font("comic.ttf"), 50, FlxColor.WHITE, CENTER);
		curText.setBorderStyle(OUTLINE, FlxColor.BLACK, 5);
		curText.camera = camHUD;
		curText.scrollFactor.set();
		curText.screenCenter(X);
		add(curText);

		controlsText = new FlxText(-125, 125, 0, 'Press P to enter preview mode.', 20);
		controlsText.setFormat(Paths.font("comic.ttf"), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		controlsText.scrollFactor.set();
		controlsText.camera = camHUD;
		add(controlsText);

		curIcon = new HealthIcon(boyfriend.healthIcon, true);
		curIcon.scrollFactor.set();
		curIcon.screenCenter(X).y = (curText.y + curIcon.height) - 100;
		curIcon.camera = camHUD;
		add(curIcon);

		changeCharacter();
        Paths.currentLevel = lastLoaded;

		Conductor.usePlayState = false;
		Conductor.mapBPMChanges(true);
		Conductor.bpm = 110;
		FlxG.sound.playMusic(Paths.music('good-ending'));

		super.create();
	}

	function checkPreview() {
		if (previewMode) controlsText.text = "PREVIEW MODE\nPress I to play idle animation.\nPress your controls to play an animation.\n";
		else {
			controlsText.text = "Press P to enter preview mode.";
			boyfriend.playAnim('idle');
		}
	}

	override public function beatHit() {
		super.beatHit();
		if (!entering) {
			if (camGame.zoom < 1.35) camGame.zoom += .0075;
			if (curBeat % 2 == 0) boyfriend.dance();
			gf.dance();
		}
	}

	override function update(elapsed) {
		Conductor.songPosition = FlxG.sound.music.time;
		super.update(elapsed);

		camGame.zoom = FlxMath.lerp(.7, camGame.zoom, Math.exp(-elapsed * 3.125));

		if (FlxG.keys.justPressed.P && unlocked && !entering) {
			previewMode = !previewMode;
			checkPreview();
		}
		if (!previewMode) {
			if (controls.UI_RIGHT_P || controls.UI_LEFT_P) changeCharacter(controls.UI_RIGHT_P ? 1 : -1);
			if ((controls.UI_DOWN_P || controls.UI_UP_P) && unlocked) changeForm(controls.UI_DOWN_P ? 1 : -1);
			if (controls.ACCEPT && unlocked) acceptCharacter();
		} else {
			if (controls.NOTE_LEFT_P) if (boyfriend.animOffsets.exists('singLEFT')) boyfriend.playAnim('singLEFT');
			if (controls.NOTE_DOWN_P) if (boyfriend.animOffsets.exists('singDOWN')) boyfriend.playAnim('singDOWN');
			if (controls.NOTE_UP_P) if (boyfriend.animOffsets.exists('singUP')) boyfriend.playAnim('singUP');
			if (controls.NOTE_RIGHT_P) if (boyfriend.animOffsets.exists('singRIGHT')) boyfriend.playAnim('singRIGHT');
			if (FlxG.keys.justPressed.I) boyfriend.playAnim('idle');
		}

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(() -> new FreeplayState());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}
	}

	function changeCharacter(change:Int = 0, playSound:Bool = true) {
		if (entering) return;

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

	function changeForm(change:Int) {
		var chrData:Array<Array<String>> = characterData[curSelected][1];
		if (!entering && chrData.length >= 2) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
			curSelectedForm = FlxMath.wrap(curSelectedForm + change, 0, chrData.length - 1);

			curText.text = chrData[curSelectedForm][0];
			characterFile = chrData[curSelectedForm][1];
			reloadCharacter();
			curText.screenCenter(X);
		}
	}

	function reloadCharacter() {
		boyfriend.destroy();
		boyfriendGroup.remove(boyfriend, true);
		boyfriend = new Character(0, 0, characterFile, true);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		boyfriend.dance();
		boyfriendGroup.add(boyfriend);

		curIcon.changeIcon(boyfriend.healthIcon);
		curIcon.y = (curText.y + curIcon.height) - 100;

		if (!unlocked) boyfriend.color = FlxColor.BLACK;
		curIcon.color = unlocked ? FlxColor.WHITE : FlxColor.BLACK;
	}

	function acceptCharacter() {
		if (entering) return;

		entering = true;
		if (boyfriend.animOffsets.exists('hey') && boyfriend.animation.getByName('hey') != null)
			boyfriend.playAnim('hey');
		else boyfriend.playAnim('singUP');

		if (gf.animOffsets.exists('cheer') && gf.animation.getByName('cheer') != null)
			gf.playAnim('cheer');

		FlxG.sound.playMusic(Paths.music('gameOverEnd'));
		new FlxTimer().start(1.5, (tmr:FlxTimer) -> {
			PlayState.SONG.gfVersion = switch(characterFile) {
				case 'bf-pixel': 'gf-pixel';
				case 'bf-christmas': 'gf-christmas';
				case 'bs': 'gfbf';
				case 'dave-playable' | 'bambi-playable' | 'bf-holding-gf': 'speaker';
				default: PlayState.SONG.gfVersion;
			}

			PlayState.SONG.player1 = characterFile;
            LoadingState.prepareToSong();
			LoadingState.loadAndSwitchState(() -> new PlayState());
		});
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
