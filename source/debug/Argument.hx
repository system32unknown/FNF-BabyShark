#if sys
package debug;

import backend.Difficulty;
import backend.Mods;
import backend.Song;
import data.WeekData;

class Argument {
	public static function parse(args:Array<String>):Bool {
		switch (args[0]) {
			default: return false;

			case '-h' | '--help':
				var exePath:Array<String> = Sys.programPath().split(#if windows '\\' #else '/' #end);
				var exeName:String = exePath[exePath.length - 1].replace('.exe', '');

				Sys.println('
Usage:
  ${exeName} play "Song Name" ["Mod Folder"] [-s | --story] [-d=<val> | --diff=<val>]
  ${exeName} chart "Song Name" ["Mod Folder"] [-d=<val> | --diff=<val>]
  ${exeName} debug ["Mod Folder"]
  ${exeName} character <char> ["Mod Folder"]
  ${exeName} -h | --help

Options:
  -h       --help        Show this screen.
  -s       --story       Enables story mode when in play state.
  -d=<val> --diff=<val>  Sets the difficulty for the song. [default: ${Difficulty.getDefault().toLowerCase().trim()}]
');

				Sys.exit(0);

			case 'play':
				var modFolder:String = null;
				var diff:String = null;
				for (i in 2...args.length) {
					if (args[i] == '-s' || args[i] == '--story')
						PlayState.isStoryMode = true;

					else if (args[i].startsWith('-d=') || args[i].startsWith('--diff=')) diff = (args[i].split('='))[1];
					else if (modFolder != null) modFolder = args[i];
				}

				setupSong(args[1], modFolder, diff);
				LoadingState.loadAndSwitchState(new PlayState(), true);

			case 'chart':
				var modFolder:String = null;
				var diff:String = null;
				for (i in 2...args.length) {
					if (args[i].startsWith('-d') || args[i].startsWith('--diff'))
						diff = (args[i].split('='))[1];
					else if (modFolder != null) modFolder = args[i];
				}

				setupSong(args[1], args[2], diff);
				LoadingState.loadAndSwitchState(new states.editors.ChartingState(), true);

			case 'debug':
				if (args[1] != null) Mods.currentModDirectory = args[1];
				LoadingState.loadAndSwitchState(new states.editors.MasterEditorMenu());

			case 'character':
				if (args[2] != null) Mods.currentModDirectory = args[2];
				LoadingState.loadAndSwitchState(new states.editors.CharacterEditorState(args[1]));
		}

		return true;
	}

	static function setupSong(songName:String, ?modFolder:String, ?diff:String):Void {
		WeekData.reloadWeekFiles(PlayState.isStoryMode);

		if (modFolder == null) {
			var songFound:Bool = false;
			for (weekData in WeekData.weeksList) {
				if (songFound) break;

				var week:WeekData = WeekData.weeksLoaded.get(weekData);
				for (weekSong in week.songs) {
					if (Paths.formatToSongPath(weekSong[0]) == Paths.formatToSongPath(songName)) {
						WeekData.setDirectoryFromWeek(week);
						Difficulty.loadFromWeek(week);
						songFound = true;
						break;
					}
				}
			}
		} else Mods.currentModDirectory = modFolder;

		var defaultDiff:Bool = diff == null || (diff != null && diff.toLowerCase().trim() == Difficulty.getDefault().toLowerCase().trim());
		var jsonName:String = songName + (!defaultDiff ? '-${diff}' : '');
		PlayState.SONG = Song.loadFromJson(jsonName, songName);
	}
}
#end