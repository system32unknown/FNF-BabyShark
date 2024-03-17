package backend;

class Rating {
	public var name:String = '';
	public var image:String = '';
	public var hitWindow:Null<Int> = 0; //ms
	public var ratingMod:Float = 1;
	public var score:Int = 500;
	public var noteSplash:Bool = true;
	public var hits:Int = 0;

	public function new(name:String) {
		this.name = name;
		this.image = name;
		this.hitWindow = 0;
		try {
			this.hitWindow = Reflect.field(ClientPrefs.data, window);
		} catch(e) FlxG.log.error(e);
	}

	public static function loadDefault():Array<Rating> {
		var ratingsData:Array<Rating> = [new Rating('epic')];
		var ratingNames:Array<String> = ['sick', 'good', 'ok', 'bad'];
		for (i => _rating in ratingNames) {
			var _:Rating = new Rating(_rating);
			_.ratingMod = .68 - (.68 * (i * .5));
			_.score = Math.floor(200 * Math.pow(.5, i));
			_.noteSplash = (_rating == 'sick');
			ratingsData.push(_);
		} 
		return ratingsData;
	}

	public static function GenerateLetterRank(accuracy:Float) { // generate a letter rankings
		var ranking:String = "N/A";
		final wifeConditions:Array<Dynamic> = [
			[accuracy >= 99.9935, "P"],
			[accuracy >= 99.980, "S+:"],
			[accuracy >= 99.970, "S+."],
			[accuracy >= 99.955, "S+"],
			[accuracy >= 99.90, "SS:"],
			[accuracy >= 99.80, "SS."],
			[accuracy >= 99.70, "SS"],
			[accuracy >= 99, "S:"],
			[accuracy >= 96.50, "S."],
			[accuracy >= 93, "S"],
			[accuracy >= 90, "A:"],
			[accuracy >= 85, "A."],
			[accuracy >= 80, "A"],
			[accuracy >= 70, "B"],
			[accuracy >= 60, "C"],
			[accuracy >= 50, "D"],
			[accuracy >= 20, "E"],
			[accuracy > 10, "F"],
		];

		for (i in 0...wifeConditions.length) {
			if (wifeConditions[i][0]) {
				ranking = wifeConditions[i][1];
				break;
			}
		}

		if (accuracy == 0) ranking = "N/A";
		return ranking;
	}
}