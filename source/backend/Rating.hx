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
			this.hitWindow = Reflect.field(ClientPrefs.data, name + 'Window');
		} catch(e) FlxG.log.error(e);
	}

	public static function loadDefault():Array<Rating> {
		var ratingsData:Array<Rating> = [new Rating('epic')];

		var rating:Rating = new Rating('sick');
		rating.ratingMod = 1;
		rating.score = 350;
		rating.noteSplash = true;
		ratingsData.push(rating);

		var rating:Rating = new Rating('good');
		rating.ratingMod = .7;
		rating.score = 200;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('ok');
		rating.ratingMod = .4;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		ratingsData.push(rating);

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