package options;

import substates.Prompt;
import backend.Highscore;

class SaveSubState extends BaseOptionsMenu {
	public function new() {
		title = 'Saves';
		rpcTitle = 'Save Menu'; //for Discord Rich Presence

		var option:Option = new Option('Reset Score', "Reset your score on all songs and weeks. This is irreversible!", 'resetScore', 'func');
		addOption(option);
		option.onChange = resetScore;

		var option:Option = new Option('Reset Week Score', "Reset your story mode progress. This is irreversible!", 'resetWeekLink', 'func');
		addOption(option);
		option.onChange = resetWeek;

		super();
	}

	function resetScore() {
		FlxG.mouse.visible = true;
		openSubState(new Prompt('This action will clear all score progress.\n\nProceed?', () -> {
            Highscore.songScores.clear();
            Highscore.songRating.clear();
            Highscore.weekScores.clear();
            FlxG.save.data.songScores = Highscore.songScores;
            FlxG.save.data.songRating = Highscore.songRating;
            FlxG.save.data.weekScores = Highscore.weekScores;
            FlxG.save.flush();

			FlxG.mouse.visible = false;
		}, () -> FlxG.mouse.visible = false));
	}

	function resetWeek() {
		FlxG.mouse.visible = true;
		openSubState(new Prompt('This action will clear all score progress.\n\nProceed?', () -> {
			FlxG.save.data.weekScores = null;
			for (key in Highscore.weekScores.keys()) Highscore.weekScores[key] = 0;
			FlxG.mouse.visible = false;
		}, () -> FlxG.mouse.visible = false));
	}
}