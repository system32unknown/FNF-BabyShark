package states;

import flixel.*;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
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
		new CharacterInSelect(['bf', 'bf-pixel', 'bf-christmas'], ["Boyfriend", "Pixel Boyfriend", "Christmas Boyfriend"]),
		new CharacterInSelect(['tristan, tristan-golden'], ["Tristan", "Golden Tristan"]),
		new CharacterInSelect(['dave', 'dave-future'], ["Dave Algebra Class", 'Dave (Robot Suit)']),
		new CharacterInSelect(['bambi', 'bambi-angry'], ['Bambi Bambi Bambi', 'Ripple Bambi']),
		new CharacterInSelect(['bs', 'bs-true', 'bs-at'], ["Baby Shark", 'Baby Shark True form', 'Baby Shark And Altertoriel']),
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

		FlxG.sound.playMusic(Paths.music("gameOver"), 1, true);

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
		funnyIconMan.sprTracker = characterText;
		funnyIconMan.cameras = [camHUD];
		funnyIconMan.visible = false;
		add(funnyIconMan);

		var tutorialThing:FlxSprite = new FlxSprite(-130, -90).loadGraphic(Paths.image('charSelectGuide'));
		tutorialThing.setGraphicSize(Std.int(tutorialThing.width * 1.5));
		tutorialThing.antialiasing = true;
		tutorialThing.cameras = [camHUD];
		add(tutorialThing);
	}

	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE)
		{
			LoadingState.loadAndSwitchState(new FreeplayState());
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
		if (FlxG.keys.justPressed.LEFT && !selectedCharacter)
		{
			curForm = 0;
			current--;
			if (current < 0) 
				current = characters.length - 1;
			if(current == 1) current = 0;
            switch(current) {
				case 2: currentReal = 2;
				case 3: currentReal = 2;
				case 4: currentReal = 2;
				case 5: currentReal = 3;
				default: currentReal = current;
			}
			UpdateBF();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		if (FlxG.keys.justPressed.RIGHT && !selectedCharacter) {
			curForm = 0;
			current++;
			if (current > characters.length - 1)
				current = 0;
			if(current == 1) current = 2;

			switch(current) {
				case 2: currentReal = 2;
				case 3: currentReal = 2;
				case 4: currentReal = 2;
				case 5: currentReal = 3;
				default: currentReal = current;
			}
			UpdateBF();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}
		if (FlxG.keys.justPressed.DOWN && !selectedCharacter)
		{
			curForm--;
			if (curForm < 0)
				curForm = characters[currentReal].names.length - 1;
			UpdateBF();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		if (FlxG.keys.justPressed.UP && !selectedCharacter)
		{
			curForm++;
			if (curForm > characters[currentReal].names.length - 1)
				curForm = 0;
			UpdateBF();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}
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

		switch (char.curCharacter) {
			case "tristan" | 'tristan-golden':
				char.y = 100 + 325;
			case 'dave' | 'dave-future':
				char.y = 100 + 160;
			case 'bambi', 'bambi-angry':
				char.y = 100 + 400;
				char.y -= 75;
		}
		add(char);
		funnyIconMan.animation.play(char.curCharacter);
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