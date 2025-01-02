package substates;

import data.WeekData;
import objects.HealthIcon;
import backend.Highscore;

class ResetScoreSubState extends FlxSubState {
	var bg:FlxSprite;
	var alphabetArray:Array<Alphabet> = [];
	var icon:HealthIcon;
	var onYes:Bool = false;
	var yesText:Alphabet;
	var noText:Alphabet;

	var song:String;
	var difficulty:Int;
	var week:Int;

	// Week -1 = Freeplay
	public function new(song:String, difficulty:Int, character:String, week:Int = -1) {
		this.song = song;
		this.difficulty = difficulty;
		this.week = week;

		super();

		var name:String = song;
		if (week > -1) name = WeekData.weeksLoaded.get(WeekData.weeksList[week]).weekName;
		name += ' (${Difficulty.getString(difficulty)})?';

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var tooLong:Float = (name.length > 18) ? .8 : 1; //Fucking Winter Horrorland
		var text:Alphabet = new Alphabet(0, 180, Language.getPhrase('reset_score', 'Reset the score of'));
		text.gameCenter(X);
		alphabetArray.push(text);
		text.alpha = 0;
		add(text);
		var text:Alphabet = new Alphabet(0, text.y + 90, name);
		text.scaleX = tooLong;
		text.gameCenter(X);
		if (week == -1) text.x += 60 * tooLong;
		alphabetArray.push(text);
		text.alpha = 0;
		add(text);
		if (week == -1) {
			icon = new HealthIcon(character);
			icon.setGraphicSize(Std.int(icon.width * tooLong));
			icon.updateHitbox();
			icon.setPosition(text.x - icon.width + (10 * tooLong), text.y - 30);
			icon.alpha = 0;
			add(icon);
		}

		yesText = new Alphabet(0, text.y + 150, Language.getPhrase('Yes'));
		yesText.gameCenter(X).x -= 200;
		yesText.scrollFactor.set();
		yesText.color = FlxColor.RED;
		add(yesText);
		noText = new Alphabet(0, text.y + 150, Language.getPhrase('No'));
		noText.gameCenter(X).x += 200;
		noText.scrollFactor.set();
		add(noText);

		updateOptions();
	}

	override function update(elapsed:Float) {
		bg.alpha += elapsed * 1.5;
		if (bg.alpha > .6) bg.alpha = .6;

		for (i in 0...alphabetArray.length)
			alphabetArray[i].alpha += elapsed * 2.5;
		if (week == -1) icon.alpha += elapsed * 2.5;

		if (Controls.justPressed('ui_left') || Controls.justPressed('ui_right')) {
			FlxG.sound.play(Paths.sound('scrollMenu'), 1);
			onYes = !onYes;
			updateOptions();
		}
		if (Controls.justPressed('back')) {
			FlxG.sound.play(Paths.sound('cancelMenu'), 1);
			close();
		} else if (Controls.justPressed('accept')) {
			if (onYes) {
				if (week == -1) Highscore.resetSong(song, difficulty);
				else Highscore.resetWeek(WeekData.weeksList[week], difficulty);
			}
			FlxG.sound.play(Paths.sound('cancelMenu'), 1);
			close();
		}
		super.update(elapsed);
	}

	function updateOptions() {
		var scales:Array<Float> = [.75, 1];
		var alphas:Array<Float> = [.6, 1.25];
		var confirmInt:Int = onYes ? 1 : 0;

		yesText.alpha = alphas[confirmInt];
		yesText.scale.set(scales[confirmInt], scales[confirmInt]);
		noText.alpha = alphas[1 - confirmInt];
		noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);
		if (week == -1) icon.setState(confirmInt);
	}
}