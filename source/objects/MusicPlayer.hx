package objects;

import flixel.ui.FlxBar;
import flixel.util.FlxStringUtil;
import states.FreeplayState;

/**
 * Music player used for Freeplay
 */
@:access(states.FreeplayState)
class MusicPlayer extends flixel.group.FlxGroup {
	public var instance:FreeplayState;

	public var playing(get, never):Bool;
	public var paused(get, never):Bool;

	public var playingMusic:Bool = false;
	public var curTime:Float;

	var songBG:FlxSprite;
	var songTxt:FlxText;
	var timeTxt:FlxText;
	var progressBar:FlxBar;
	var playbackBG:FlxSprite;
	var playbackSymbols:Array<FlxText> = [];
	var playbackTxt:FlxText;

	var wasPlaying:Bool;

	var holdPitchTime:Float = 0;
	var playbackRate(default, set):Float = 1;

	public function new(instance:FreeplayState) {
		super();

		this.instance = instance;

		var xPos:Float = FlxG.width * .7;

		songBG = new FlxSprite(xPos - 6).makeGraphic(1, 100, 0xFF000000);
		songBG.alpha = .6;
		add(songBG);

		playbackBG = new FlxSprite(xPos - 6).makeGraphic(1, 100, 0xFF000000);
		playbackBG.alpha = .6;
		add(playbackBG);

		songTxt = new FlxText(FlxG.width * .7, 5, 0, "", 32);
		songTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		add(songTxt);

		timeTxt = new FlxText(xPos, songTxt.y + 60, 0, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		add(timeTxt);

		for (i in 0...2) {
			var text:FlxText = new FlxText();
			text.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, CENTER);
			text.text = '^';
			if (i == 1) text.flipY = true;
			text.visible = false;
			playbackSymbols.push(text);
			add(text);
		}

		progressBar = new FlxBar(timeTxt.x, timeTxt.y + timeTxt.height, LEFT_TO_RIGHT, Std.int(timeTxt.width), 8, null, "", 0, Math.POSITIVE_INFINITY);
		progressBar.createFilledBar(FlxColor.WHITE, FlxColor.BLACK);
		add(progressBar);

		playbackTxt = new FlxText(FlxG.width * 0.6, 20, 0, "", 32);
		playbackTxt.setFormat(Paths.font("vcr.ttf"), 32);
		add(playbackTxt);

		switchPlayMusic();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (!playingMusic) return;

		var songName:String = instance.songs[FreeplayState.curSelected].songName;
		if (playing && !wasPlaying)
			songTxt.text = Language.getPhrase('musicplayer_playing', 'PLAYING: {1}', [songName]);
		else songTxt.text = Language.getPhrase('musicplayer_paused', 'PLAYING: {1} (PAUSED)', [songName]);
		positionSong();

		if (Controls.justPressed('ui_left')) {
			if (playing) wasPlaying = true;

			pauseOrResume();

			curTime = FlxG.sound.music.time - 1000;
			instance.holdTime = 0;

			if (curTime < 0) curTime = 0;

			FlxG.sound.music.time = curTime;
			setVocalsTime(curTime);
		}
		if (Controls.justPressed('ui_right')) {
			if (playing) wasPlaying = true;

			pauseOrResume();

			curTime = FlxG.sound.music.time + 1000;
			instance.holdTime = 0;

			if (curTime > FlxG.sound.music.length)
				curTime = FlxG.sound.music.length;

			FlxG.sound.music.time = curTime;
			setVocalsTime(curTime);
		}

		final leftPressed:Bool = Controls.pressed('ui_left');
		if (leftPressed || Controls.pressed('ui_right')) {
			instance.holdTime += elapsed;
			if (instance.holdTime > .5) curTime += 40000 * elapsed * (leftPressed ? -1 : 1);

			var difference:Float = Math.abs(curTime - FlxG.sound.music.time);
			if (curTime + difference > FlxG.sound.music.length) curTime = FlxG.sound.music.length;
			else if (curTime - difference < 0) curTime = 0;

			FlxG.sound.music.time = curTime;
			setVocalsTime(curTime);
		}

		if (Controls.released('ui_left') || Controls.released('ui_right')) {
			FlxG.sound.music.time = curTime;
			setVocalsTime(curTime);

			if (wasPlaying) {
				pauseOrResume(true);
				wasPlaying = false;
			}
		}

		final upPressed:Bool = Controls.pressed('ui_up');
		final upJustPressed:Bool = Controls.justPressed('ui_up');
		if (upJustPressed || Controls.justPressed('ui_down')) {
			holdPitchTime = 0;
			upJustPressed ? playbackRate += .05 : playbackRate -= .05;
			setPlaybackRate();
		}
		if (Controls.pressed('ui_down') || upPressed) {
			holdPitchTime += elapsed;
			if (holdPitchTime > 0.6) {
				playbackRate += .05 * (upPressed ? 1 : -1);
				setPlaybackRate();
			}
		}
	
		if (Controls.justPressed('reset')) {
			playbackRate = 1;
			setPlaybackRate();

			FlxG.sound.music.time = 0;
			setVocalsTime(0);
		}

		if (playing) {
			if (FreeplayState.vocals != null) FreeplayState.vocals.volume = (FreeplayState.vocals.length > FlxG.sound.music.time) ? .8 : 0;
			if ((FreeplayState.vocals != null && FreeplayState.vocals.length > FlxG.sound.music.time && Math.abs(FlxG.sound.music.time - FreeplayState.vocals.time) >= 25)) {
				pauseOrResume();
				setVocalsTime(FlxG.sound.music.time);
				pauseOrResume(true);
			}
		}

		positionSong();
		updateTimeTxt();
		updatePlaybackTxt();
	}

	function setVocalsTime(time:Float) {
		if (FreeplayState.vocals != null && FreeplayState.vocals.length > time)
			FreeplayState.vocals.time = time;
	}

	public function pauseOrResume(resume:Bool = false) {
		if (resume) {
			FlxG.sound.music.resume();
			if (FreeplayState.vocals != null) FreeplayState.vocals.resume();
		} else {
			FlxG.sound.music.pause();
			if (FreeplayState.vocals != null) FreeplayState.vocals.pause();
		}
		positionSong();
	}

	public function switchPlayMusic() {
		FlxG.autoPause = (!playingMusic && ClientPrefs.data.autoPause);
		active = visible = playingMusic;

		instance.scoreBG.visible = instance.diffText.visible = instance.scoreText.visible = instance.comboText.visible = !playingMusic; //Hide Freeplay texts and boxes if playingMusic is true
		songTxt.visible = timeTxt.visible = songBG.visible = playbackTxt.visible = playbackBG.visible = progressBar.visible = playingMusic; //Show Music Player texts and boxes if playingMusic is true

		for (i in playbackSymbols) i.visible = playingMusic;
		
		holdPitchTime = 0;
		instance.holdTime = 0;
		playbackRate = 1;
		updatePlaybackTxt();

		if (playingMusic) {
			instance.bottomText.text = Language.getPhrase('musicplayer_tip', "[SPACE] Pause • [ESCAPE] Exit • [R] Reset the Song");
			positionSong();
			
			progressBar.setRange(0, FlxG.sound.music.length);
			progressBar.setParent(FlxG.sound.music, "time");
			progressBar.numDivisions = 1600;

			updateTimeTxt();
		} else {
			progressBar.setRange(0, Math.POSITIVE_INFINITY);
			progressBar.setParent(null, "");
			progressBar.numDivisions = 0;

			instance.bottomText.text = instance.bottomString;
			instance.positionHighscore();
		}
		progressBar.updateBar();
	}

	function updatePlaybackTxt() {
		var text:String = "";
		if (playbackRate is Int) text = playbackRate + '.00';
		else {
			var playbackRate:String = Std.string(playbackRate);
			if (playbackRate.split('.')[1].length < 2) playbackRate += '0'; // Playback rates for like 1.1, 1.2 etc
			text = playbackRate;
		}
		playbackTxt.text = text + 'x';
	}

	function positionSong() {
		var length:Int = instance.songs[FreeplayState.curSelected].songName.length;
		var shortName:Bool = length < 5; // Fix for song names like Ugh, Guns
		songTxt.x = FlxG.width - songTxt.width - 6;
		if (shortName) songTxt.x -= 10 * length - length;
		songBG.scale.x = FlxG.width - songTxt.x + 12;
		if (shortName) songBG.scale.x += 6 * length;
		songBG.x = FlxG.width - (songBG.scale.x / 2);
		timeTxt.x = Std.int(songBG.x + (songBG.width / 2));
		timeTxt.x -= timeTxt.width / 2;
		if (shortName) timeTxt.x -= length - 5;

		playbackBG.scale.x = playbackTxt.width + 30;
		playbackBG.x = songBG.x - (songBG.scale.x / 2);
		playbackBG.x -= playbackBG.scale.x;

        playbackTxt.setPosition(playbackBG.x - playbackTxt.width / 2, playbackTxt.height);

		progressBar.setGraphicSize(Std.int(songTxt.width), 5);
        progressBar.setPosition(songTxt.x + songTxt.width / 2 - 15, songTxt.y + songTxt.height + 10);
		if (shortName) {
			progressBar.scale.x += length / 2;
			progressBar.x -= length - 10;
		}

		for (i in 0...2) {
			var text:FlxText = playbackSymbols[i];
            text.setPosition(playbackTxt.x + playbackTxt.width / 2 - 10, playbackTxt.y);

			if (i == 0) text.y -= playbackTxt.height;
			else text.y += playbackTxt.height;
		}
	}

	function updateTimeTxt() {
		timeTxt.text = '< ${FlxStringUtil.formatTime(FlxG.sound.music.time / 1000, false) + ' / ' + FlxStringUtil.formatTime(FlxG.sound.music.length / 1000, false)} >';
	}

	function setPlaybackRate() {
		FlxG.sound.music.pitch = playbackRate;
		if (FreeplayState.vocals != null) FreeplayState.vocals.pitch = playbackRate;
	}

	function get_playing():Bool return FlxG.sound.music.playing;
	function get_paused():Bool @:privateAccess return FlxG.sound.music._paused;

	function set_playbackRate(value:Float):Float {
		var value:Float = FlxMath.roundDecimal(value, 2);
		if (value > 3) value = 3;
		else if (value <= 0.25) value = 0.25;
		return playbackRate = value;
	}
}