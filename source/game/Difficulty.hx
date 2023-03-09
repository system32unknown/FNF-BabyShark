package game;

import states.PlayState;

class Difficulty {
	public static var defaultList(default, never):Array<String> = ['Easy', 'Normal', 'Hard'];
	public static var list:Array<String> = [];
	static var defaultDifficulty(default, never):String = 'Normal'; //The chart that has no suffix and starting difficulty on Freeplay/Story Mode

	public static var lowerlists(get, null):Array<String>;
	static function get_lowerlists():Array<String> {
		return [for (v in list) v.toLowerCase()];
	}

	inline public static function getFilePath(num:Null<Int> = null) {
		if(num == null) num = PlayState.storyDifficulty;

		var fileSuffix:String = list[num];
		if(fileSuffix != defaultDifficulty)
			fileSuffix = '-' + fileSuffix;
		else fileSuffix = '';

		return Paths.formatToSongPath(fileSuffix);
	}
	
	inline public static function resetList() {
		list = defaultList.copy();
	}

	inline public static function copyFrom(diffs:Array<String>) {
		list = diffs.copy();
	}

	inline public static function getString(num:Null<Int> = null):String {
		return list[num == null ? PlayState.storyDifficulty : num];
	}

	inline public static function getDefault():String {
		return defaultDifficulty;
	}
}