package backend;

/**
 * Represents a hit judgement (e.g. "sick", "good", "bad").
 *
 * Each judgement defines:
 * - A timing window (in ms)
 * - A score value
 * - A rating modifier (accuracy multiplier)
 * - Whether it should spawn a note splash
 */
@:structInit class Judgement {
	/**
	 * Internal name of the judgement (also used as image key). 
	 */
	public var name:String;

	/**
	 * Image identifier (usually same as name).
	 */
	public var image:String;

	/**
	 * Timing window in milliseconds.
	 */
	public var timing:Int;

	/**
	 * Accuracy multiplier.
	 */
	public var ratingMod:Float;

	/**
	 * Score granted for this judgement.
	 */
	public var score:Int;

	/**
	 * Whether this judgement spawns a note splash effect.
	 */
	public var noteSplash:Bool;

	/**
	 * Total hits recorded for this judgement.
	 */
	public var hits:Int = 0;

	/**
	 * Creates a new judgement definition.
	 *
	 * @param name        Judgement name (also used for image and timing window lookup).
	 * @param ratingMod   Accuracy multiplier.
	 * @param score       Score awarded.
	 * @param noteSplash  Whether a splash should appear.
	 */
	public function new(name:String = '', ratingMod:Float = 1, score:Int = 500, noteSplash:Bool = true) {
		this.name = image = name;
		this.ratingMod = ratingMod;
		this.score = score;
		this.noteSplash = noteSplash;

		try {
			timing = Reflect.field(Settings.data, name + 'Window');
		} catch (e:Dynamic) {
			FlxG.log.error(e);
			this.timing = 0; // fallback safe default
		}
	}

	/**
	 * Active judgement list used during gameplay.
	 */
	public static var list:Array<Judgement> = [];

	/**
	 * Loads default judgement definitions.
	 */
	public static function loadDefault():Array<Judgement> {
		final init_array:Array<Judgement> = [
			new Judgement('epic'),
			new Judgement('sick', 1, 350, true),
			new Judgement('good', .7, 200, false),
			new Judgement('ok', .4, 100, false),
			new Judgement('bad', 0, 50, false),
		];
		if (Settings.data.noEpic) init_array.shift();

		list = init_array;
		return init_array;
	}

	/**
	 * Worst judgement (largest timing window).
	 */
	public static var max(get, never):Judgement;
	static function get_max():Judgement return list[list.length - 1];
	/**
	 * Largest timing window value.
	 */
	public static var maxHitWindow(get, never):Float;
	static function get_maxHitWindow():Float return max.timing;

	/**
	 * Best judgement (smallest timing window).
	 */
	public static var min(get, never):Judgement;
	static function get_min():Judgement return list[0];
	/**
	 * Smallest timing window value.
	 */
	public static var minHitWindow(get, never):Float;
	static function get_minHitWindow():Float return min.timing;

	/**
	 * Returns the appropriate judgement based on hit difference.
	 *
	 * @param diff Time difference between note and input (in ms).
	 * @param bot  If true, always returns the best judgement.
	 */
	public static function getTiming(diff:Float = 0, bot:Bool = false):Judgement {
		if (list.length == 0) return null;
		if (bot) return min;
		for (judgement in list) if (Math.abs(diff) <= judgement.timing) return judgement;
		return max; // Fallback to worst judgement
	}

	/**
	 * Returns the index of the judgement corresponding to a timing deviation.
	 *
	 * @param noteDev Absolute timing deviation in milliseconds.
	 */
	public static function getIDFromTiming(noteDev:Float):Int {
		if (list.length == 0) return -1;
		for (i in 0...list.length) if (Math.abs(noteDev) <= list[i].timing) return i;
		return list.length - 1;
	}
}