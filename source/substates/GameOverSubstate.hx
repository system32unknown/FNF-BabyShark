package substates;

import flixel.FlxObject;
import objects.Character;

class GameOverSubstate extends MusicBeatSubstate {
	public var boyfriend:Character;
	var camFollow:FlxObject;

	public var camOther:FlxCamera;
	public var camHUD:FlxCamera;

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';
	public static var deathDelay:Float = 0;

	public static var instance:GameOverSubstate;

	public static function resetVariables() {
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
		deathDelay = 0;

		var _song:backend.Song.SwagSong = PlayState.SONG;
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
		Paths.music(endSoundName);

		if (PlayState.instance != null) PlayState.instance.gameOverChar = new Character(0, 0, characterName, true);
	}

	override function create() {
		instance = this;
		utils.system.MemoryUtil.clearMajor();

		FlxG.sound.play(Paths.sound(deathSoundName));

		boyfriend = getBoyfriend();
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		boyfriend.skipDance = true;
		add(boyfriend);

		var anim:flixel.animation.FlxAnimation = boyfriend.animation.getByName('firstDeath');
		boyfriend.playAnim('firstDeath');
		if (anim != null) boyfriend.animation.frameIndex = anim.frames[0];

		camOther = PlayState.instance.camOther;
		camHUD = PlayState.instance.camHUD;

		camOther.zoom = camHUD.zoom = 1;
		camOther.x = camOther.y = camOther.angle = camHUD.x = camHUD.y = camHUD.angle = 0;

		Conductor.songPosition = 0;
		Conductor.bpm = 100;

		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend.playAnim('firstDeath');
		boyfriend.animation.onFinish.add((name:String) -> {
			if(name == 'firstDeath') {
				boyfriend.playAnim('deathLoop');
				FlxG.sound.playMusic(Paths.music(loopSoundName));
			}
			boyfriend.animation.onFinish.removeAll();
		});
		camFollow = new FlxObject(0, 0, 1, 1);
		final mid:FlxPoint = boyfriend.getGraphicMidpoint();
		camFollow.setPosition(mid.x + boyfriend.cameraPosition[0], mid.y + boyfriend.cameraPosition[1]);
		mid.put();
		FlxG.camera.focusOn(FlxPoint.get(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2)));
		FlxG.camera.follow(camFollow, LOCKON, 0.01);
		add(camFollow);

		PlayState.instance.setOnScripts('inGameOver', true);
		PlayState.instance.callOnScripts('onGameOverStart');
		FlxG.sound.music.loadEmbedded(Paths.music(loopSoundName), true);

		super.create();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		PlayState.instance.callOnScripts('onUpdate', [elapsed]);

		var justPlayedLoop:Bool = false;
		if (!boyfriend.isAnimationNull() && boyfriend.getAnimationName() == 'firstDeath' && boyfriend.isAnimationFinished()) {
			boyfriend.playAnim('deathLoop');
			justPlayedLoop = true;
		}

		if(!isEnding) {
			if (controls.ACCEPT) endBullshit();
			else if (controls.BACK) {
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
				FlxG.camera.visible = false;
				FlxG.sound.music.stop();
				PlayState.deathCounter = 0;
				PlayState.seenCutscene = false;
				PlayState.chartingMode = false;
	
				Mods.loadTopMod();
				FlxG.switchState(() -> PlayState.isStoryMode ? new states.StoryMenuState() : new states.FreeplayState());
	
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				PlayState.instance.callOnScripts('onGameOverConfirm', [false]);
			}
	
			if (FlxG.sound.music.playing) Conductor.songPosition = FlxG.sound.music.time;
		}

		PlayState.instance.callOnScripts('onUpdatePost', [elapsed]);
	}

	override function destroy() {
		instance = null;
		super.destroy();
	}

	var isEnding:Bool = false;
	function endBullshit():Void {
		if (isEnding) return;

		isEnding = true;
		if(boyfriend.hasAnimation('deathConfirm')) boyfriend.playAnim('deathConfirm', true);
		else if(boyfriend.hasAnimation('deathLoop')) boyfriend.playAnim('deathLoop', true);
		FlxG.sound.music.stop();
		
		var snd:FlxSound = FlxG.sound.play(Paths.music(endSoundName));
		FlxTimer.wait(.7, () -> {
			FlxG.camera.fade(FlxColor.BLACK, 2);
			FlxTimer.wait((snd.length / 1000) - .7, () -> {
				FlxTransitionableState.skipNextTransIn = true;
				FlxG.resetState();
			});
		});

		PlayState.instance.callOnScripts('onGameOverConfirm', [true]);
	}

	function getBoyfriend():Character {
		var ins:PlayState = PlayState.instance;

		final pos:FlxPoint = ins.boyfriend.getScreenPosition();
		var x:Float = pos.x - ins.boyfriend.positionArray[0];
		var y:Float = pos.y - ins.boyfriend.positionArray[1];
		pos.put();

		if (ins != null) {
			var bf:Character = ins.gameOverChar;
			if (bf != null && bf.curCharacter == characterName) {
				bf.setPosition(x, y);
				return bf;
			}
		}

		var bf:Character = ins.boyfriendMap.get(characterName);
		if (bf != null) {
			bf.setPosition(x, y);
			bf.visible = true;
			return bf;
		}

		return new Character(x, y, characterName, true);
	}
}
