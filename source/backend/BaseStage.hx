package backend;

import flixel.FlxBasic;
import flixel.FlxObject;

import objects.Note.EventNote;
import objects.Character;

enum Countdown {
	THREE;
	TWO;
	ONE;
	GO;
	START;
}

class BaseStage extends FlxBasic {
	var game(get, never):Dynamic;
	var lowQuality(default, null):Bool = ClientPrefs.data.lowQuality;
	var antialiasing(default, null):Bool = ClientPrefs.data.antialiasing;

	public var onPlayState(get, never):Bool;

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
		if(game == null) {
			FlxG.log.error('Invalid state for the stage added!');
			destroy();
		} else {
			game.stages.push(this);
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
	public function openSubState(SubState:flixel.FlxSubState) {}

	// Events
	public function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float) {}
	public function eventPushed(event:EventNote) {}
	public function eventPushedUnique(event:EventNote) {}

	// Things to replace FlxGroup stuff and inject sprites directly into the state
	function add(object:FlxBasic) return FlxG.state.add(object);
	function remove(object:FlxBasic) return FlxG.state.remove(object);
	function insert(position:Int, object:FlxBasic) return FlxG.state.insert(position, object);

	public function addBehindGF(obj:FlxBasic) return insert(members.indexOf(game.gfGroup), obj);
	public function addBehindBF(obj:FlxBasic) return insert(members.indexOf(game.boyfriendGroup), obj);
	public function addBehindDad(obj:FlxBasic) return insert(members.indexOf(game.dadGroup), obj);
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

	// overrides
	function startCountdown() if(onPlayState) return PlayState.instance.startCountdown(); else return false;
	function endSong() if(onPlayState) return PlayState.instance.endSong(); else return false;
	function moveCameraSection() if(onPlayState) PlayState.instance.moveCameraSection();
	function moveCamera(isDad:Bool) if(onPlayState) PlayState.instance.moveCamera(isDad);
	inline function get_paused() return game.paused;
	inline function get_songName() return game.songName;
	inline function get_isStoryMode() return PlayState.isStoryMode;
	inline function get_seenCutscene() return PlayState.seenCutscene;
	inline function get_inCutscene() return game.inCutscene;
	inline function set_inCutscene(value:Bool) return game.inCutscene = value;
	inline function get_canPause() return game.canPause;
	inline function set_canPause(value:Bool) return game.canPause = value;
	inline function get_members() return game.members;

	inline function get_game() return cast FlxG.state;
	inline function get_onPlayState() return (Std.isOfType(FlxG.state, states.PlayState));

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
	inline function set_defaultCamZoom(value:Float):Float return game.defaultCamZoom = value;
	inline function get_camFollow():FlxObject return game.camFollow;
}