package backend;

import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxState;

class MusicBeatState extends flixel.addons.ui.FlxUIState {
	public var curBPMChange:BPMChangeEvent;

	var passedSections:Array<Float> = [];
	var stepsToDo:Float = 0;

	var curSection:Int = 0;
	var prevSection:Int = 0;

	var curDecStep:Float = 0;
	var curStep:Int = 0;
	var prevStep:Int = 0;

	var curDecBeat:Float = 0;
	var curBeat:Int = 0;

	public var controls(get, never):Controls;

	var stateClass:Class<MusicBeatState>;
	var isPlayState:Bool;

	static var previousStateClass:Class<FlxState>;
	var _psychCameraInitialized:Bool = false;

	function get_controls():Controls return Controls.instance;

	public function new() {
		isPlayState = (stateClass = Type.getClass(this)) == PlayState;
		curBPMChange = Conductor.getDummyBPMChange();
		super();
	}

	var updatedMusicBeat:Bool = false;
	public function updateMusicBeat() {
		prevStep = curStep;

		updateCurStep();
		updateBeat();

		updatedMusicBeat = true;
	}

	override function create() {
		if (curBPMChange != null && curBPMChange.bpm != Conductor.bpm) curBPMChange = Conductor.getDummyBPMChange();
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		if(!_psychCameraInitialized) initPsychCamera();

		super.create();

		if (!skip) openSubState(new CustomFadeTransition(.6, true));
		FlxTransitionableState.skipNextTransOut = false;
	}

	override function destroy() {
		previousStateClass = cast stateClass;
		persistentUpdate = false;
		passedSections = null;
		utils.system.MemoryUtil.clearMajor();
		super.destroy();
	}

	public function initPsychCamera():PsychCamera {
		var camera:PsychCamera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		return camera;
	}

	override function update(elapsed:Float) {
		if (!updatedMusicBeat) updateMusicBeat();
		if (prevStep != curStep) {
			if (curStep > 0 || !isPlayState) stepHit();
			if (passedSections == null) passedSections = [];
			if (curStep > prevStep) updateSection();
			else rollbackSection();
		}
		updatedMusicBeat = false;

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;
		stagesFunc((stage:BaseStage) -> stage.update(elapsed));

		super.update(elapsed);
	}

	function updateSection():Void {
		if (stepsToDo <= 0) {
			curSection = 0;
			stepsToDo = getBeatsOnSection() * 4;
			passedSections = [];
		}

		while(curStep >= stepsToDo) {
			passedSections.push(stepsToDo);
			stepsToDo = stepsToDo + getBeatsOnSection() * 4;

			prevSection = curSection;
			curSection = passedSections.length;
			sectionHit();
		}
	}

	function rollbackSection():Void {
		if (curStep <= 0) {
			stepsToDo = 0;
			if (curBeat < 1) sectionHit();
			return updateSection();
		}

		var lastSection:Int = prevSection = curSection;
		while((curSection = passedSections.length) > 0 && curStep < passedSections[curSection - 1])
			stepsToDo = passedSections.pop();

		if (curSection > lastSection) sectionHit();
	}

	function updateBeat():Void {
		curDecBeat = curDecStep / 4;
		curBeat = Math.floor(curDecBeat);
	}

	function updateCurStep():Void {
		curBPMChange = Conductor.getBPMFromSeconds(Conductor.songPosition, curBPMChange != null ? curBPMChange.id : -1);
		curDecStep = Conductor.getStep(Conductor.songPosition, ClientPrefs.getPref('noteOffset'), curBPMChange.id);
		curStep = Math.floor(curDecStep);
	}

	public function getBeatsOnSection():Float
		return inline Conductor.getSectionBeats(PlayState.SONG, curSection);

	override function startOutro(onOutroComplete:()->Void):Void {
		if (!FlxTransitionableState.skipNextTransIn) {
			FlxG.state.openSubState(new CustomFadeTransition(.6, false));
			CustomFadeTransition.finishCallback = onOutroComplete;
			return;
		}

		FlxTransitionableState.skipNextTransIn = false;
		onOutroComplete();
	}

	public static function getState(?state:FlxState):MusicBeatState return cast(state != null ? state : FlxG.state);
	public static function previousStateIs(state:Class<FlxState>):Bool return previousStateClass == state;
	
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
		for (stage in stages) if(stage != null && stage.exists && stage.active) func(stage);
	}
}
