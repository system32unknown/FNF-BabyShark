package substates;

import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.addons.transition.FlxTransitionableState;
import game.Boyfriend;
import game.Conductor;
import states.StoryMenuState;
import states.FreeplayState;
import data.WeekData;

class GameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend:Boyfriend;

	public var camOther:FlxCamera;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;

	var camFollow:FlxObject;
	var updateCamera:Bool = false;
	var playingDeathSound:Bool = false;

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	public static var instance:GameOverSubstate;

	public static function resetVariables() {
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
	}

	public static function cache() {
		Paths.sound(deathSoundName);
		Paths.music(loopSoundName);
		Paths.sound(endSoundName);

		if (PlayState.instance != null)
			PlayState.instance.gameOverChar = new Boyfriend(0, 0, characterName);
	}

	override function create() {
		instance = this;
		camOther.zoom = camHUD.zoom = 1;
		camOther.x = camOther.y = camOther.angle = camHUD.x = camHUD.y = camHUD.angle = 0;
		PlayState.instance.callOnLuas('onGameOverStart', []);
		utils.system.MemoryUtil.clearMajor();

		FlxG.sound.play(Paths.sound(deathSoundName));

		var anim = boyfriend.animation.getByName('firstDeath');
		boyfriend.playAnim('firstDeath');
		boyfriend.animation.frameIndex = anim.frames[0];

		super.create();
	}

	public function new(x:Float, y:Float, camX:Float, camY:Float)
	{
		super();

		PlayState.instance.setOnLuas('inGameOver', true);
		camOther = PlayState.instance.camOther;
		camHUD = PlayState.instance.camHUD;
		camGame = PlayState.instance.camGame;

		Conductor.songPosition = 0;
		Conductor.changeBPM(100);

		boyfriend = getBoyfriend(x, y);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(boyfriend);

		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend.playAnim('firstDeath');

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y);
		FlxG.camera.focusOn(new FlxPoint(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2)));
		add(camFollow);
	}

	var isFollowingAlready:Bool = false;
	override function update(elapsed:Float) {
		PlayState.instance.cleanupLuas();
		super.update(elapsed);

		PlayState.instance.callOnLuas('onUpdate', [elapsed]);

		if (controls.ACCEPT) endBullshit();

		if (controls.BACK) {
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			PlayState.chartingMode = false;

			WeekData.loadTheFirstEnabledMod();
			if (PlayState.isStoryMode) MusicBeatState.switchState(new StoryMenuState());
			else MusicBeatState.switchState(new FreeplayState());

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.instance.callOnLuas('onGameOverConfirm', [false]);
		}

		if (boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name == 'firstDeath') {
			if(boyfriend.animation.curAnim.curFrame >= 12 && !isFollowingAlready) {
				FlxG.camera.follow(camFollow, LOCKON, 0);
				updateCamera = true;
				isFollowingAlready = true;
			}
		}

		if(updateCamera) FlxG.camera.followLerp = FlxMath.bound(elapsed * 0.6, 0, 1);
		else FlxG.camera.followLerp = 0;

		if (FlxG.sound.music.playing) {
			Conductor.songPosition = FlxG.sound.music.time;
		}
		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);
	}

	var isEnding:Bool = false;
	var endCompleted:Bool = false;
	var quick:Bool = false;
	var slowass:FlxTimer;

	function resetState():Void {
		if (slowass != null) slowass.cancel();
		FlxTransitionableState.skipNextTransIn = true;
		MusicBeatState.resetState();
	}

	function coolStartDeath(?volume:Float = 1):Void {
		FlxG.sound.playMusic(Paths.music(loopSoundName), volume);
	}

	function endSoundComplete():Void {
		if (endCompleted) {
			resetState();
			return;
		}
		endCompleted = true;
	}

	function endBullshit():Void
	{
		if (isEnding) {
			quick = true;
			if (endCompleted) resetState();
			return;
		}
		isEnding = true;

		boyfriend.playAnim('deathConfirm', true);
		FlxG.sound.music.stop();

		var snd:FlxSound = FlxG.sound.play(Paths.music(endSoundName));
		snd.onComplete = endSoundComplete;

		new FlxTimer().start(0.7, function(tmr:FlxTimer) {
			FlxG.camera.fade(FlxColor.BLACK, if (quick) 1 else 2, false, function() {
				if (quick || endCompleted) resetState();
				endCompleted = true;

				if (!quick) {
					slowass = new FlxTimer().start(1.3, function(tmr:FlxTimer) {
						resetState();
						return;
					});
				}
			});
		});

		PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
	}

	function getBoyfriend(x:Float, y:Float):Boyfriend {
		var ins:PlayState = PlayState.instance;
		if (ins != null) {
			var bf = ins.gameOverChar;
			if (bf != null && bf.curCharacter == characterName) {
				bf.setPosition(x, y);
				return bf;
			}
		}

		var bf = ins.boyfriendMap.get(characterName);
		if (bf != null) {
			bf.setPosition(x, y);
			bf.visible = true;
			return bf;
		}

		return new Boyfriend(x, y, characterName);
	}
}
