package substates;

import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.addons.transition.FlxTransitionableState;
import objects.Character;

import states.StoryMenuState;
import states.FreeplayState;

class GameOverSubstate extends MusicBeatSubstate {
	public var boyfriend:Character;

	public var camOther:FlxCamera;
	public var camHUD:FlxCamera;

	var camFollow:FlxObject;
	var updateCamera:Bool = false;

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

		var _song = PlayState.SONG;
		if(_song != null) {
			if(_song.gameOverChar != null && _song.gameOverChar.trim().length > 0) characterName = _song.gameOverChar;
			if(_song.gameOverSound != null && _song.gameOverSound.trim().length > 0) deathSoundName = _song.gameOverSound;
			if(_song.gameOverLoop != null && _song.gameOverLoop.trim().length > 0) loopSoundName = _song.gameOverLoop;
			if(_song.gameOverEnd != null && _song.gameOverEnd.trim().length > 0) endSoundName = _song.gameOverEnd;
		}
	}

	public static function cache() {
		Paths.sound(deathSoundName);
		Paths.music(loopSoundName);
		Paths.sound(endSoundName);

		if (PlayState.instance != null)
			PlayState.instance.gameOverChar = new Character(0, 0, characterName, true);
	}

	override function create() {
		instance = this;
		camOther.zoom = camHUD.zoom = 1;
		camOther.x = camOther.y = camOther.angle = camHUD.x = camHUD.y = camHUD.angle = 0;
		PlayState.instance.callOnScripts('onGameOverStart', []);
		utils.system.MemoryUtil.clearMajor();

		FlxG.sound.play(Paths.sound(deathSoundName));

		var anim = boyfriend.animation.getByName('firstDeath');
		boyfriend.playAnim('firstDeath');
		boyfriend.animation.frameIndex = anim.frames[0];

		super.create();
	}

	public function new(x:Float, y:Float, camX:Float, camY:Float) {
		super();

		PlayState.instance.setOnLuas('inGameOver', true);
		camOther = PlayState.instance.camOther;
		camHUD = PlayState.instance.camHUD;

		Conductor.songPosition = 0;
		Conductor.bpm = 100;

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

	var startedDeath:Bool = false;
	var isFollowingAlready:Bool = false;
	override function update(elapsed:Float) {
		PlayState.instance.cleanupLuas();
		super.update(elapsed);

		PlayState.instance.callOnScripts('onUpdate', [elapsed]);

		if (controls.ACCEPT) endBullshit();

		if (controls.BACK) {
			#if desktop Discord.resetClientID(); #end
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			PlayState.chartingMode = false;

			Mods.loadTopMod();
			if (PlayState.isStoryMode) MusicBeatState.switchState(new StoryMenuState());
			else MusicBeatState.switchState(new FreeplayState());

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.instance.callOnScripts('onGameOverConfirm', [false]);
		}

		if (boyfriend.animation.curAnim != null) {
			if (boyfriend.animation.curAnim.name == 'firstDeath' && boyfriend.animation.curAnim.finished && startedDeath)
				boyfriend.playAnim('deathLoop');

			if(boyfriend.animation.curAnim.name == 'firstDeath') {
				if(boyfriend.animation.curAnim.curFrame >= 12 && !isFollowingAlready) {
					FlxG.camera.follow(camFollow, LOCKON, 0);
					updateCamera = true;
					isFollowingAlready = true;
				}

				if (boyfriend.animation.curAnim.finished) {
					startedDeath = true;
					coolStartDeath();
				}
			}
		}

		if(updateCamera) FlxG.camera.followLerp = FlxMath.bound(elapsed * 0.6 / (FlxG.updateFramerate / 60), 0, 1);
		else FlxG.camera.followLerp = 0;

		if (FlxG.sound.music.playing)
			Conductor.songPosition = FlxG.sound.music.time;
		PlayState.instance.callOnScripts('onUpdatePost', [elapsed]);
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

		var snd:FlxSound = FlxG.sound.play(Paths.sound(endSoundName));
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

		PlayState.instance.callOnScripts('onGameOverConfirm', [true]);
	}

	function getBoyfriend(x:Float, y:Float):Character {
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

		return new Character(x, y, characterName, true);
	}
}
