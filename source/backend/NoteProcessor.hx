package backend;

import haxe.Timer;
import haxe.ds.IntMap;
import objects.Note;

/**
 * Handles note spawning for note spams in PlayState.
 */
class NoteProcessor {
	var game:PlayState;

	/**
	 * How far ahead (in ms) notes are spawned before their hit time.
	 */
	public var spawnTime:Float = 1500;

	/**
	 * Number of notes successfully hit.
	 */
	public var hit:Int = 0;

	/**
	 * Index of the next unspawned note in the unspawnNotes array.
	 */
	public var totalCnt:Int = 0;

	/**
	 * Number of botplay notes to skip (passed to combo this frame).
	 */
	public var skipBf:Int = 0;

	/**
	 * Rolling window of note hits keyed by song position (ms).
	 */
	var npsWindow:IntMap<Float> = new IntMap<Float>();

	/**
	 * Current notes-per-second value.
	 */
	public var nps:Float = 0;

	/**
	 * Peak notes-per-second reached so far.
	 */
	public var npsMax:Float = 0;

	/**
	 * Accumulated hits on the active side this frame.
	 */
	public var sideHit:Float = 0;

	/**
	 * Whether the note being evaluated is a sustain/hold note.
	 */
	var isHold:Bool = false;

	/**
	 * Whether the note being evaluated belongs to the player. 
	 */
	var isPlayerNote:Bool = false;

	/**
	 * Whether the note is within the visible spawn window.
	 */
	var isVisible:Bool = false;

	/**
	 * Spawn-window duration in milliseconds.
	 */
	var spawnWindowMs:Float = 0;

	/**
	 * Spawn-window duration in seconds (used for timeout checks).
	 */
	var spawnWindowSec:Float = 0;

	/**
	 * Song position adjusted by the player's note offset.
	 */
	var adjustedPosition:Float = 0;

	var _botPlay:Bool = false;
	var _songSpeed:Float = 0.0;

	var _skipThisFrame:Int = 0;

	public function new(ps:PlayState):Void {
		game = ps;
		_botPlay = game.cpuControlled;
		_songSpeed = game.songSpeed;
	}

	/**
	 * Called every game frame. Runs note spawning and note-update logic
	 * in the order determined by the `processFirst` setting.
	 */
	public function update():Void {
		if (!Settings.data.processFirst) {
			noteSpawn();
			noteUpdate();
		} else {
			noteUpdate();
			noteSpawn();
		}

		_skipThisFrame = skipBf;
		if (_skipThisFrame > 0) game.combo += skipBf;
	}

	/**
	 * Updates the NPS rolling window and refreshes `nps` / `npsMax`.
	 * Should be called once per frame after hit detection.
	 */
	public function updateNPS():Void {
		var nowMs:Int = Math.round(Conductor.songPosition);
		if (sideHit > 0) npsWindow.set(nowMs, sideHit);

		for (timestamp => hitCount in npsWindow) {
			if (timestamp + 1000 > nowMs) {
				if (sideHit > 0) {
					nps += sideHit;
					sideHit = 0;
				}
			} else {
				nps -= hitCount;
				npsWindow.remove(timestamp);
			}
		}

		npsMax = Math.max(nps, npsMax);
	}

	/**
	 * Pre-computes spawn-window fields for `target` so the spawn loop
	 * avoids redundant calculations.
	 */
	inline function cacheSpawnInfo(target:Note):Void {
		isHold = target.isSustainNote;
		isPlayerNote = target.mustPress;

		spawnWindowMs = isHold ? Math.max(spawnTime / _songSpeed, Conductor.stepCrochet) : spawnTime / _songSpeed;
		spawnWindowSec = spawnWindowMs / 1000;
		isVisible = target.strumTime - adjustedPosition < spawnWindowMs;
	}

	/**
	 * Iterates through unspawned notes and either adds them to the active
	 * notes group or handles them as missed/skipped notes.
	 */
	function noteSpawn():Void {
		if (game.unspawnNotes.length <= totalCnt) return;

		var frameStart:Float = Timer.stamp();
		var target:Note = game.unspawnNotes[totalCnt];
		adjustedPosition = Conductor.songPosition - Settings.data.noteOffset;
		cacheSpawnInfo(target);

		while (isVisible) {
			var pastHitTime:Bool = adjustedPosition > target.strumTime;
			var tooLate:Bool = adjustedPosition > target.strumTime + game.noteKillOffset;

			var shouldSkip:Bool = isHold ? tooLate : pastHitTime;

			var withinTimeout:Bool = !Settings.data.skipSpawnNote || Timer.stamp() - frameStart < spawnWindowSec;

			if ((!shouldSkip || !Settings.data.optimizeSpawnNote) && withinTimeout) spawnNote(target, pastHitTime);
			else handleSkippedNote(target);

			// Advance to the next unspawned note
			if (game.unspawnNotes.length > ++totalCnt) target = game.unspawnNotes[totalCnt];
			else break;
			cacheSpawnInfo(target);
		}
	}

	/**
	 * Adds a note to the active group and runs optional pre-processing.
	 */
	inline function spawnNote(note:Note, pastHitTime:Bool):Void {
		note.spawned = true;
		note.strum = (note.mustPress ? game.playerStrums : game.opponentStrums).members[note.noteData];

		game.notes.add(note);
		game.callOnHScript('onSpawnNote', [note]);

		if (Settings.data.processFirst) {
			note.followStrumNote(_songSpeed);
			if (pastHitTime && note.isSustainNote && note.strum.sustainReduce) note.clipToStrumNote();
		}
	}

	/**
	 * Handles a note that was skipped (too late or optimised away).
	 */
	inline function handleSkippedNote(note:Note):Void {
		game.strumHitId = (note.noteData + (isPlayerNote ? EK.keys(PlayState.mania) : 0)) & 0xFF;

		if (_botPlay) {
			if (!isHold && isPlayerNote) ++skipBf;
		} else if (isPlayerNote) @:privateAccess game.noteMissCommon(note.noteData);
	}

	/**
	 * Iterates active notes each frame to handle hits, misses, position
	 * following, and clipping for sustain notes.
	 */
	function noteUpdate():Void @:privateAccess {
		if (!game.generatedMusic) return;
		game.checkEventNote();
		if (game.inCutscene) return;

		if (!_botPlay) game.keysCheck();
		else game.playerDance();

		if (game.notes.length == 0) return;

		if (game.startedCountdown) game.notes.forEach(processActiveNote);
		else game.notes.forEachAlive((daNote:Note) -> daNote.canBeHit = daNote.wasGoodHit = false);
	}

	/**
	 * Processes a single active note: determines kill, hit, sustain clipping,
	 * and strum following.
	 */
	inline function processActiveNote(daNote:Note):Void @:privateAccess {
		var canBeHit:Bool = Conductor.songPosition - daNote.strumTime > 0;

		if (Settings.data.updateSpawnNote) daNote.strum = (!daNote.mustPress ? game.opponentStrums : game.playerStrums).members[daNote.noteData];

		if (Conductor.songPosition - daNote.strumTime > game.noteKillOffset) {
			if (daNote.mustPress) {
				if (_botPlay) game.goodNoteHit(daNote);
				else if (!daNote.ignoreNote && !game.endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
					trace("FUCK");
					game.noteMiss(daNote);
				}
			} else {
				if (!daNote.hitByOpponent) game.opponentNoteHit(daNote);
				if (daNote.ignoreNote && !game.endingSong) game.noteMiss(daNote, true);
			}
			game.invalidateNote(daNote);
			canBeHit = false;
		}

		if (canBeHit) {
			if (daNote.mustPress) {
				if (!daNote.blockHit || daNote.isSustainNote) {
					if (_botPlay) game.goodNoteHit(daNote);
					else {
						final holdMissed:Bool = !Util.toBool(game.pressHit & (1 << daNote.noteData)) && daNote.isSustainNote && !daNote.wasGoodHit && Conductor.songPosition - daNote.strumTime > Conductor.stepCrochet;
						if (holdMissed) game.noteMiss(daNote);
					}
				}
			} else if ((!daNote.hitByOpponent && !daNote.ignoreNote) || daNote.isSustainNote) game.opponentNoteHit(daNote);
			if (daNote.isSustainNote && daNote.strum.sustainReduce) daNote.clipToStrumNote();
		}

		if (daNote.exists) daNote.followStrumNote(_songSpeed);
	}
}