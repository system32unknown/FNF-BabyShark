package backend;

class Highscore {
	public static var weekScores:Map<String, Int> = new Map();
	public static var songScores:Map<String, Int> = new Map<String, Int>();
	public static var songRating:Map<String, Float> = new Map<String, Float>();
	public static var songCombos:Map<String, String> = new Map<String, String>();

	public static function resetSong(song:String, diff:Int = 0):Void {
		var daSong:String = formatSong(song, diff);
		setScore(daSong, 0);
		setRating(daSong, 0);
		setCombo(daSong, '');
	}

	public static function resetWeek(week:String, diff:Int = 0):Void {
		setWeekScore(formatSong(week, diff), 0);
	}

	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0, ?rating:Float = -1):Void {
		var daSong:String = formatSong(song, diff);

		if (songScores.exists(daSong)) {
			if (songScores.get(daSong) < score) {
				setScore(daSong, score);
				if(rating >= 0) setRating(daSong, rating);
			}
		} else {
			setScore(daSong, score);
			if(rating >= 0) setRating(daSong, rating);
		}
	}

	public static function saveWeekScore(week:String, score:Int = 0, ?diff:Int = 0):Void {
		var daWeek:String = formatSong(week, diff);

		if (weekScores.exists(daWeek))
			if (weekScores.get(daWeek) < score) setWeekScore(daWeek, score);
		else setWeekScore(daWeek, score);
	}

	public static function saveCombo(song:String, combo:String, ?diff:Int = 0):Void {
		var daSong:String = formatSong(song, diff);
		var finalCombo:String = combo;

		if (songCombos.exists(daSong)) {
			if (getComboInt(songCombos.get(daSong)) < getComboInt(finalCombo))
				setCombo(daSong, finalCombo);
		} else setCombo(daSong, finalCombo);
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	static function setScore(song:String, score:Int):Void {
		songScores.set(song, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}
	static function setCombo(song:String, combo:String):Void {
		songCombos.set(song, checkIfEmpty(combo) ? "Unclear, N/A" : combo);
		FlxG.save.data.songCombos = songCombos;
		FlxG.save.flush();
	}
	static function setWeekScore(week:String, score:Int):Void {
		weekScores.set(week, score);
		FlxG.save.data.weekScores = weekScores;
		FlxG.save.flush();
	}

	static function setRating(song:String, rating:Float):Void {
		songRating.set(song, rating);
		FlxG.save.data.songRating = songRating;
		FlxG.save.flush();
	}

	public static function formatSong(song:String, diff:Int):String {
		return Paths.formatToSongPath(song) + Difficulty.getFilePath(diff);
	}

	static function getComboInt(combo:String):Int {
		combo = combo.split(',')[0];
		final ratings:Array<String> = ['Clear', 'SDCB', 'FC', 'GFC', 'SFC', 'PFC'];
		for (i => item in ratings) if (item == combo) return i + 1;
		return 0;
	}

	public static function getScore(song:String, diff:Int):Int {
		var daSong:String = formatSong(song, diff);
		if (!songScores.exists(daSong)) setScore(daSong, 0);
		return songScores.get(daSong);
	}
	public static function getCombo(song:String, diff:Int):String {
		var daSong:String = formatSong(song, diff);
		if (!songCombos.exists(daSong)) setCombo(daSong, '');
		return songCombos.get(daSong);
	}
	public static function getRating(song:String, diff:Int):Float {
		var daSong:String = formatSong(song, diff);
		if (!songRating.exists(daSong)) setRating(daSong, 0);
		return songRating.get(daSong);
	}

	public static function getWeekScore(week:String, diff:Int):Int {
		var daWeek:String = formatSong(week, diff);
		if (!weekScores.exists(daWeek)) setWeekScore(daWeek, 0);
		return weekScores.get(daWeek);
	}

	public static function load():Void {
		if (FlxG.save.data.weekScores != null) weekScores = FlxG.save.data.weekScores;
		if (FlxG.save.data.songScores != null) songScores = FlxG.save.data.songScores;
		if (FlxG.save.data.songRating != null) songRating = FlxG.save.data.songRating;
		if (FlxG.save.data.songCombos != null) songCombos = FlxG.save.data.songCombos;
	}

	inline static function checkIfEmpty(s:String):Bool {
		return s == null || s.length == 0 || s == '';
	}
}