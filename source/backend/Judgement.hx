package backend;

@:structInit class Judgement {
	public var name:String;
	public var image:String;
	public var timing:Int;
	public var ratingMod:Float;
	public var score:Int;

	public var noteSplash:Bool;
	public var hits:Int = 0;

	public function new(name:String = '', ratingMod:Float = 1, score:Int = 500, noteSplash:Bool = true) {
		this.name = image = name;
		try {
			timing = Reflect.field(ClientPrefs.data, name + 'Window');
		} catch(e) FlxG.log.error(e);
		this.ratingMod = ratingMod;
		this.score = score;
		this.noteSplash = noteSplash;
	}

	public static var list:Array<Judgement> = [
		new Judgement('epic'),
		new Judgement('sick', 1, 350, true),
		new Judgement('good', .7, 200, false),
		new Judgement('ok', .4, 100, false),
		new Judgement('bad', 0, 50, false),
	];

	public static var max(get, never):Judgement;
	static function get_max():Judgement return list[list.length - 1];
	public static var maxHitWindow(get, never):Float;
	static function get_maxHitWindow():Float return max.timing;

	public static var min(get, never):Judgement;
	static function get_min():Judgement return list[0];
	public static var minHitWindow(get, never):Float;
	static function get_minHitWindow():Float return min.timing;

	public static function getTiming(diff:Float = 0, bot:Bool = false):Judgement {
		var value:Judgement = max;
		if (bot) value = min
		else {
			for (i in 0...list.length - 1) {
				if (diff <= list[i].timing) {
					value = list[i]; //skips last window (Shit)
					break;
				}
			}
		}
		return value;
	}
	public static function getIDFromTiming(noteDev:Float):Int {
		var value:Int = list.length - 1;
		for (i in 0...list.length) {
			if (Math.abs(noteDev) >= list[i].timing) continue;
			value = i;
			break;
		}
		return value;
	}
}