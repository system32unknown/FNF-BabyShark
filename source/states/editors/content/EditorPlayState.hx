package states.editors.content;

import backend.Song;
import backend.Rating;

import objects.*;
import utils.MathUtil;

import flixel.FlxBasic;
import flixel.util.FlxSort;
import openfl.events.KeyboardEvent;

class EditorPlayState extends MusicBeatSubstate {
	// Borrowed from original PlayState
	var finishTimer:FlxTimer = null;
	var noteKillOffset:Float = 350;
	var spawnTime:Float = 2000;
	var startingSong:Bool = true;

    var mania:Int = 0;
	var playbackRate:Float = 1;
	var vocals:FlxSound;
	
	var notes:NoteGroup;
	var unspawnNotes:Array<Note> = [];
	var ratingsData:Array<Rating> = Rating.loadDefault();
	
	var strumLineNotes:FlxTypedGroup<StrumNote>;
	var opponentStrums:FlxTypedGroup<StrumNote>;
	var playerStrums:FlxTypedGroup<StrumNote>;
	var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	
	var combo:Int = 0;
	var keysArray:Array<String> = [];
	
	var comboGroup:FlxSpriteGroup;
	var noteGroup:FlxTypedGroup<FlxBasic>;

	var songHits:Int = 0;
	var songMisses:Int = 0;
	var songLength:Float = 0;
	var songSpeed:Float = 1;
	
	var showComboNum:Bool = true;
	var showRating:Bool = true;

	// Originals
	var startOffset:Float = 0;
	var startPos:Float = 0;
	var timerToStart:Float = 0;

	var scoreTxt:FlxText;
	var dataTxt:FlxText;

	var msTimingTween:FlxTween;
	var mstimingTxt:FlxText = new FlxText(0, 0, 0, "0ms");

	var downScroll:Bool = ClientPrefs.data.downScroll;
	var middleScroll:Bool = ClientPrefs.data.middleScroll;

	var notesHitArray:Array<Date> = [];
	var nps:Int = 0;
	var maxNPS:Int = 0;

	var cpuControlled:Bool = false;
	
	var timeTxt:FlxText;
	var showTime:Bool = true;

	var _noteList:Array<Note>;
	public function new(noteList:Array<Note>, vocal:FlxSound) {
		super();

		/* setting up some important data */
		this.vocals = vocal;
		this._noteList = noteList;
		this.startPos = Conductor.songPosition;
		Conductor.songPosition = startPos;

		playbackRate = FlxG.sound.music.pitch;
	}

	override function create() {
		mania = PlayState.mania;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * playbackRate;
		Conductor.songPosition -= startOffset;
		startOffset = Conductor.crochet;
		timerToStart = startOffset;
		
		/* borrowed from PlayState */
		if(ClientPrefs.data.hitsoundVolume > 0) Paths.sound('hitsounds/${Std.string(ClientPrefs.data.hitsoundTypes).toLowerCase()}');

		/* setting up Editor PlayState stuff */
		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, 0xFF101010);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.scrollFactor.set();
		bg.alpha = .9;
		bg.active = false;
		add(bg);
		
		/**** NOTES ****/
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpNoteSplashes.ID = 0;

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		comboGroup = new FlxSpriteGroup();
		comboGroup.ID = 0;
		noteGroup = new FlxTypedGroup<FlxBasic>();
		
		timeTxt = new FlxText(0, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		timeTxt.setBorderStyle(OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.screenCenter(X);
		timeTxt.visible = showTime;
		if(downScroll) timeTxt.y = FlxG.height - 44;
		add(timeTxt);

		add(comboGroup);
		add(noteGroup);
		noteGroup.add(strumLineNotes);

		var splash:NoteSplash = new NoteSplash(100, 100);
		grpNoteSplashes.add(splash);
		splash.alpha = .000001; //cant make it invisible or it won't allow precaching
        noteGroup.add(grpNoteSplashes);

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();
		
		generateStaticArrows(0);
		generateStaticArrows(1);
		
		scoreTxt = new FlxText(10, FlxG.height - 35, FlxG.width - 20, "", 16);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		add(scoreTxt);
		
		dataTxt = new FlxText(10, 580, FlxG.width - 20, "Section: 0", 20);
		dataTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		dataTxt.scrollFactor.set();
		dataTxt.borderSize = 1.25;
		add(dataTxt); dataTxt.updateHitbox();

		var tipText:FlxText = new FlxText(10, FlxG.height - 24, 0, 'Press ESC to Go Back to Chart Editor', 16);
		tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		tipText.borderSize = 2;
		tipText.scrollFactor.set();
		add(tipText);
		FlxG.mouse.visible = false;

		generateSong();
        keysArray = EK.fillKeys()[mania];
		_noteList = null;

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Playtesting on Chart Editor', PlayState.SONG.song, true, songLength);
		#end
		updateScore();
		cachePopUpScore();

		super.create();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float) {
		if(controls.BACK || FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.F12) {
			endSong();
			super.update(elapsed);
			return;
		}
		if (FlxG.keys.justPressed.SIX) cpuControlled = !cpuControlled;
		
		if (startingSong) {
			timerToStart -= elapsed * 1000;
			Conductor.songPosition = startPos - timerToStart;
			if(timerToStart < 0) startSong();
		} else {
			Conductor.songPosition += elapsed * 1000 * playbackRate;
			if (Conductor.songPosition >= 0) {
				var timeDiff:Float = Math.abs((FlxG.sound.music.time + Conductor.offset) - Conductor.songPosition);
				Conductor.songPosition = FlxMath.lerp(FlxG.sound.music.time + Conductor.offset, Conductor.songPosition, Math.exp(-elapsed * 2.5));
				if (timeDiff > 1000 * playbackRate) Conductor.songPosition = Conductor.songPosition + 1000 * FlxMath.signOf(timeDiff);
			}
		}

		if (showTime) timeTxt.text = CoolUtil.formatTime(Math.floor(Math.max(0, (Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset) / playbackRate) / 1000))) + " / " + CoolUtil.formatTime(Math.floor((songLength / playbackRate) / 1000));	

		if (unspawnNotes[0] != null) {
			var time:Float = spawnTime * playbackRate;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time) {
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				unspawnNotes.splice(unspawnNotes.indexOf(dunceNote), 1);
			}
		}

		if (!cpuControlled) keysCheck();
		if(notes.length != 0) {
			notes.forEachAlive((daNote:Note) -> {
				var strum:StrumNote = (daNote.mustPress ? playerStrums : opponentStrums).members[daNote.noteData];
				daNote.followStrumNote(strum, songSpeed / playbackRate);

				if(daNote.mustPress) {
					if(cpuControlled && !daNote.blockHit && daNote.canBeHit && ((daNote.isSustainNote && daNote.prevNote.wasGoodHit) || daNote.strumTime <= Conductor.songPosition)) goodNoteHit(daNote);
				} else if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote) opponentNoteHit(daNote);
				if(daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);

				// Kill extremely late notes and cause misses
				if (Conductor.songPosition - daNote.strumTime > noteKillOffset) {
					if (daNote.mustPress && !daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit)) noteMiss(daNote);
					daNote.active = daNote.visible = false;
					invalidateNote(daNote);
				}
			});
		}
		
		if (ClientPrefs.data.showNPS) {
			for(i in 0...notesHitArray.length) {
				var curNPS:Date = notesHitArray[i];
				if (curNPS != null && curNPS.getTime() + (1000 / playbackRate) < Date.now().getTime()) notesHitArray.remove(curNPS);
			}
			nps = Math.floor(notesHitArray.length);
			if (nps > maxNPS) maxNPS = nps;
			updateScore();
		}

		dataTxt.text = 'Section:$curSection\nBeat:$curBeat\nStep:$curStep\nBot:${(cpuControlled ? 'ON' : 'OFF')}';
		super.update(elapsed);
	}

	var lastBeatHit:Int = -1;
	override function beatHit() {
		if(lastBeatHit >= curBeat) return;
		notes.sort(FlxSort.byY, downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		super.beatHit();
		lastBeatHit = curBeat;
	}
	
	override function sectionHit() {
		if (PlayState.SONG.notes[curSection] != null && PlayState.SONG.notes[curSection].changeBPM)
			Conductor.bpm = PlayState.SONG.notes[curSection].bpm;
		super.sectionHit();
	}

	override function destroy() {
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		FlxG.mouse.visible = true;
		super.destroy();
	}
	
	function startSong():Void {
		startingSong = false;
		FlxG.sound.music.onComplete = finishSong;
		FlxG.sound.music.volume = vocals.volume = 1;

		FlxG.sound.music.play();
		vocals.play();
		FlxG.sound.music.time = vocals.time = startPos - Conductor.offset;

		songLength = FlxG.sound.music.length; // Song duration in a float, useful for the time left feature
	}

	// Borrowed from PlayState
	function generateSong() {
		songSpeed = PlayState.SONG.speed;
		switch(ClientPrefs.getGameplaySetting('scrolltype')) {
			case "multiplicative": songSpeed = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant": songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
		
		var songData:SwagSong = PlayState.SONG;
		Conductor.bpm = songData.bpm;
		FlxG.sound.music.volume = vocals.volume = 0;

		noteGroup.add(notes = new NoteGroup());

		var oldNote:Note = null;
		for (note in _noteList) {
			if(note == null || note.strumTime < startPos) continue;

			var idx:Int = _noteList.indexOf(note);
			if (idx != 0) {
				// CLEAR ANY POSSIBLE GHOST NOTES
				for (evilNote in unspawnNotes) {
					var matches:Bool = note.noteData == evilNote.noteData && note.mustPress == evilNote.mustPress && note.noteType == evilNote.noteType;
					if (matches && Math.abs(note.strumTime - evilNote.strumTime) == 0.0) {
						evilNote.destroy();
						unspawnNotes.remove(evilNote);
					}
				}
			}

			var swagNote:Note = new Note(note.strumTime, note.noteData, oldNote, false, this);
			swagNote.mustPress = note.mustPress;
			swagNote.sustainLength = note.sustainLength;
			swagNote.gfNote = note.gfNote;
			swagNote.noteType = note.noteType;
			swagNote.scrollFactor.set();
			unspawnNotes.push(swagNote);

			var roundSus:Int = Math.floor(swagNote.sustainLength / Conductor.stepCrochet);
			if(roundSus > 0) {
				for (susNote in 0...roundSus + 1) {
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(swagNote.strumTime + (Conductor.stepCrochet * susNote), note.noteData, oldNote, true, this);
					sustainNote.mustPress = swagNote.mustPress;
					sustainNote.gfNote = swagNote.gfNote;
					sustainNote.noteType = swagNote.noteType;
					sustainNote.scrollFactor.set();
					sustainNote.parent = swagNote;
					unspawnNotes.push(sustainNote);
					swagNote.tail.push(sustainNote);

					sustainNote.correctionOffset = swagNote.height / 2;
					if(!PlayState.isPixelStage) {
						if(oldNote.isSustainNote) {
							oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
							oldNote.scale.y /= playbackRate;
							oldNote.updateHitbox();
						}

						if(downScroll) sustainNote.correctionOffset = 0;
					} else if(oldNote.isSustainNote) {
						oldNote.scale.y /= playbackRate;
						oldNote.updateHitbox();
					}

					if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2; // general offset
					else if(middleScroll) {
						sustainNote.x += 310;
						if(sustainNote.noteData > 1) sustainNote.x += FlxG.width / 2 + 25;  // Up and Right
					}
				}
			}

			if (swagNote.mustPress) swagNote.x += FlxG.width / 2; // general offset
			else if(middleScroll) {
				swagNote.x += 310;
				if(swagNote.noteData > 1) swagNote.x += FlxG.width / 2 + 25; //Up and Right
			}
			oldNote = swagNote;
		}
		unspawnNotes.sort(PlayState.sortByTime);
	}
	
	function generateStaticArrows(player:Int):Void {
        var strumLine:FlxPoint = FlxPoint.get(middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X, downScroll ? (FlxG.height - 150) : 50);
		for (i in 0...EK.keys(mania)) {
			var targetAlpha:Float = 1;
			if (player < 1) {
				if(!ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if(middleScroll) targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(strumLine.x, strumLine.y, i, player);
			babyArrow.downScroll = downScroll;
			babyArrow.alpha = targetAlpha;

			if (player < 1 && middleScroll) {
				babyArrow.x += 310;
				if(i > EK.midArray[mania]) babyArrow.x += FlxG.width / 2 + 25; //Up and Right
			}

			(player == 1 ? playerStrums : opponentStrums).add(babyArrow);
			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
        strumLine.put();
	}

	public function finishSong():Void {
		if(ClientPrefs.data.noteOffset <= 0) endSong();
		else finishTimer = FlxTimer.wait(ClientPrefs.data.noteOffset / 1000, () -> endSong());
	}

	public function endSong() {
		notes.forEachAlive((note:Note) -> invalidateNote(note));
		for (note in unspawnNotes) if(note != null) invalidateNote(note);

		FlxG.sound.music.pause();
		vocals.pause();
		if(finishTimer != null) finishTimer.destroy();
		Conductor.songPosition = FlxG.sound.music.time = vocals.time = startPos - Conductor.offset;
		close();
	}

	function cachePopUpScore() {
		for (rating in ratingsData) Paths.image('ratings/${rating.image}');
		for (i in 0...10) Paths.image('number/num$i');
	}

	function popUpScore(note:Note = null):Void {
		var noteDiff:Float = PlayState.getNoteDiff(note) / playbackRate;
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff, cpuControlled);

		note.ratingMod = daRating.ratingMod;
		note.rating = daRating.name;

		if(!note.ratingDisabled) daRating.hits++;
		if(daRating.noteSplash && !note.noteSplashData.disabled) spawnNoteSplashOnNote(note);

		if(!note.ratingDisabled) songHits++;

		if (!ClientPrefs.data.showComboCounter || (!showRating && !showComboNum)) return;
		if (!ClientPrefs.data.comboStacking) comboGroup.forEachAlive((spr:FlxSprite) -> FlxTween.globalManager.completeTweensOf(spr));

		final placement:Float = FlxG.width * .35;
		var antialias:Bool = ClientPrefs.data.antialiasing;
        final mult:Float = .7;

		var comboOffset:Array<Array<Int>> = ClientPrefs.data.comboOffset;
		var rating:FlxSprite = null;
		if (showRating) {
			rating = comboGroup.recycle(FlxSprite).loadGraphic(Paths.image('ratings/${daRating.image}'));
			rating.screenCenter(Y).y -= 60 + comboOffset[0][1];
			rating.x = placement - 40 + comboOffset[0][0];
	
			rating.velocity.set(-FlxG.random.int(0, 10) * playbackRate, -FlxG.random.int(140, 175) * playbackRate);
			rating.acceleration.set(playbackRate * playbackRate, 550 * playbackRate * playbackRate);
			rating.antialiasing = antialias;
			rating.setGraphicSize(rating.width * mult);
			rating.updateHitbox();
			rating.ID = comboGroup.ID++;
	
			comboGroup.add(rating);
			FlxTween.tween(rating, {alpha: 0}, .2 / playbackRate, {onComplete: (_) -> {rating.kill(); rating.alpha = 1;}, startDelay: Conductor.crochet * .001 / playbackRate});
		}

		if (ClientPrefs.data.showMsTiming && mstimingTxt != null) {
			mstimingTxt.setFormat(null, 20, FlxColor.WHITE, CENTER);
			mstimingTxt.setBorderStyle(OUTLINE, FlxColor.BLACK);
			mstimingTxt.text = '${MathUtil.truncateFloat(noteDiff / playbackRate)}ms';
			mstimingTxt.color = SpriteUtil.dominantColor(rating);
			mstimingTxt.setPosition(rating.x + 100, rating.y + 100);
			mstimingTxt.updateHitbox();
			mstimingTxt.ID = comboGroup.ID++;
			comboGroup.add(mstimingTxt);
		}

		if (showComboNum) {
			var comboSplit:Array<String> = Std.string(Math.abs(combo)).split('');
			var daLoop:Int = 0;
			for (i in [for (i in 0...comboSplit.length) Std.parseInt(comboSplit[i])]) {
				var numScore:FlxSprite = comboGroup.recycle(FlxSprite).loadGraphic(Paths.image('number/num$i'));
				numScore.setPosition(rating.x + (43 * daLoop++) - 50 + comboOffset[1][0], rating.y + 100 - comboOffset[1][1]);
			
				numScore.velocity.set(FlxG.random.float(-5, 5) * playbackRate, -FlxG.random.int(130, 150) * playbackRate);
				numScore.acceleration.set(playbackRate * playbackRate, FlxG.random.int(250, 300) * playbackRate * playbackRate);
				numScore.antialiasing = antialias;
				numScore.setGraphicSize(numScore.width * .5);
				numScore.updateHitbox();
				numScore.ID = comboGroup.ID++;

				comboGroup.add(numScore);
				FlxTween.tween(numScore, {alpha: 0}, .2 / playbackRate, {onComplete: (_) -> {numScore.kill(); numScore.alpha = 1;}, startDelay: Conductor.crochet * .002 / playbackRate});
			}
		}

		if (ClientPrefs.data.showMsTiming) {
			if (msTimingTween != null) {mstimingTxt.alpha = 1; msTimingTween.cancel();}
			msTimingTween = FlxTween.tween(mstimingTxt, {alpha: 0}, .2 / playbackRate, {startDelay: Conductor.crochet * .001 / playbackRate});
		}
		comboGroup.sort(CoolUtil.sortByID);
	}

	function onKeyPress(event:KeyboardEvent):Void {
		var eventKey:flixel.input.keyboard.FlxKey = event.keyCode;
		if(FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(PlayState.getKeyFromEvent(keysArray, eventKey));
	}

	function keyPressed(key:Int) {
		if(cpuControlled || key < 0 || key > playerStrums.length) return;

		var lastTime:Float = Conductor.songPosition; // more accurate hit time for the ratings?
		if(Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		// obtain notes that the player can hit
		final plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool {
			final noteIsHittable:Bool = n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
			return n != null && noteIsHittable && !n.isSustainNote && n.noteData == key;
		});
		plrInputNotes.sort((a:Note, b:Note) -> Std.int(a.strumTime - b.strumTime));

		if (plrInputNotes.length != 0) goodNoteHit(plrInputNotes[0]); // nicer on the GPU usage than doing `> 0` lol
		Conductor.songPosition = lastTime;

		final spr:StrumNote = playerStrums.members[key];
		if(spr != null && spr.animation.curAnim.name != 'confirm') {
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
	}

	function onKeyRelease(event:KeyboardEvent):Void {
		var key:Int = PlayState.getKeyFromEvent(keysArray, event.keyCode);
		if(key > -1) keyReleased(key);
	}

	function keyReleased(key:Int) {
		if(cpuControlled || key < 0 || key > playerStrums.length) return;

		var spr:StrumNote = playerStrums.members[key];
		if(spr != null) {
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
	}
	
	// Hold notes
	function keysCheck():Void {
		var holdArray:Array<Bool> = [for (key in keysArray) controls.pressed(key)];
		if (notes.length != 0) {
			for (sustainNote in notes.members.filter((n:Note) -> return n.canBeHit && n.mustPress && !n.tooLate && !n.blockHit)) {
				if (sustainNote.isSustainNote && holdArray[sustainNote.noteData]) goodNoteHit(sustainNote);
			}
		}
	}

	function opponentNoteHit(note:Note):Void {
		if (PlayState.SONG.needsVoices) vocals.volume = 1;
        strumPlayAnim(true, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000);
		note.hitByOpponent = true;
		if (!note.isSustainNote) invalidateNote(note);
	}

	function goodNoteHit(note:Note):Void {
		if (note.wasGoodHit || (cpuControlled && note.ignoreNote)) return;

		note.wasGoodHit = true;
		if (note.hitsoundVolume > 0 && !note.hitsoundDisabled) FlxG.sound.play(Paths.sound('${note.hitsound}'), note.hitsoundVolume);

		if(note.hitCausesMiss) {
			noteMiss(note);
			if(!note.isSustainNote) {
                if(!note.noteSplashData.disabled) spawnNoteSplashOnNote(note);
                invalidateNote(note);
            } 
			return;
		}

		if (!note.isSustainNote) {
			notesHitArray.push(Date.now());
			combo++;
			popUpScore(note);
		}

		strumPlayAnim(false, note.noteData % EK.keys(mania), cpuControlled ? Conductor.stepCrochet * 1.25 / 1000 : 0);
		vocals.volume = 1;

		if (!note.isSustainNote) invalidateNote(note);
	}
	
	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		if (daNote.animation.curAnim.name.endsWith("end")) return;

		songMisses++; // score and data
		updateScore();
		vocals.volume = 0;
		combo = 0;
	}

	public function invalidateNote(note:Note):Void {
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	function spawnNoteSplashOnNote(note:Note) {
		if(note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) spawnNoteSplash(strum.x + EK.swidths[mania] / 2 - Note.swagWidth / 2, strum.y + EK.swidths[mania] / 2 - Note.swagWidth / 2, note.noteData, note);
		}
	}

	function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, note);
		grpNoteSplashes.add(splash);
	}

	function updateScore() {
		scoreTxt.text = '${!ClientPrefs.data.showNPS ? '' : 'NPS:$nps/$maxNPS | '}' + 'Hits:$songHits | Breaks:$songMisses';
	}
	
	function strumPlayAnim(isDad:Bool, id:Int, time:Float = 0) {
		var spr:StrumNote = (isDad ? opponentStrums : playerStrums).members[id];
		if(spr != null && ClientPrefs.data.lightStrum) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time / playbackRate;
		}
	}
}