package states;

import flixel.math.FlxPoint;
import objects.Character;
import objects.HealthIcon;
import utils.MathUtil;

class CharacterInSelect {
	public var forms:Array<CharacterForm>;
	public function new(forms:Array<CharacterForm>) {
		this.forms = forms;
	}
}

class CharacterForm
{
	public var name:String;
	public var polishedName:String;

	public function new(name:String, polishedName:String) {
		this.name = name;
		this.polishedName = polishedName;
	}
}

class CharacterSelectState extends MusicBeatState
{
	public var char:Character;
	public var current:Int = 0;
	public var curForm:Int = 0;
	public var characterText:FlxText;

	public var funnyIconMan:HealthIcon;

	public var pressedTheFunny:Bool = false;

	var selectedCharacter:Bool = false;

	var camHUD:FlxCamera;
	var camGame:FlxCamera;
	var camTransition:FlxCamera;

	var currentSelectedCharacter:CharacterInSelect;
	var basePosition:FlxPoint;

	public var characters:Array<CharacterInSelect> = [
		new CharacterInSelect([
			new CharacterForm('bf', 'Boyfriend'),
			new CharacterForm('bf-pixel', 'Pixel Boyfriend')
		]),
		new CharacterInSelect([
			new CharacterForm('bs', 'Baby Shark'),
			new CharacterForm('bs-pixel', 'Pixel Baby Shark')
		]),
		new CharacterInSelect([new CharacterForm('dave', 'Dave')]),
		new CharacterInSelect([new CharacterForm('bambi-new', 'Bambi')]),
		new CharacterInSelect([new CharacterForm('tristan', 'Tristan')]),
		new CharacterInSelect([new CharacterForm('tristan-golden', 'Golden Tristan')]),
		new CharacterInSelect([new CharacterForm('dave-angey', '3D Dave')]),
		new CharacterInSelect([new CharacterForm('bambi-3d', 'Expunged')])
	];

	override public function create():Void {
		Conductor.bpm = 110;

		camGame = new FlxCamera();
		camTransition = new FlxCamera();
		camTransition.bgColor.alpha = 0;
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camTransition, false);
        
        FlxG.cameras.setDefaultDrawTarget(camGame, true);
        CustomFadeTransition.nextCamera = camTransition;
        FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		camGame.scroll.set(120, 130);
		FlxG.camera.zoom = .7;
		camHUD.zoom = 0.75;

		if (FlxG.save.data.charactersUnlocked == null) reset();
		currentSelectedCharacter = characters[current];

		// create BG
		Paths.setCurrentLevel('week1');
		add(new BGSprite('stageback', -600, -200, 0.9, 0.9));

		var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		add(stageFront);

		if(!ClientPrefs.getPref('lowQuality')) {
			var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
			stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
			stageLight.updateHitbox();
			add(stageLight);
			var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
			stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
			stageLight.updateHitbox();
			stageLight.flipX = true;
			add(stageLight);

			var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
			stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
			stageCurtains.updateHitbox();
			add(stageCurtains);
        }

		char = new Character(FlxG.width / 2, FlxG.height / 2, 'bf', true);
		char.camera = camHUD;
		char.screenCenter();
		add(char);

		basePosition = char.getPosition();

		characterText = new FlxText((FlxG.width / 9) - 50, (FlxG.height / 8) - 225, "Boyfriend");
		characterText.setFormat(Paths.font("comic.ttf"), 90, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		characterText.autoSize = false;
		characterText.fieldWidth = 1080;
		characterText.borderSize = 5;
		characterText.screenCenter(X);
		characterText.camera = camHUD;
		characterText.antialiasing = true;
		characterText.y = FlxG.height - 180;
		add(characterText);

		var resetText = new FlxText(FlxG.width, FlxG.height, "Press R to Reset Character.");
		resetText.setFormat(Paths.font("comic.ttf"), 30, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		resetText.autoSize = false;
		resetText.fieldWidth = FlxG.height;
		resetText.x -= resetText.textField.textWidth + 100;
		resetText.y -= resetText.textField.textHeight - 100;
		resetText.borderSize = 3;
		resetText.camera = camHUD;
		resetText.antialiasing = true;
		add(resetText);

		funnyIconMan = new HealthIcon('bf', true);
		funnyIconMan.camera = camHUD;
		funnyIconMan.visible = false;
		funnyIconMan.antialiasing = true;
		updateIconPosition();
		add(funnyIconMan);

		super.create();

		CustomFadeTransition.nextCamera = camTransition;
	}


	override public function update(elapsed:Float):Void {
		Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);

		if (controls.BACK) LoadingState.loadAndSwitchState(new FreeplayState());

		if (controls.ACCEPT) {
			if (isLocked(characters[current].forms[curForm].name)) {
				FlxG.camera.shake(0.05, 0.1);
				return;
			}

			if (pressedTheFunny) return;
			else pressedTheFunny = true;
			selectedCharacter = true;

			var heyAnimation:Bool = char.animation.getByName("hey") != null;
			char.playAnim(heyAnimation ? 'hey' : 'singUP', true);

			FlxG.sound.music.fadeOut(1.9, 0);
			FlxG.sound.play(Paths.sound('confirmMenu'));
			new FlxTimer().start(1.9, (e:FlxTimer) -> {
                //PlayState.characteroverride = currentSelectedCharacter.name;
                //PlayState.formoverride = currentSelectedCharacter.forms[curForm].name;
        
                FlxG.sound.music.stop();
                LoadingState.loadAndSwitchState(new PlayState());
            });
		}
		if (controls.UI_LEFT_P && !selectedCharacter)
		{
			curForm = 0;
			current--;
			if (current < 0)
			{
				current = characters.length - 1;
			}
			UpdateBF();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		if (controls.UI_RIGHT_P && !selectedCharacter)
		{
			curForm = 0;
			current++;
			if (current > characters.length - 1)
			{
				current = 0;
			}
			UpdateBF();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		if (controls.UI_DOWN_P && !selectedCharacter)
		{
			curForm--;
			if (curForm < 0)
			{
				curForm = characters[current].forms.length - 1;
			}
			UpdateBF();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}
		if (controls.UI_UP_P && !selectedCharacter)
		{
			curForm++;
			if (curForm > characters[current].forms.length - 1)
			{
				curForm = 0;
			}
			UpdateBF();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}
		if (controls.RESET && !selectedCharacter) {
			reset();
			FlxG.resetState();
		}
	}

	public static function unlockCharacter(character:String) {
		if (!FlxG.save.data.charactersUnlocked.contains(character)) {
			FlxG.save.data.charactersUnlocked.push(character);
			FlxG.save.flush();
		}
	}

	public static function isLocked(character:String):Bool {
		return !FlxG.save.data.charactersUnlocked.contains(character);
	}

	public static function reset() {
		FlxG.save.data.charactersUnlocked = new Array<String>();
		unlockCharacter('bf');
		unlockCharacter('bf-pixel');
		unlockCharacter('bs');
		unlockCharacter('bs-pixel');
		FlxG.save.flush();
	}

	public function UpdateBF() {
		currentSelectedCharacter = characters[current];
		characterText.text = currentSelectedCharacter.forms[curForm].polishedName;
		char.destroy();
		char = new Character(basePosition.x, basePosition.y, currentSelectedCharacter.forms[curForm].name, true);
		char.camera = camHUD;

		switch (char.curCharacter) {
			case 'bambi-new':
				char.x -= 30;
			case 'bambi-3d':
				char.x -= 150;
				char.y += 100;
		}

        add(char);
		funnyIconMan.changeIcon(char.curCharacter);
		funnyIconMan.color = FlxColor.WHITE;
		if (isLocked(characters[current].forms[curForm].name)) {
			char.color = FlxColor.BLACK;
			funnyIconMan.color = FlxColor.BLACK;
			characterText.text = '???';
		}
		characterText.screenCenter(X);
		updateIconPosition();
	}

	override function beatHit() {
		super.beatHit();
		if (char != null && !selectedCharacter && curBeat % 2 == 0) {
			char.playAnim('idle', true);
		}
	}

	function updateIconPosition() {
		var yValues = MathUtil.getMinAndMax(funnyIconMan.height, characterText.height);

		funnyIconMan.x = characterText.x + characterText.width / 2;
		funnyIconMan.y = characterText.y + ((yValues[0] - yValues[1]) / 2);
	}
}