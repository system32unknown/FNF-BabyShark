package options;

import flixel.FlxG;
import ui.Prompt;
import game.Highscore;
import utils.CoolUtil;

using StringTools;

class SaveSubState extends FuncOptionsMenu
{
	public function new()
	{
		title = 'Saves';
		rpcTitle = 'Save Menu'; //for Discord Rich Presence

		var option:OptionFunc = new OptionFunc('Reset Score', "Reset your score on all songs and weeks. This is irreversible!", function() {
			FlxG.mouse.visible = true;
			openSubState(new Prompt('This action will clear all score progress.\n\nProceed?', function() {
				FlxG.save.data.songScores = null;
				for (key in Highscore.songScores.keys()) {
					Highscore.songScores[key] = 0;
				}
				FlxG.save.data.songRating = null;
				for (key in Highscore.songRating.keys()) {
					Highscore.songRating[key] = 0;
				}
				FlxG.mouse.visible = false;
			}, cancelcallback));
		});
		addOptionFunc(option);

		var option:OptionFunc = new OptionFunc('Reset Week Score', "Reset your story mode progress. This is irreversible!", function() {
			FlxG.mouse.visible = true;
			openSubState(new Prompt('This action will clear all score progress.\n\nProceed?', function() {
				FlxG.save.data.weekScores = null;
				for (key in Highscore.weekScores.keys()) {
					Highscore.weekScores[key] = 0;
				}
				FlxG.mouse.visible = false;
			}, cancelcallback));
		});
		addOptionFunc(option);

		for (i in 0...10) {
			var option:OptionFunc = new OptionFunc('Secret Page ' + i, CoolUtil.getRandomizedText(20), function() {
				trace("Well you're tried.");
				Sys.exit(0);
			});
			addOptionFunc(option);
		}

		super();
	}

	function cancelcallback() {
		FlxG.mouse.visible = false;
	}
}