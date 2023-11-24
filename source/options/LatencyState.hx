package options;

import objects.Note;

class LatencyState extends MusicBeatState {
	var offsetText:FlxText;
	var noteGrp:FlxTypedGroup<Note>;
	var strumLine:FlxSprite;

	override function create() {
		add(noteGrp = new FlxTypedGroup<Note>());

		for (i in 0...32)
			noteGrp.add(new Note(Conductor.crochet * i, 1));

		offsetText = new FlxText();
		offsetText.screenCenter();
		add(offsetText);

		add(strumLine = new FlxSprite(FlxG.width / 2, 100).makeGraphic(FlxG.width, 5));

		Conductor.bpm = 120;

		super.create();
	}

	override function update(elapsed:Float) {
		offsetText.text = "Offset: " + Conductor.offset + "ms";

		Conductor.songPosition = FlxG.sound.music.time - Conductor.offset;

		var multiply:Float = 1;
		if (FlxG.keys.pressed.SHIFT) multiply = 10;

		if (controls.UI_RIGHT) Conductor.offset += 1 * multiply;
		if (controls.UI_LEFT) Conductor.offset -= 1 * multiply;

		if (controls.RESET) {
			FlxG.sound.music.stop();
			FlxG.resetState();
		}

		if(controls.BACK) {
			MusicBeatState.switchState(new OptionsState());
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 1, true);
		}

		noteGrp.forEach((daNote:Note) -> {
			daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * .45);
			daNote.x = strumLine.x + 30;

			if (daNote.y < strumLine.y) daNote.kill();
		});

		super.update(elapsed);
	}
}