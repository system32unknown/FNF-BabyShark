package backend;

import flixel.addons.ui.FlxUIState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxState;
import objects.ErrorDisplay;

class MusicBeatState extends FlxUIState {
	var curSection:Int = 0;
	var stepsToDo:Float = 0;

	var curStep:Int = 0;
	var curBeat:Int = 0;

	var curDecStep:Float = 0;
	var curDecBeat:Float = 0;
	public var controls(get, never):Controls;
	function get_controls():Controls return Controls.instance;

	var errorDisplay:ErrorDisplay;
	final missChart:String = 'Error! Chart not found;';
	final missFile:String = 'MISSING FILE AT:';

	public static var camBeat:FlxCamera;

	static function getPathWithDir(songFolder:String, songLowercase:String):String {
		return 'mods/${Mods.currentModDirectory}/data/${Paths.CHART_PATH}/$songFolder/$songLowercase.json';
	}

	public function getErrorMessage(error:String, reason:String, songFolder:String, songLowercase:String):String {
		var formattedSong:String = Song.getSongPath(songFolder, songLowercase);
		var songString:String = Paths.json(Paths.CHART_PATH + "/" + formattedSong);
		var modsSongString:String = Paths.modsJson(Paths.CHART_PATH + "/" + formattedSong);
		var modDirString:String = '';

		if (Mods.currentModDirectory.length < 1)
			return error + '\n$reason\n\'$songString\' or\n\'$modsSongString\'';
		else {
			modDirString = getPathWithDir(songFolder, songLowercase);
			return error + '\n$reason\n\'$songString\',\n\'$modsSongString\' or\n\'$modDirString\'';
		}
	}

	override function create() {
		camBeat = FlxG.camera;
		var skip = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		super.create();

		if (!skip) openSubState(new CustomFadeTransition(.7, true));
		FlxTransitionableState.skipNextTransOut = false;
	}

	override function destroy() {
		utils.system.MemoryUtil.clearMajor();
		super.destroy();
	}

	override function update(elapsed:Float) {
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep) {
			if(curStep > 0) stepHit();

			if(PlayState.SONG != null) {
				if (oldStep < curStep)
					updateSection();
				else rollbackSection();
			}
		}

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;
		stagesFunc((stage:BaseStage) -> stage.update(elapsed));

		super.update(elapsed);
	}

	function updateSection():Void {
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo) {
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	function rollbackSection():Void {
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length) {
			if (PlayState.SONG.notes[i] != null) {
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	function updateBeat():Void {
		curBeat = Math.floor(curDecBeat);
		curDecBeat = curDecStep / 4;
	}

	function updateCurStep():Void {
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.getPref('noteOffset')) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState = null) {
		if(nextState == null) nextState = FlxG.state;
		if(nextState == FlxG.state) {
			resetState();
			return;
		}

		if(FlxTransitionableState.skipNextTransIn) FlxG.switchState(nextState);
		else startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState() {
		if(FlxTransitionableState.skipNextTransIn) FlxG.resetState();
		else startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	// Custom made Trans in
	public static function startTransition(nextState:FlxState = null) {
		if(nextState == null) nextState = FlxG.state;

		FlxG.state.openSubState(new CustomFadeTransition(0.6, false));
		if(nextState == FlxG.state)
			CustomFadeTransition.finishCallback = () -> FlxG.resetState();
		else CustomFadeTransition.finishCallback = () -> FlxG.switchState(nextState);
	}

	public static function getState():MusicBeatState
		return cast (FlxG.state, MusicBeatState);
	
	public function stepHit():Void {
		stagesFunc((stage:BaseStage) -> {
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});

		if (curStep % 4 == 0) beatHit();
	}

	public var stages:Array<BaseStage> = [];
	public function beatHit():Void {
		stagesFunc((stage:BaseStage) -> {
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
	}

	public function sectionHit():Void {
		stagesFunc((stage:BaseStage) -> {
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}

	function stagesFunc(func:BaseStage -> Void) {
		for (stage in stages)
			if(stage != null && stage.exists && stage.active)
				func(stage);
	}

	function getBeatsOnSection() {
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
