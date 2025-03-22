package backend;

import options.GameplaySettingsSubState;
class MusicBeatState extends flixel.FlxState {
	static var currentState:MusicBeatState;
	var curSection:Int = 0;
	var stepsToDo:Int = 0;

	var oldStep:Int = 0;
	var varStep:Int = 0;
	var curStep:Int = 0;
	var curBeat:Int = 0;

	var curStepLimit:Int = 0;
	var updateCount:Int = 0;

	var curDecStep:Float = 0;
	var curDecBeat:Float = 0;

	var _psychCameraInitialized:Bool = false;

	public static var skipNextTransIn:Bool = false;
	public static var skipNextTransOut:Bool = false;

	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static function getVariables():Map<String, Dynamic> return getState().variables;
	
	var maxBPM:Float = 0;
	override function create() {
		currentState = this;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		if (!_psychCameraInitialized) initPsychCamera();
		super.create();

		curStepLimit = Settings.data.updateStepLimit;
		if (curStepLimit > 0) maxBPM = curStepLimit * GameplaySettingsSubState.defaultBPM * Settings.data.framerate;
		else maxBPM = Math.POSITIVE_INFINITY;

		if (!skipNextTransOut) openSubState(new CustomFadeTransition(.5, true));
		skipNextTransOut = false;
	}

	override function destroy() {
		if (!Settings.data.disableGC) utils.system.MemoryUtil.clearMajor();
		super.destroy();
	}

	public function initPsychCamera():PsychCamera {
		var camera:PsychCamera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		return camera;
	}

	var countJudge:Bool = false;
	override function update(elapsed:Float) {
		updateCount = 0;

		oldStep = curStep;
		varStep = oldStep + 1;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep) {
			if (curStep > 0) stepHit();

			if (PlayState.SONG != null) {
				if (oldStep < curStep) updateSection();
				else rollbackSection();
			}
		}
		stagesFunc((stage:BaseStage) -> stage.update(elapsed));
		super.update(elapsed);
	}

	function updateSection():Void {
		if (stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo) {
			curSection++;
			stepsToDo += Math.round(getBeatsOnSection() * 4);
			sectionHit();
		}
	}

	function rollbackSection():Void {
		if (curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length) {
			if (PlayState.SONG.notes[i] != null) {
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep) break;
				curSection++;
			}
		}

		if (curSection > lastSection) sectionHit();
	}

	function updateBeat():Void {
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	function updateCurStep():Void {
		var lastChange:Conductor.BPMChangeEvent = Conductor.getBPMChangeFromMS(Conductor.songPosition);

		var delayToFix:Float = ((Conductor.songPosition - Settings.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + delayToFix;
		curStep = lastChange.stepTime + Math.floor(delayToFix);
	}

	override function startOutro(onOutroComplete:()->Void):Void {
		if (!skipNextTransIn) {
			FlxG.state.openSubState(new CustomFadeTransition(.5, false));
			CustomFadeTransition.finishCallback = onOutroComplete;
			return;
		}

		skipNextTransIn = false;
		onOutroComplete();
	}

	public static function getState():MusicBeatState {
		if (Std.isOfType(FlxG.state, MusicBeatState)) return cast(FlxG.state, MusicBeatState);
		else return currentState;
	}
	
	public var stages:Array<BaseStage> = [];

	public function stepHit():Void {
		var nextStep:Float = curStep + 1;
		if (curStepLimit > 0) maxBPM = curStepLimit * GameplaySettingsSubState.defaultBPM * Settings.data.framerate;
		else maxBPM = Math.POSITIVE_INFINITY;

		if (Conductor.bpm <= maxBPM) {
			countJudge = (curStepLimit != 0 ? varStep < nextStep && updateCount < curStepLimit : varStep < nextStep);

			while (countJudge) {
				stagesFunc((stage:BaseStage) -> {
					stage.curStep = varStep;
					stage.curDecStep = curDecStep;
					stage.stepHit();
				});

				if (varStep % 4 == 0) beatHit();
				++varStep; ++updateCount;
				countJudge = (curStepLimit != 0 ? varStep < nextStep && updateCount < curStepLimit : varStep < nextStep);
			}
		} else {				
			stagesFunc((stage:BaseStage) -> {
				stage.curStep = varStep;
				stage.curDecStep = curDecStep;
				stage.stepHit();
			});

			if (curStep % 4 == 0) beatHit();
			updateCount = curStepLimit;
		}
	}
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
		for (stage in stages) {
			if (stage == null || !stage.exists || !stage.active) continue;
			func(stage);
		}
	}

	function getBeatsOnSection():Int {
		var val:Null<Int> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null)
			val = PlayState.SONG.notes[curSection].sectionBeats;
		return val ?? 4;
	}
}