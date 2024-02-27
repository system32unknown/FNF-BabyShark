package states;

import objects.Character;
import objects.HealthIcon;

class CharacterInSelect {
	public var forms:Array<CharacterForm>;
	public function new(forms:Array<CharacterForm>) {
		this.forms = forms;
	}
}

class CharacterForm {
	public var name:String;
	public var polishedName:String;

	public function new(name:String, polishedName:String) {
		this.name = name;
		this.polishedName = polishedName;
	}
}

/**
    This is not from the D&B source code, it's completely made by LatestRelic825, Modified by Altertoriel.
**/
class CharacterSelectionState extends MusicBeatState {
	var characters:Array<CharacterInSelect> = [
		new CharacterInSelect([new CharacterForm('bf', 'Boyfriend'), new CharacterForm('bf-pixel', 'Boyfriend (Pixel)'), new CharacterForm('bf-christmas', 'Boyfriend (Christmas)'), new CharacterForm('bf-holding-gf', 'Boyfriend and Girlfriend')]),
		new CharacterInSelect([new CharacterForm('bs', 'Baby Shark Ollie'), new CharacterForm('bs-pixel', 'Baby Shark Ollie (Pixel)'), new CharacterForm('alter-holding-bs', 'Baby Shark Ollie And Altertoriel')]),
		new CharacterInSelect([new CharacterForm('dave-player', 'Dave'),]),
		new CharacterInSelect([new CharacterForm('bambi-player', 'Bambi'),]),
		new CharacterInSelect([new CharacterForm('tristan', 'Tristan'), new CharacterForm('tristan-golden', 'Golden Tristan')]),
		new CharacterInSelect([new CharacterForm('cheating-player', 'Expunged (Cheating)'), new CharacterForm('unfair-player', 'Expunged (Unfair)'), new CharacterForm('true-expunged-player', 'Expunged (True form)'),]),
		new CharacterInSelect([new CharacterForm('pico-player', 'Pico'),]),
		new CharacterInSelect([new CharacterForm('nate-player', 'Nate'),]),
	];
	static var unlockedChrs:Array<String>;
	
	var current:Int = 0;
	var curForm:Int = 0;

	var boyfriendGroup:FlxSpriteGroup;
	var char:Character;

	var gfGroup:FlxSpriteGroup;
	var gf:Character;

	public static var characterFile:String = 'bf';

	final BF_POS:Array<Float> = [770, 100];
	final GF_POS:Array<Float> = [400, 130];

	var characterText:FlxText;
	var curIcon:HealthIcon;
	var controlsText:FlxText;

	var previewMode:Bool = false;
	var selectedCharacter:Bool = false;
	var pressedTheFunny:Bool = false;

	var camGame:FlxCamera;
	var camHUD:FlxCamera;

	var currentSelectedCharacter:CharacterInSelect;
	final singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	override function create() {
		#if DISCORD_ALLOWED DiscordClient.changePresence('Selecting Character'); #end
		unlockedChrs = ClientPrefs.getPref('unlockedCharacters');

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

		char = new Character(0, 0, 'bf', true);
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
		boyfriendGroup.add(char);

		add(gfGroup);
		add(boyfriendGroup);
		
		var tutorialThing:FlxSprite = new FlxSprite(-125, -100).loadGraphic(Paths.image('charSelectGuide'));
		tutorialThing.setGraphicSize(Std.int(tutorialThing.width * 1.25));
		tutorialThing.scrollFactor.set();
		tutorialThing.camera = camHUD;
		add(tutorialThing);

		characterText = new FlxText(0, -100, 0, "Boyfriend", 50);
		characterText.setFormat(Paths.font("comic.ttf"), 50, FlxColor.WHITE, CENTER);
		characterText.setBorderStyle(OUTLINE, FlxColor.BLACK, 5);
		characterText.camera = camHUD;
		characterText.scrollFactor.set();
		characterText.screenCenter(X);
		add(characterText);

		controlsText = new FlxText(-125, 125, 0, 'Press P to enter preview mode.', 20);
		controlsText.setFormat(Paths.font("comic.ttf"), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		controlsText.scrollFactor.set();
		controlsText.camera = camHUD;
		add(controlsText);

		curIcon = new HealthIcon(char.healthIcon, true);
		curIcon.scrollFactor.set();
		curIcon.screenCenter(X);
		curIcon.camera = camHUD;
		updateIconPosition();
		add(curIcon);

		if (unlockedChrs == null) currentSelectedCharacter = characters[current];

        Paths.currentLevel = lastLoaded;

		Conductor.usePlayState = false;
		Conductor.mapBPMChanges(true);
		Conductor.bpm = 110;
		FlxG.sound.playMusic(Paths.music('good-ending'));

		super.create();
	}

	function checkPreview() {
		if (previewMode) controlsText.text = "PREVIEW MODE\nPress your controls to play an animation.\n(Press P to exit.)";
		else {
			controlsText.text = "Press P to enter preview mode.";
			char.playAnim('idle', true);
		}
	}

	override public function beatHit() {
		super.beatHit();
		if (!selectedCharacter) {
			if (camGame.zoom < 1.35) camGame.zoom += .0075;
			if (curBeat % 2 == 0 && char != null) char.dance();
			gf.dance();
		}
	}

	override function update(elapsed) {
		Conductor.songPosition = FlxG.sound.music.time;
		var controlSet:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
		super.update(elapsed);

		camGame.zoom = FlxMath.lerp(.7, camGame.zoom, Math.exp(-elapsed * 3.125));

		for (i in 0...controlSet.length) {
			if (controlSet[i] && !pressedTheFunny && previewMode && char.animOffsets.exists(singAnimations[i])) {
				char.playAnim(singAnimations[i], true);
			}
		}

		if (controls.ACCEPT) {
			if (isLocked(characters[current].forms[curForm].name)) {
				FlxG.camera.shake(.05, .1);
				FlxG.sound.play(Paths.sound('badnoise1'), .9);
				return;
			}

			if (pressedTheFunny) return;
			else pressedTheFunny = true;

			selectedCharacter = true;
			if (char.animOffsets.exists('hey') && char.animation.getByName('hey') != null)
				char.playAnim('hey', true);
			else char.playAnim('singUP', true);
			if (gf.animOffsets.exists('cheer') && gf.animation.getByName('cheer') != null)
				gf.playAnim('cheer', true);

			FlxG.sound.playMusic(Paths.music('gameOverEnd'));

			new FlxTimer().start(1.9, (e:FlxTimer) -> {
				PlayState.SONG.gfVersion = switch(characterFile) {
					case 'bf-pixel': 'gf-pixel';
					case 'bf-christmas': 'gf-christmas';
					case 'bs' | 'pico-player' | 'nate-player': 'gfbf';
					case 'bf-holding-gf': 'speaker';
					default: PlayState.SONG.gfVersion;
				}
				PlayState.SONG.player1 = characterFile;
				LoadingState.prepareToSong();
				LoadingState.loadAndSwitchState(() -> new PlayState());
				#if !LOADING_SCREEN_ALLOWED FlxG.sound.music.stop(); #end
			});
		}

		if (FlxG.keys.justPressed.P && !selectedCharacter) {
			previewMode = !previewMode;
			checkPreview();
		}
		if (!selectedCharacter && !previewMode) {
			if (controls.UI_LEFT_P || controls.UI_RIGHT_P) {
				curForm = 0;
				current = FlxMath.wrap(current += (controls.UI_LEFT_P ? -1 : 1), 0, characters.length - 1);
				UpdateBF();
			}

			if (controls.UI_DOWN_P || controls.UI_UP_P) {
				curForm = FlxMath.wrap(curForm += (controls.UI_DOWN_P ? -1 : 1), 0, characters[current].forms.length - 1);
				UpdateBF();
			}
	
			if (controls.RESET) {
				reset();
				FlxG.resetState();
			}
		}

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(() -> new FreeplayState());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}
	}

	public static function unlockCharacter(character:String, save:Bool = false) {
		if (!unlockedChrs.contains(character)) unlockedChrs.push(character);
		ClientPrefs.prefs.set('unlockedCharacters', unlockedChrs);
		if (save) ClientPrefs.saveSettings();
	}

	public static function isLocked(character:String):Bool {
		return !unlockedChrs.contains(character);
	}

	public static function reset() {
		ClientPrefs.prefs.set("unlockedCharacters", ClientPrefs.defaultprefs.get('unlockedCharacters'));
		ClientPrefs.saveSettings();
	}

	function UpdateBF() {
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		currentSelectedCharacter = characters[current];
		characterText.text = currentSelectedCharacter.forms[curForm].polishedName;
		characterFile = currentSelectedCharacter.forms[curForm].name;

		char.destroy();
		boyfriendGroup.remove(char, true);
		char = new Character(0, 0, currentSelectedCharacter.forms[curForm].name, true);
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
		boyfriendGroup.add(char);

		curIcon.changeIcon(char.healthIcon);
		curIcon.color = FlxColor.WHITE;

		if (isLocked(characters[current].forms[curForm].name)) {
			char.color = FlxColor.BLACK;
			curIcon.color = FlxColor.BLACK;
			characterText.text = '???';
		}
		characterText.screenCenter(X);
		updateIconPosition();
	}

	function updateIconPosition() {
		var yValues = utils.MathUtil.getMinAndMax(curIcon.height, characterText.height);
		curIcon.y = characterText.y - ((yValues[0] - yValues[1]) / 2);
	}
}