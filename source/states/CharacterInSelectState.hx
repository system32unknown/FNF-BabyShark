package states;

import flixel.*;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import game.Boyfriend;
import game.Conductor;
import game.HealthIcon;
import game.BGSprite;
/**
    hey you fun commiting people, 
    i don't know about the rest of the mod but since this is basically 99% my code 
    i do not give you guys permission to grab this specific code and re-use it in your own mods without asking me first.
    the secondary dev, ben
*/
class CharacterInSelect
{
	public var names:Array<String>;
	public var polishedNames:Array<String>;

	public function new(names:Array<String>, polishedNames:Array<String>) {
		this.names = names;
		this.polishedNames = polishedNames;
	}
}
class CharacterSelectState extends MusicBeatState
{
	public var char:Boyfriend;
	public var current:Int = 0;
	public var currentReal:Int = 0;
	public var curForm:Int = 0;
	public var characterText:FlxText;

	public var funnyIconMan:HealthIcon;

	public var pressedTheFunny:Bool = false;

	var selectedCharacter:Bool = false;

	var camHUD:FlxCamera;
	var camGame:FlxCamera;

	var currentSelectedCharacter:CharacterInSelect;

	public var characters:Array<CharacterInSelect> = [
		new CharacterInSelect(['bf', 'bf-pixel', 'bf-christmas', 'bf-holding-gf'], ["Boyfriend", "Pixel Boyfriend", "Christmas Boyfriend", 'BF and GF']),
		new CharacterInSelect(['bs', 'bs-true', 'bs-at'], ["Baby Shark", 'Baby Shark True form', 'Baby Shark And Altertoriel']),
		new CharacterInSelect(['pico-player'], ["Pico"]),
		new CharacterInSelect(['nate-player'], ["Nate the Hunter Baby Shark"]),
	];
	
	override public function create():Void 
	{
		super.create();

		Conductor.changeBPM(110);

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		currentSelectedCharacter = characters[currentReal];

		FlxG.sound.playMusic(Paths.music("good-ending"), 1, true);

		var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
		add(bg);

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

		FlxG.camera.zoom = .75;
		camHUD.zoom = .75;

		char = new Boyfriend(FlxG.width / 2, FlxG.height / 2, "bf");
		char.screenCenter();
		char.y = 450;
		add(char);
		
		characterText = new FlxText((FlxG.width / 9) - 50, (FlxG.height / 8) - 225, 1080, "Boyfriend");
		characterText.setFormat(Paths.font("comic.ttf"), 90, FlxColor.WHITE, CENTER);
        characterText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 7);
		characterText.autoSize = false;
		characterText.screenCenter(X);
		characterText.cameras = [camHUD];
		add(characterText);

		funnyIconMan = new HealthIcon('bf', true);
		funnyIconMan.setPosition(FlxG.width / 2, characterText.y + characterText.height);
		funnyIconMan.cameras = [camHUD];
		add(funnyIconMan);
		funnyIconMan.screenCenter(X);
	}

	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE)
		{
			MusicBeatState.switchState(new FreeplayState());
		}

		if(controls.UI_LEFT_P && !pressedTheFunny) {
			char.playAnim('singLEFT', true);
		}
		if(controls.UI_RIGHT_P && !pressedTheFunny) {
			char.playAnim('singRIGHT', true);
		}
		if(controls.UI_UP_P && !pressedTheFunny) {
			char.playAnim('singUP', true);
		}
		if(controls.UI_DOWN_P && !pressedTheFunny) {
			char.playAnim('singDOWN', true);
		}
		if (controls.ACCEPT)
		{
			if (pressedTheFunny)
				return;
			else pressedTheFunny = true;

			selectedCharacter = true;
			var heyAnimation:Bool = char.animation.getByName("hey") != null; 
			char.playAnim(heyAnimation ? 'hey' : 'singUP', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music('gameOverEnd'));
			new FlxTimer().start(1.9, endIt);
		}
		if (FlxG.keys.justPressed.LEFT && !selectedCharacter){
			changeChr(-1);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}
		if (FlxG.keys.justPressed.RIGHT && !selectedCharacter) {
			changeChr(1);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		if (FlxG.keys.justPressed.DOWN && !selectedCharacter) {
			changeForm(-1);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}
		if (FlxG.keys.justPressed.UP && !selectedCharacter) {
			changeForm(1);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}
	}

	function changeChr(chr:Int = 0) {
		curForm = 0;
		current = FlxMath.wrap(current + chr, 0, characters.length - 1);
		currentReal = current;
		UpdateBF();
	}
	function changeForm(form:Int = 0) {
		curForm = 0;
		curForm = FlxMath.wrap(curForm + form, 0, characters[currentReal].names.length - 1);
		UpdateBF();
	}

	public function UpdateBF()
	{
		funnyIconMan.color = FlxColor.WHITE;
		currentSelectedCharacter = characters[currentReal];
		characterText.text = currentSelectedCharacter.polishedNames[curForm];
		char.destroy();
		char = new Boyfriend(FlxG.width / 2, FlxG.height / 2, currentSelectedCharacter.names[curForm]);
		char.screenCenter();
		char.y = 450;

		add(char);
		funnyIconMan.changeIcon(char.healthIcon);
		funnyIconMan.y = characterText.y + characterText.height;
		characterText.screenCenter(X);
	}

	override function beatHit()
	{
		super.beatHit();
		if (char != null && !selectedCharacter && curBeat % 2 == 0) {
			char.playAnim('idle', true);
		}
	}
	
	public function endIt(e:FlxTimer = null)
	{
		//PlayState.characteroverride = currentSelectedCharacter.names[0];
		//PlayState.formoverride = currentSelectedCharacter.names[curForm];
		LoadingState.loadAndSwitchState(new FreeplayState());
	}
}