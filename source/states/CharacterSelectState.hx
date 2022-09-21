package states;

#if desktop
import utils.Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import game.Character;
import ui.HealthIcon;
import backgrounds.BGSprite;
import utils.ClientPrefs;
/**
 hey you fun commiting people, 
 i don't know about the rest of the mod but since this is basically 99% my code 
 i do not give you guys permission to grab this specific code and re-use it in your own mods without asking me first.
 the secondary dev, ben

 -I will credit your code, ben.
 -Altertoriel
*/

class CharacterInSelect
{
	public var names:Array<String>;
	public var polishedNames:Array<String>;

	public function new(names:Array<String>, polishedNames:Array<String>)
	{
		this.names = names;
		this.polishedNames = polishedNames;
	}
}

class CharacterSelectState extends MusicBeatState
{
	public var char:Character;
	private var curForm:Int = 0;
	public var characterText:FlxText;
	public var funnyIconMan:HealthIcon;

	var PressedTheFunny:Bool = false;
	var selectedCharacter:Bool = false;

	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;
	
	public var characters:CharacterInSelect = new CharacterInSelect(['bf', 'bf-car', 'bf-christmas', 'bf-pixel', 'bs'], ["Boyfriend", "Car Boyfriend", "Christmas Boyfriend", "Pixel Boyfriend", "Baby Shark"]);
	
	override public function create():Void {   
		#if desktop
		DiscordClient.changePresence("In the Character Selects", null);
		#end

		// Cameras
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		FlxG.camera.scroll.set(100, 130);
		FlxG.camera.zoom = .95;

		persistentUpdate = true;
		FlxG.sound.pause();
		FlxG.sound.playMusic(Paths.music("good-ending"));

		// Stage
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

		// Characters
		char = new Character(FlxG.width / 2, FlxG.height / 2, "bf", true);
		char.screenCenter();
		char.y += 10;
		add(char);
		
		characterText = new FlxText((FlxG.width / 9) - 50, (FlxG.height / 2) - 320, "Boyfriend");
		characterText.setFormat(Paths.font("vcr.ttf"), 70, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		characterText.fieldWidth = 1080;
		characterText.autoSize = false;
		characterText.borderSize = 5;
		characterText.screenCenter(X);
		characterText.cameras = [camHUD];
		add(characterText);

		funnyIconMan = new HealthIcon('bf', true);
		funnyIconMan.sprTracker = characterText;
		funnyIconMan.cameras = [camHUD];
		funnyIconMan.visible = false;
		add(funnyIconMan);

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.5;
		textBG.cameras = [camHUD];
		add(textBG);

		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, "Press ENTER to Select Character. / Press ESC to Return Freeplay.", 16);
		text.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		text.scrollFactor.set();
		text.cameras = [camHUD];
		add(text);

		var tutorialtext:FlxText = new FlxText(0, (FlxG.height / 2) - 320, "DOWN / UP ARROWS - CHANGE FORMS");
		tutorialtext.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tutorialtext.scrollFactor.set();
		tutorialtext.cameras = [camHUD];
		add(tutorialtext);

        super.create();
	}

	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE && !selectedCharacter) {
			persistentUpdate = false;
            FlxG.sound.playMusic(Paths.music('freakyMenu'));
			LoadingState.loadAndSwitchState(new FreeplayState());
		}

		if (controls.ACCEPT) {
			if (PressedTheFunny) {
				return;
            } else {
				PressedTheFunny = true;
			}
			selectedCharacter = true;
			var heyAnimation:Bool = char.animation.getByName("hey") != null; 
			char.playAnim(heyAnimation ? 'hey' : 'singUP', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music('gameOverEnd'));
			new FlxTimer().start(1.9, function(deadTime:FlxTimer) {
				//PlayState.formoverride = currentSelectedCharacter.names[curForm];
				persistentUpdate = false;
				LoadingState.loadAndSwitchState(new PlayState());
			});
		}

		if (FlxG.keys.justPressed.DOWN && !selectedCharacter) {
			curForm--;
			if (curForm < 0) {
				curForm = characters.names.length - 1;
			}
			UpdateBF();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		if (FlxG.keys.justPressed.UP && !selectedCharacter) {
			curForm++;
			if (curForm > characters.names.length - 1) {
				curForm = 0;
			}
			UpdateBF();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}
	}

	public function UpdateBF() {
		characterText.text = characters.polishedNames[curForm];
		char.destroy();
		char = new Character(FlxG.width / 2, FlxG.height / 2, characters.names[curForm], true);
		char.screenCenter();
		add(char);

		funnyIconMan.animation.play(char.curCharacter);
		characterText.screenCenter(X);
	}

	var lastBeatHit:Int = -1;
	override public function beatHit() {
		super.beatHit();

		if(lastBeatHit == curBeat) return;

		if (char != null && !selectedCharacter) {
			if (curBeat % 2 == 0) char.dance();
		}

		lastBeatHit = curBeat;
	}
}