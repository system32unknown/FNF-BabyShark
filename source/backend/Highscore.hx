package backend;

import flixel.util.FlxSave;

class Highscore {
	public static var weekScores:Map<String, Int> = new Map<String, Int>();
	public static var songScores:Map<String, Int> = new Map<String, Int>();
	public static var songRating:Map<String, Float> = new Map<String, Float>();
	public static var songCombos:Map<String, String> = new Map<String, String>();

	static var _save:FlxSave;

	public static function resetSong(song:String, diff:Int = 0):Void {
		var daSong:String = Song.format(song, diff);
		setScore(daSong, 0);
		setRating(daSong, 0);
		setCombo(daSong, '');
	}

	public static function resetWeek(week:String, diff:Int = 0):Void {
		setWeekScore(Song.format(week, diff), 0);
	}

	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0, ?rating:Float = -1):Void {
		if (song == null) return;
		var daSong:String = Song.format(song, diff);

		if (songScores.exists(daSong)) {
			if (songScores.get(daSong) < score) {
				setScore(daSong, score);
				if (rating >= 0) setRating(daSong, rating);
			}
		} else {
			setScore(daSong, score);
			if (rating >= 0) setRating(daSong, rating);
		}
	}

	public static function saveWeekScore(week:String, score:Int = 0, ?diff:Int = 0):Void {
		var daWeek:String = Song.format(week, diff);

		if (weekScores.exists(daWeek) && weekScores.get(daWeek) < score)
			setWeekScore(daWeek, score);
		else setWeekScore(daWeek, score);
	}

	public static function saveCombo(song:String, combo:String, ?diff:Int = 0):Void {
		if (song == null) return;
		var daSong:String = Song.format(song, diff);
		var finalCombo:String = combo;

		if (songCombos.exists(daSong) && getComboInt(songCombos.get(daSong)) < getComboInt(finalCombo))
			setCombo(daSong, finalCombo);
		else setCombo(daSong, finalCombo);
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH Song.format() BEFORE TOSSING IN SONG VARIABLE
	 */
	static function setScore(song:String, score:Int):Void {
		songScores.set(song, score);
		_save.data.songScores = songScores;
		_save.flush();
	}
	static function setCombo(song:String, combo:String):Void {
		songCombos.set(song, !Util.notBlank(combo) ? "Unclear, N/A" : combo);
		_save.data.songCombos = songCombos;
		_save.flush();
	}
	static function setWeekScore(week:String, score:Int):Void {
		weekScores.set(week, score);
		_save.data.weekScores = weekScores;
		_save.flush();
	}

	static function setRating(song:String, rating:Float):Void {
		songRating.set(song, rating);
		_save.data.songRating = songRating;
		_save.flush();
	}

	static function getComboInt(combo:String):Int {
		combo = combo.split(',')[0];
		for (i => item in ['Clear', 'SDCB', 'FC', 'GFC', 'SFC', 'PFC']) if (item == combo) return i + 1;
		return 0;
	}

	public static function getScore(song:String, diff:Int):Int {
		var daSong:String = Song.format(song, diff);
		if (!songScores.exists(daSong)) setScore(daSong, 0);
		return songScores.get(daSong);
	}
	public static function getCombo(song:String, diff:Int):String {
		var daSong:String = Song.format(song, diff);
		if (!songCombos.exists(daSong)) setCombo(daSong, '');
		return songCombos.get(daSong);
	}
	public static function getRating(song:String, diff:Int):Float {
		var daSong:String = Song.format(song, diff);
		if (!songRating.exists(daSong)) setRating(daSong, 0);
		return songRating.get(daSong);
	}

	public static function getWeekScore(week:String, diff:Int):Int {
		var daWeek:String = Song.format(week, diff);
		if (!weekScores.exists(daWeek)) setWeekScore(daWeek, 0);
		return weekScores.get(daWeek);
	}

	public static function load():Void {
		_save = new FlxSave();
		_save.bind('scores', Util.getSavePath());
		if (_save.data.weekScores != null) weekScores = _save.data.weekScores;
		if (_save.data.songScores != null) songScores = _save.data.songScores;
		if (_save.data.songRating != null) songRating = _save.data.songRating;
		if (_save.data.songCombos != null) songCombos = _save.data.songCombos;
	}

	public static function save():Void {
		_save.data.weekScores = weekScores;
		_save.data.songScores = songScores;
		_save.data.songRating = songRating;
		_save.data.songCombos = songCombos;
		_save.flush();
	}
}