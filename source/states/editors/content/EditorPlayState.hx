package states.editors.content;

import haxe.Timer;
import backend.Song;
import backend.Rating;

import objects.*;
import objects.Note.CastNote;
import utils.StringUtil;

import flixel.FlxBasic;
import flixel.util.FlxSort;
import openfl.events.KeyboardEvent;

class EditorPlayState extends MusicBeatSubstate {
	// Borrowed from original PlayState
	var finishTimer:FlxTimer = null;
	var noteKillOffset:Float = 350;
	var spawnTime:Float = 2000;
	var startingSong:Bool = true;

	var playbackRate:Float = 1;
	var vocals:FlxSound;
	
	var notes:FlxTypedGroup<Note>;
	var unspawnNotes:Array<CastNote> = [];
	var unspawnSustainNotes:Array<CastNote> = [];
	var ratingsData:Array<Rating> = Rating.loadDefault();
	
	var strumLineNotes:FlxTypedGroup<StrumNote>;
	var opponentStrums:FlxTypedGroup<StrumNote>;
	var playerStrums:FlxTypedGroup<StrumNote>;
	var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	
	var combo:Int = 0;
	var keysArray:Array<String> =  ['note_left', 'note_down', 'note_up', 'note_right'];
	
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
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * playbackRate;
		Conductor.songPosition -= startOffset;
		startOffset = Conductor.crochet;
		timerToStart = startOffset;
		
		/* borrowed from PlayState */
		if(ClientPrefs.data.hitsoundVolume > 0) Paths.sound('hitsounds/${Std.string(ClientPrefs.data.hitsoundTypes).toLowerCase()}');

		/* setting up Editor PlayState stuff */
		var bg:FlxSprite = new FlxSprite().makeSolid(FlxG.width, FlxG.height, 0xFF101010);
		bg.scrollFactor.set();
		bg.alpha = .9;
		bg.active = false;
		add(bg);
		
		/**** NOTES ****/
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		comboGroup = new FlxSpriteGroup();
		noteGroup = new FlxTypedGroup<FlxBasic>();
		
		timeTxt = new FlxText(0, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		timeTxt.setBorderStyle(OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.gameCenter(X);
		timeTxt.visible = showTime;
		if(downScroll) timeTxt.y = FlxG.height - 44;
		add(timeTxt);

		add(comboGroup);
		add(noteGroup);
		noteGroup.add(strumLineNotes);

		var splash:NoteSplash = new NoteSplash();
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

	var totalCnt:Int = 0;
	override function update(elapsed:Float) {
		if(Controls.justPressed('back') || FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.F12) {
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

		if (showTime) timeTxt.text = StringUtil.formatTime(Math.floor(Math.max(0, (Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset) / playbackRate) / 1000))) + " / " + StringUtil.formatTime(Math.floor((songLength / playbackRate) / 1000));	

		if (unspawnNotes.length > totalCnt) {
			var targetNote:CastNote = unspawnNotes[totalCnt];
			while (targetNote.strumTime - Conductor.songPosition < spawnTime) {
				var dunceNote:Note = notes.recycle(Note).recycleNote(targetNote);
				dunceNote.spawned = true;
	
				dunceNote.strum = (!dunceNote.mustPress ? opponentStrums : playerStrums).members[dunceNote.noteData];
				notes.insert(0, dunceNote);
				++totalCnt;
				if (unspawnNotes.length > totalCnt) targetNote = unspawnNotes[totalCnt];
				else break;
			}
		}

		if (!cpuControlled) keysCheck();
		if(notes.length > 0) {
			notes.forEachAlive((daNote:Note) -> {
				daNote.followStrumNote(songSpeed / playbackRate);

				if(daNote.mustPress) {
					if(cpuControlled && !daNote.blockHit && daNote.canBeHit && ((daNote.isSustainNote && daNote.prevNote.wasGoodHit) || daNote.strumTime <= Conductor.songPosition)) goodNoteHit(daNote);
				} else if(!daNote.mustPress && !daNote.hitByOpponent && !daNote.ignoreNote && daNote.strumTime <= Conductor.songPosition) opponentNoteHit(daNote);
				if(daNote.isSustainNote && daNote.strum.sustainReduce) daNote.clipToStrumNote();

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
		NoteSplash.configs.clear();
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
		
		var songData:SwagSong = PlayState.SONG;
		Conductor.bpm = songData.bpm;
		FlxG.sound.music.volume = vocals.volume = 0;

		noteGroup.add(notes = new FlxTypedGroup<Note>());

		var daBpm:Float = (PlayState.SONG.notes[0].changeBPM == true) ? PlayState.SONG.notes[0].bpm : PlayState.SONG.bpm;
		var songNotes:Array<Dynamic> = [];

		// Section Time/Crochet
		var noteSec:Int = 0;
		var secTime:Float = 0;
		var cachedSectionTimes:Array<Float> = [];
		var cachedSectionCrochets:Array<Float> = [];
		if(PlayState.SONG != null) {
			var tempBpm:Float = daBpm;
			for (_ => section in PlayState.SONG.notes) {
				if(PlayState.SONG.notes[noteSec].changeBPM == true) tempBpm = PlayState.SONG.notes[noteSec].bpm;
				secTime += Conductor.calculateCrochet(tempBpm) * (Math.round(4 * section.sectionBeats) / 4);
				cachedSectionTimes.push(secTime);
			}
		}

		// Load Notes
		var section:SwagSection = songData.notes[0];
		for (note in _noteList) {
			if(note == null || note.strumTime < startPos) continue;

			while(cachedSectionTimes.length > noteSec + 1 && cachedSectionTimes[noteSec + 1] <= note.strumTime) {
				section = songData.notes[++noteSec];
				if(PlayState.SONG.notes[noteSec].changeBPM == true)
					daBpm = PlayState.SONG.notes[noteSec].bpm;
			}

			var swagNote:CastNote = cast { strumTime: songNotes[0], noteData: songNotes[1], noteType: Math.isNaN(songNotes[3]) ? songNotes[3] : 0, holdLength: songNotes[2], noteSkin: songData.arrowSkin ?? ""};
			
			swagNote.noteData |= section.mustHitSection ? 1 << 8 : 0; // mustHit
			swagNote.noteData |= (section.gfSection && (songNotes[1] < 4) || songNotes[3] == 'GF Sing' || songNotes[3] == 4) ? 1 << 11 : 0; // gfNote
			swagNote.noteData |= (section.altAnim || (songNotes[3] == 'Alt Animation' || songNotes[3] == 1)) ? 1 << 12 : 0; // altAnim
			swagNote.noteData |= (songNotes[3] == 'No Animation' || songNotes[3] == 5) ? 3 << 13 : 0; // noAnimation & noMissAnimaiton
			swagNote.noteData |= (songNotes[3] == 'Hurt Note' || songNotes[3] == 3) ? 1 << 15 : 0;
			if (songNotes[1] > 3) swagNote.noteData ^= 1 << 8;
			unspawnNotes.push(swagNote);

			final roundSus:Int = Math.round(swagNote.holdLength / Conductor.stepCrochet);
			if(roundSus > 0) {
				for (susNote in 0...roundSus) {
					swagNote.noteData |= 1 << 9; // isHold
					swagNote.noteData |= susNote == roundSus ? 1 << 10 : 0; // isHoldEnd
					var sustainNote:CastNote = cast {strumTime: swagNote.noteData + Conductor.stepCrochet * susNote, noteData: swagNote.noteData, noteType: swagNote.noteType, holdLength: 0, noteSkin: swagNote.noteSkin};
					unspawnSustainNotes.push(sustainNote);
				}
			}
		}
		unspawnNotes.sort(PlayState.sortByTime);
	}
	
	function generateStaticArrows(player:Int):Void {
        var strumLine:FlxPoint = FlxPoint.get(middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X, downScroll ? (FlxG.height - 150) : 50);
		for (i in 0...4) {
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
				if(i > 1) babyArrow.x += FlxG.width / 2 + 25; //Up and Right
			}

			(player == 1 ? playerStrums : opponentStrums).add(babyArrow);
			strumLineNotes.add(babyArrow);
			babyArrow.playerPosition();
		}
        strumLine.put();
	}

	public function finishSong():Void {
		if(ClientPrefs.data.noteOffset <= 0) endSong();
		else finishTimer = FlxTimer.wait(ClientPrefs.data.noteOffset / 1000, () -> endSong());
	}

	public function endSong() {
		notes.forEachAlive((note:Note) -> invalidateNote(note));
		unspawnNotes.resize(0);

		FlxG.sound.music.pause();
		vocals.pause();
		if(finishTimer != null) finishTimer.destroy();
		Conductor.songPosition = FlxG.sound.music.time = vocals.time = startPos - Conductor.offset;
		close();
	}

	function cachePopUpScore() {
		var uiFolder:String = "";
		if (PlayState.stageUI != "normal") uiFolder = PlayState.uiPrefix + "UI/";

		for (rating in ratingsData) Paths.image(uiFolder + 'ratings/${rating.image}'+ PlayState.uiPostfix);
		for (i in 0...10) Paths.image(uiFolder + 'number/num$i' + PlayState.uiPostfix);
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

		var uiFolder:String = "";
		var antialias:Bool = ClientPrefs.data.antialiasing;
        final mult:Float = .7;

		var comboOffset:Array<Array<Int>> = ClientPrefs.data.comboOffset;
		var rating:FlxSprite = null;
		if (showRating) {
			rating = comboGroup.recycle(FlxSprite).loadGraphic(Paths.image(uiFolder + 'ratings/${daRating.image}' + PlayState.uiPostfix));
			rating.gameCenter(Y).y -= 60 + comboOffset[0][1];
			rating.x = placement - 40 + comboOffset[0][0];
	
			rating.velocity.set(-FlxG.random.int(0, 10) * playbackRate, -FlxG.random.int(140, 175) * playbackRate);
			rating.acceleration.set(playbackRate * playbackRate, 550 * playbackRate * playbackRate);
			rating.antialiasing = antialias;
			rating.setGraphicSize(rating.width * mult);
			rating.updateHitbox();
	
			comboGroup.add(rating);
			FlxTween.tween(rating, {alpha: 0}, .2 / playbackRate, {onComplete: (_:FlxTween) -> {rating.kill(); rating.alpha = 1;}, startDelay: Conductor.crochet * .001 / playbackRate});
		}

		if (showComboNum) {
			var comboSplit:Array<String> = Std.string(Math.abs(combo)).split('');
			var daLoop:Int = 0;
			for (i in [for (i in 0...comboSplit.length) Std.parseInt(comboSplit[i])]) {
				var numScore:FlxSprite = comboGroup.recycle(FlxSprite).loadGraphic(Paths.image(uiFolder + 'number/num$i' + PlayState.uiPostfix));
				numScore.setPosition(rating.x + (43 * daLoop++) - 50 + comboOffset[1][0], rating.y + 100 - comboOffset[1][1]);
			
				numScore.velocity.set(FlxG.random.float(-5, 5) * playbackRate, -FlxG.random.int(130, 150) * playbackRate);
				numScore.acceleration.set(playbackRate * playbackRate, FlxG.random.int(250, 300) * playbackRate * playbackRate);
				numScore.antialiasing = antialias;
				numScore.setGraphicSize(numScore.width * .5);
				numScore.updateHitbox();

				comboGroup.add(numScore);
				FlxTween.tween(numScore, {alpha: 0}, .2 / playbackRate, {onComplete: (_:FlxTween) -> {numScore.kill(); numScore.alpha = 1;}, startDelay: Conductor.crochet * .002 / playbackRate});
			}
		}
	}

	function onKeyPress(event:KeyboardEvent):Void {
		var eventKey:flixel.input.keyboard.FlxKey = event.keyCode;
		if(FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(Controls.convertStrumKey(keysArray, eventKey));
	}

	function keyPressed(key:Int) {
		if(cpuControlled || key < 0 || key > playerStrums.length) return;

		var lastTime:Float = Conductor.songPosition; // more accurate hit time for the ratings?
		if(Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		// obtain notes that the player can hit

		var plrInputNotes:Array<Note> = notes.members.filter((n:Note) -> return n != null && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit && !n.isSustainNote && n.noteData == key);
		plrInputNotes.sort((a:Note, b:Note) -> Std.int(a.strumTime - b.strumTime));

		if (plrInputNotes.length != 0) { // slightly faster than doing `> 0` lol
			var funnyNote:Note = plrInputNotes[0]; // front note
			if (plrInputNotes.length > 1) {
				var doubleNote:Note = plrInputNotes[1];

				if (doubleNote.noteData == funnyNote.noteData) {
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.) invalidateNote(doubleNote);
					else if (doubleNote.strumTime < funnyNote.strumTime) funnyNote = doubleNote;
				}
			}

			goodNoteHit(funnyNote);
		}
		Conductor.songPosition = lastTime;

		final spr:StrumNote = playerStrums.members[key];
		if(spr != null && spr.animation.curAnim.name != 'confirm') {
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
	}

	function onKeyRelease(event:KeyboardEvent):Void {
		var key:Int = Controls.convertStrumKey(keysArray, event.keyCode);
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
		var holdArray:Array<Bool> = [for (key in keysArray) Controls.pressed(key)];
		if (notes.length > 0) for (n in notes) if ((n != null && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit) && n.isSustainNote && holdArray[n.noteData]) goodNoteHit(n);
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

		strumPlayAnim(false, note.noteData % 4, cpuControlled ? Conductor.stepCrochet * 1.25 / 1000 : 0);
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
			if(strum != null) spawnNoteSplash(note, strum);
		}
	}

	function spawnNoteSplash(note:Note, strum:StrumNote) {
		var splash:NoteSplash = new NoteSplash();
		splash.babyArrow = strum;
		splash.spawnSplashNote(note);
		grpNoteSplashes.add(splash);
	}

	function updateScore() {
		scoreTxt.text = '${!ClientPrefs.data.showNPS ? '' : 'NPS:$nps/$maxNPS | '}' + 'Hits:$songHits | Misses:$songMisses';
	}
	
	function strumPlayAnim(isDad:Bool, id:Int, time:Float = 0) {
		var spr:StrumNote = (isDad ? opponentStrums : playerStrums).members[id];
		if(spr != null && ClientPrefs.data.lightStrum) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time / playbackRate;
		}
	}
}