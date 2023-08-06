package options;

import substates.Prompt;
import backend.Highscore;

class SaveSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Saves';
		rpcTitle = 'Save Menu'; //for Discord Rich Presence

		var option:Option = new Option('Reset Score',
			"Reset your score on all songs and weeks. This is irreversible!",
			'resetScore', 'func');
		addOption(option);
		option.onChange = resetScore;

		var option:Option = new Option('Reset Week Score',
			"Reset your story mode progress. This is irreversible!",
			'resetWeekLink', 'func');
		addOption(option);
		option.onChange = resetWeek;

		super();
	}

	function cancelcallback() {
		FlxG.mouse.visible = false;
	}

	function resetScore() {
		FlxG.mouse.visible = true;
		openSubState(new Prompt('This action will clear all score progress.\n\nProceed?', function() {
			FlxG.save.data.songScores = null;
			for (key in Highscore.songScores.keys()) Highscore.songScores[key] = 0;
			FlxG.save.data.songRating = null;
			for (key in Highscore.songRating.keys()) Highscore.songRating[key] = 0;
			FlxG.save.data.songCombos = null;
			for (key in Highscore.songCombos.keys()) Highscore.songCombos[key] = '';
			FlxG.mouse.visible = false;
		}, cancelcallback));
	}

	function resetWeek() {
		FlxG.mouse.visible = true;
		openSubState(new Prompt('This action will clear all score progress.\n\nProceed?', function() {
			FlxG.save.data.weekScores = null;
			for (key in Highscore.weekScores.keys()) {
				Highscore.weekScores[key] = 0;
			}
			FlxG.mouse.visible = false;
		}, cancelcallback));
	}
}