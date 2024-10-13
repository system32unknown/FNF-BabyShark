package modcharting;

import flixel.util.FlxTimer.FlxTimerManager;
import openfl.geom.Vector3D;
import modcharting.Modifier;
import managers.TweenManager;
import objects.Note;
import objects.StrumNote;

typedef StrumNoteType = StrumNote;

class PlayfieldRenderer extends FlxSprite { // extending flxsprite just so i can edit draw
	public var strumGroup:FlxTypedGroup<StrumNoteType>;
	public var notes:FlxTypedGroup<Note>;
	public var instance:ModchartMusicBeatState;
	public var playStateInstance:PlayState;
	public var playfields:Array<Playfield> = []; // adding an extra playfield will add 1 for each player

	public var eventManager:ModchartEventManager;
	public var modifierTable:ModTable;
	public var tweenManager:TweenManager = null;
	public var timerManager:FlxTimerManager = null;

	public var modchart:ModchartFile;
	public var inEditor:Bool = false;
	public var editorPaused:Bool = false;

	public var speed:Float = 1.0;

	public var modifiers(get, default):Map<String, Modifier>;

	function get_modifiers():Map<String, Modifier> {
		return modifierTable.modifiers; // back compat with lua modcharts
	}

	public function new(strumGroup:FlxTypedGroup<StrumNoteType>, notes:FlxTypedGroup<Note>, instance:ModchartMusicBeatState) {
		super();
		this.strumGroup = strumGroup;
		this.notes = notes;
		this.instance = instance;
		if (Std.isOfType(instance, PlayState)) playStateInstance = cast instance; // so it just casts once

		strumGroup.visible = false; // drawing with renderer instead
		notes.visible = false;

		// fix stupid crash because the renderer in playstate is still technically null at this point and its needed for json loading
		instance.playfieldRenderer = this;

		tweenManager = new TweenManager();
		timerManager = new FlxTimerManager();
		eventManager = new ModchartEventManager(this);
		modifierTable = new ModTable(instance, this);
		addNewPlayfield();
		modchart = new ModchartFile(this);
	}

	public function addNewPlayfield(?x:Float = 0, ?y:Float = 0, ?z:Float = 0, ?alpha:Float = 1) {
		playfields.push(new Playfield(x, y, z, alpha));
	}

	override function update(elapsed:Float) {
		try {
			eventManager.update(elapsed);
			tweenManager.update(elapsed); // should be automatically paused when you pause in game
			timerManager.update(elapsed);
		} catch (e:Dynamic) Logs.trace(e, ERROR);
		super.update(elapsed);
	}

	override public function draw() {
		if (alpha == 0 || !visible) return;

		strumGroup.cameras = this.cameras;
		notes.cameras = this.cameras;

		try {
			drawStuff(getNotePositions()); // draw notes to screen
		} catch (e:Dynamic) Logs.trace(e, ERROR);
	}

	function addDataToStrum(strumData:NotePositionData, strum:StrumNoteType) {
		strum.x = strumData.x;
		strum.y = strumData.y;

		strum.angle = strumData.angle;
		strum.alpha = strumData.alpha;
		strum.scale.x = strumData.scaleX;
		strum.scale.y = strumData.scaleY;
		strum.skew.x = strumData.skewX;
		strum.skew.y = strumData.skewY;
	}

	function getDataForStrum(i:Int, pf:Int):NotePositionData {
		var strumX:Float = NoteMovement.defaultStrumX[i];
		var strumY:Float = NoteMovement.defaultStrumY[i];
		var strumZ:Float = 0;
		var strumScaleX:Float = NoteMovement.defaultScale[i];
		var strumScaleY:Float = NoteMovement.defaultScale[i];
		var strumSkewX:Float = NoteMovement.defaultSkewX[i];
		var strumSkewY:Float = NoteMovement.defaultSkewY[i];
		if (ModchartUtil.getIsPixelStage(instance)) { // work on pixel stages
			strumScaleX = 1 * PlayState.daPixelZoom;
			strumScaleY = 1 * PlayState.daPixelZoom;
		}
		var strumData:NotePositionData = NotePositionData.get();
		strumData.setupStrum(strumX, strumY, strumZ, i, strumScaleX, strumScaleY, strumSkewX, strumSkewY, pf);
		playfields[pf].applyOffsets(strumData);
		modifierTable.applyStrumMods(strumData, i, pf);
		return strumData;
	}

	function addDataToNote(noteData:NotePositionData, daNote:Note) {
		daNote.x = noteData.x;
		daNote.y = noteData.y;
		daNote.z = noteData.z;
		daNote.angle = noteData.angle;
		daNote.alpha = noteData.alpha;
		daNote.scale.x = noteData.scaleX;
		daNote.scale.y = noteData.scaleY;
		daNote.skew.x = noteData.skewX;
		daNote.skew.y = noteData.skewY;
	}

	function createDataFromNote(noteIndex:Int, playfieldIndex:Int, curPos:Float, noteDist:Float, incomingAngle:Array<Float>):NotePositionData {
		var noteX:Float = notes.members[noteIndex].x;
		var noteY:Float = notes.members[noteIndex].y;
		var noteZ:Float = notes.members[noteIndex].z;
		var lane:Int = getLane(noteIndex);
		var noteScaleX:Float = NoteMovement.defaultScale[lane];
		var noteScaleY:Float = NoteMovement.defaultScale[lane];
		var noteSkewX:Float = notes.members[noteIndex].skew.x;
		var noteSkewY:Float = notes.members[noteIndex].skew.y;

		var noteAlpha:Float = notes.members[noteIndex].multAlpha;

		if (ModchartUtil.getIsPixelStage(instance)) {
			// work on pixel stages
			noteScaleX = 1 * PlayState.daPixelZoom;
			noteScaleY = 1 * PlayState.daPixelZoom;
		}

		var noteData:NotePositionData = NotePositionData.get();
		noteData.setupNote(noteX, noteY, noteZ, lane, noteScaleX, noteScaleY, noteSkewX, noteSkewY, playfieldIndex, noteAlpha, curPos, noteDist, incomingAngle[0], incomingAngle[1], notes.members[noteIndex].strumTime, noteIndex);
		playfields[playfieldIndex].applyOffsets(noteData);
		return noteData;
	}

	function getNoteCurPos(noteIndex:Int, strumTimeOffset:Float = 0):Float {
		if (notes.members[noteIndex].isSustainNote && ModchartUtil.getDownscroll(instance))
			strumTimeOffset -= Std.int(Conductor.stepCrochet / getCorrectScrollSpeed()); // psych does this to fix its sustains but that breaks the visuals so basically reverse it back to normal
		var distance:Float = (Conductor.songPosition - notes.members[noteIndex].strumTime) + strumTimeOffset;
		return distance * getCorrectScrollSpeed();
	}

	function getLane(noteIndex:Int):Int {
		return (notes.members[noteIndex].mustPress ? notes.members[noteIndex].noteData + NoteMovement.keyCount : notes.members[noteIndex].noteData);
	}

	function getNoteDist(noteIndex:Int):Float {
		var noteDist:Float = -.45;
		if (ModchartUtil.getDownscroll(instance)) noteDist *= -1;
		return noteDist;
	}

	function getNotePositions():Array<NotePositionData> {
		var notePositions:Array<NotePositionData> = [];
		for (pf in 0...playfields.length) {
			for (i in 0...strumGroup.members.length) notePositions.push(getDataForStrum(i, pf));
			for (i in 0...notes.members.length) {
				var songSpeed:Float = getCorrectScrollSpeed();
				var lane:Int = getLane(i);

				var noteDist:Float = getNoteDist(i);
				noteDist = modifierTable.applyNoteDistMods(noteDist, lane, pf);

				var curPos:Float = getNoteCurPos(i);
				curPos = modifierTable.applyCurPosMods(lane, curPos, pf);

				if ((notes.members[i].wasGoodHit || (notes.members[i].prevNote.wasGoodHit)) && curPos >= 0 && notes.members[i].isSustainNote)
					curPos = 0; // sustain clip

				var incomingAngle:Array<Float> = modifierTable.applyIncomingAngleMods(lane, curPos, pf);
				if (noteDist < 0) incomingAngle[0] += 180; // make it match for both scrolls

				// get the general note path
				NoteMovement.setNotePath(notes.members[i], lane, songSpeed, curPos, noteDist, incomingAngle[0], incomingAngle[1]);
				var noteData:NotePositionData = createDataFromNote(i, pf, curPos, noteDist, incomingAngle); // save the position data
				modifierTable.applyNoteMods(noteData, lane, curPos, pf); // add offsets to data with modifiers
				notePositions.push(noteData); // add position data to list
			}
		}
		// sort by z before drawing
		notePositions.sort((a:NotePositionData, b:NotePositionData) -> {
			if (a.z < b.z) return -1;
			else if (a.z > b.z) return 1;
			else return 0;
		});
		return notePositions;
	}

	function drawStrum(noteData:NotePositionData) {
		if (noteData.alpha <= 0) return;

		var changeX:Bool = ((noteData.z > 0 || noteData.z < 0) && noteData.z != 0);
		var strumNote:StrumNoteType = strumGroup.members[noteData.index];
		var thisNotePos:Vector3D = changeX ? ModchartUtil.calculatePerspective(new Vector3D(noteData.x + (strumNote.width / 2), noteData.y + (strumNote.height / 2), noteData.z * 0.001), ModchartUtil.defaultFOV * (Math.PI / 180), -(strumNote.width / 2), -(strumNote.height / 2)) : new Vector3D(noteData.x, noteData.y, 0);

		noteData.x = thisNotePos.x;
		noteData.y = thisNotePos.y;
		if (changeX) {
			noteData.scaleX *= (1 / -thisNotePos.z);
			noteData.scaleY *= (1 / -thisNotePos.z);
		}

		addDataToStrum(noteData, strumGroup.members[noteData.index]); // set position and stuff before drawing
		strumGroup.members[noteData.index].cameras = this.cameras;
		strumGroup.members[noteData.index].draw();
	}

	function drawNote(noteData:NotePositionData) {
		if (noteData.alpha <= 0) return;

		var changeX:Bool = ((noteData.z > 0 || noteData.z < 0) && noteData.z != 0);
		var daNote:Note = notes.members[noteData.index];
		var thisNotePos:Vector3D = changeX ? ModchartUtil.calculatePerspective(new Vector3D(noteData.x + (daNote.width / 2) + ModchartUtil.getNoteOffsetX(daNote, instance), noteData.y + (daNote.height / 2), noteData.z * .001), ModchartUtil.defaultFOV * (Math.PI / 180), -(daNote.width / 2), -(daNote.height / 2)) : new Vector3D(noteData.x, noteData.y, 0);

		noteData.x = thisNotePos.x;
		noteData.y = thisNotePos.y;
		if (changeX) {
			noteData.scaleX *= (1 / -thisNotePos.z);
			noteData.scaleY *= (1 / -thisNotePos.z);
		}

		// set note position using the position data
		addDataToNote(noteData, notes.members[noteData.index]);
		notes.members[noteData.index].cameras = this.cameras; // make sure it draws on the correct camera
		notes.members[noteData.index].draw(); // draw it
	}

	function drawSustainNote(noteData:NotePositionData) {
		if (noteData.alpha <= 0) return;
		var daNote:Note = notes.members[noteData.index];
		if (daNote.mesh == null) daNote.mesh = new SustainStrip(daNote);

		daNote.mesh.scrollFactor.x = daNote.scrollFactor.x;
		daNote.mesh.scrollFactor.y = daNote.scrollFactor.y;
		daNote.alpha = noteData.alpha;
		daNote.mesh.alpha = daNote.alpha;

		var songSpeed:Float = getCorrectScrollSpeed();
		var lane:Int = noteData.lane;

		// makes the sustain match the center of the parent note when at weird angles
		var yOffsetThingy:Float = (NoteMovement.arrowSizes[lane] / 2);
		var thisNotePos:Vector3D = ModchartUtil.calculatePerspective(new Vector3D(noteData.x + (daNote.width / 2) + ModchartUtil.getNoteOffsetX(daNote, instance), noteData.y + (NoteMovement.arrowSizes[noteData.lane] / 2), noteData.z * 0.001), ModchartUtil.defaultFOV * (Math.PI / 180), -(daNote.width / 2), yOffsetThingy - (NoteMovement.arrowSizes[noteData.lane] / 2));

		var timeToNextSustain:Float = ModchartUtil.getFakeCrochet() / 4;
		if (noteData.noteDist < 0) timeToNextSustain *= -1; // weird shit that fixes upscroll lol

		var nextHalfNotePos = getSustainPoint(noteData, timeToNextSustain * 0.5);
		var nextNotePos = getSustainPoint(noteData, timeToNextSustain);

		var flipGraphic:Bool = false;

		// mod/bound to 360, add 360 for negative angles, mod again just in case
		var fixedAngY:Float = ((noteData.incomingAngleY % 360) + 360) % 360;
		var reverseClip:Bool = (fixedAngY > 90 && fixedAngY < 270);

		if (noteData.noteDist > 0) // downscroll
			if (!ModchartUtil.getDownscroll(instance)) flipGraphic = true; // fix reverse
		else if (ModchartUtil.getDownscroll(instance)) flipGraphic = true;
		// render that shit
		daNote.mesh.constructVertices(noteData, thisNotePos, nextHalfNotePos, nextNotePos, flipGraphic, reverseClip);
		daNote.mesh.cameras = this.cameras;
		daNote.mesh.draw();
	}

	function drawStuff(notePositions:Array<NotePositionData>) {
		for (noteData in notePositions) {
			if (noteData.isStrum) drawStrum(noteData); // draw strum
			else if (!notes.members[noteData.index].isSustainNote) drawNote(noteData); // draw regular note
			else drawSustainNote(noteData);
		}
	}

	function getSustainPoint(noteData:NotePositionData, timeOffset:Float):NotePositionData {
		var daNote:Note = notes.members[noteData.index];
		var songSpeed:Float = getCorrectScrollSpeed();
		var lane:Int = noteData.lane;
		var pf:Int = noteData.playfieldIndex;

		var noteDist:Float = getNoteDist(noteData.index);
		var curPos:Float = getNoteCurPos(noteData.index, timeOffset);

		curPos = modifierTable.applyCurPosMods(lane, curPos, pf);

		if ((daNote.wasGoodHit || (daNote.prevNote.wasGoodHit)) && curPos >= 0) curPos = 0;
		noteDist = modifierTable.applyNoteDistMods(noteDist, lane, pf);
		var incomingAngle:Array<Float> = modifierTable.applyIncomingAngleMods(lane, curPos, pf);
		if (noteDist < 0) incomingAngle[0] += 180; // make it match for both scrolls

		NoteMovement.setNotePath(daNote, lane, songSpeed, curPos, noteDist, incomingAngle[0], incomingAngle[1]); // get the general note path for the next note
		var noteData:NotePositionData = createDataFromNote(noteData.index, pf, curPos, noteDist, incomingAngle); // save the position data
		modifierTable.applyNoteMods(noteData, lane, curPos, pf); // add offsets to data with modifiers
		var yOffsetThingy:Float = (NoteMovement.arrowSizes[lane] / 2);
		var finalNotePos:Vector3D = ModchartUtil.calculatePerspective(new Vector3D(noteData.x + (daNote.width / 2) + ModchartUtil.getNoteOffsetX(daNote, instance), noteData.y + (NoteMovement.arrowSizes[noteData.lane] / 2), noteData.z * 0.001), ModchartUtil.defaultFOV * (Math.PI / 180), -(daNote.width / 2), yOffsetThingy - (NoteMovement.arrowSizes[noteData.lane] / 2));

		noteData.x = finalNotePos.x;
		noteData.y = finalNotePos.y;
		noteData.z = finalNotePos.z;

		return noteData;
	}

	public function getCorrectScrollSpeed():Float {
		if (inEditor) return PlayState.SONG.speed; // just use this while in editor so the instance shit works
		else return ModchartUtil.getScrollSpeed(playStateInstance);
		return 1.0;
	}

	public function createTween(Object:Dynamic, Values:Dynamic, Duration:Float, ?Options:TweenOptions):FlxTween {
		var tween:FlxTween = tweenManager.tween(Object, Values, Duration, Options);
		tween.manager = tweenManager;
		return tween;
	}

	public function createTweenNum(FromValue:Float, ToValue:Float, Duration:Float = 1, ?Options:TweenOptions, ?TweenFunction:Float->Void):FlxTween {
		var tween:FlxTween = tweenManager.num(FromValue, ToValue, Duration, Options, TweenFunction);
		tween.manager = tweenManager;
		return tween;
	}

	public function createBezierPathTween(Object:Dynamic, Values:Dynamic, Duration:Float, ?Options:TweenOptions):FlxTween {
		var tween:FlxTween = tweenManager.bezierPathTween(Object, Values, Duration, Options);
		tween.manager = tweenManager;
		return tween;
	}

	public function createBezierPathNumTween(Points:Array<Float>, Duration:Float, ?Options:TweenOptions, ?TweenFunction:Float->Void):FlxTween {
		var tween:FlxTween = tweenManager.bezierPathNumTween(Points, Duration, Options, TweenFunction);
		tween.manager = tweenManager;
		return tween;
	}

	override public function destroy() {
		if (modchart != null) {
			#if hscript
			for (customMod in modchart.customModifiers) {
				customMod.destroy(); // make sure the interps are dead
			}
			#end
		}
		super.destroy();
	}
}
