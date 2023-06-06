package states.stages;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;

import game.Note.EventNote;
import game.Character;

enum Countdown {
	THREE;
	TWO;
	ONE;
	GO;
	START;
}

class BaseStage extends FlxBasic
{
	var game(default, set):Dynamic = PlayState.instance;
	var lowQuality(default, null):Bool = ClientPrefs.getPref('lowQuality');
	var antialiasing(default, null):Bool = ClientPrefs.getPref('Antialiasing');

	public var onPlayState:Bool = false;

	// some variables for convenience
	public var paused(get, never):Bool;
	public var songName(get, never):String;
	public var isStoryMode(get, never):Bool;
	public var seenCutscene(get, never):Bool;
	public var inCutscene(get, set):Bool;
	public var canPause(get, set):Bool;
	public var members(get, never):Dynamic;

	public var boyfriend(get, never):Character;
	public var dad(get, never):Character;
	public var gf(get, never):Character;
	public var boyfriendGroup(get, never):FlxSpriteGroup;
	public var dadGroup(get, never):FlxSpriteGroup;
	public var gfGroup(get, never):FlxSpriteGroup;

	public var camGame(get, never):FlxCamera;
	public var camHUD(get, never):FlxCamera;
	public var camOther(get, never):FlxCamera;

	public var defaultCamZoom(get, set):Float;
	public var camFollow(get, never):FlxObject;

	public function new() {
		this.game = cast FlxG.state;

		if(this.game == null) {
			FlxG.log.warn('Invalid state for the stage added!');
			destroy();
		} else {
			this.game.stages.push(this);
			super();
			create();
		}
	}

	//main callbacks
	public function create() {}
	public function createPost() {}
	public function countdownTick(count:Countdown, num:Int) {}

	// FNF steps, beats and sections
	public var curBeat:Int = 0;
	public var curDecBeat:Float = 0;
	public var curStep:Int = 0;
	public var curDecStep:Float = 0;
	public var curSection:Int = 0;
	public function beatHit() {}
	public function stepHit() {}
	public function sectionHit() {}

	// Substate close/open, for pausing Tweens/Timers
	public function closeSubState() {}
	public function openSubState(SubState:FlxSubState) {}

	// Events
	public function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float) {}
	public function eventPushed(event:EventNote) {}

	// Things to replace FlxGroup stuff and inject sprites directly into the state
	function add(object:FlxBasic) game.add(object);
	function remove(object:FlxBasic) game.remove(object);
	function insert(position:Int, object:FlxBasic) game.insert(position, object);

	public function addBehindGF(obj:FlxBasic) insert(members.indexOf(game.gfGroup), obj);
	public function addBehindBF(obj:FlxBasic) insert(members.indexOf(game.boyfriendGroup), obj);
	public function addBehindDad(obj:FlxBasic) insert(members.indexOf(game.dadGroup), obj);
	public function setDefaultGF(name:String) { //Fix for the Chart Editor on Base Game stages
		var gfVersion:String = PlayState.SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1) {
			gfVersion = name;
			PlayState.SONG.gfVersion = gfVersion;
		}
	}

	//start/end callback functions
	public function setStartCallback(myfn:Void->Void) {
		if(!onPlayState) return;
		PlayState.instance.startCallback = myfn;
	}
	public function setEndCallback(myfn:Void->Void) {
		if(!onPlayState) return;
		PlayState.instance.endCallback = myfn;
	}

	//precache functions
	public function precacheImage(key:String) precache(key, 'image');
	public function precacheSound(key:String) precache(key, 'sound');
	public function precacheMusic(key:String) precache(key, 'music');

	public function precache(key:String, type:String) {
		if(onPlayState)
			PlayState.instance.precacheList.set(key, type);
		else {
			switch(type) {
				case 'image': Paths.image(key);
				case 'sound': Paths.sound(key);
				case 'music': Paths.music(key);
			}
		}
	}

	// overrides
	function startCountdown() if(onPlayState) return PlayState.instance.startCountdown(); else return false;
	function endSong() if(onPlayState)return PlayState.instance.endSong(); else return false;
	function moveCameraSection() if(onPlayState) moveCameraSection();
	function moveCamera(isDad:Bool) if(onPlayState) moveCamera(isDad);
	inline function get_paused() return game.paused;
	inline function get_songName() return game.songName;
	inline function get_isStoryMode() return PlayState.isStoryMode;
	inline function get_seenCutscene() return PlayState.seenCutscene;
	inline function get_inCutscene() return game.inCutscene;
	inline function set_inCutscene(value:Bool) {
		game.inCutscene = value;
		return value;
	}
	inline function get_canPause() return game.canPause;
	inline function set_canPause(value:Bool) {
		game.canPause = value;
		return value;
	}
	inline function get_members() return game.members;
	inline function set_game(value:MusicBeatState) {
		onPlayState = (Std.isOfType(value, states.PlayState));
		game = value;
		return value;
	}

	inline function get_boyfriend():Character return game.boyfriend;
	inline function get_dad():Character return game.dad;
	inline function get_gf():Character return game.gf;

	inline function get_boyfriendGroup():FlxSpriteGroup return game.boyfriendGroup;
	inline function get_dadGroup():FlxSpriteGroup return game.dadGroup;
	inline function get_gfGroup():FlxSpriteGroup return game.gfGroup;

	inline function get_camGame():FlxCamera return game.camGame;
	inline function get_camHUD():FlxCamera return game.camHUD;
	inline function get_camOther():FlxCamera return game.camOther;

	inline function get_defaultCamZoom():Float return game.defaultCamZoom;
	inline function set_defaultCamZoom(value:Float):Float {
		game.defaultCamZoom = value;
		return game.defaultCamZoom;
	}
	inline function get_camFollow():FlxObject return game.camFollow;
}