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

		var window:String = name + 'Window';
		try {
			this.hitWindow = ClientPrefs.getPref(window);
		} catch(e) FlxG.log.error(e);
	}

	public static function loadDefault():Array<Rating> {
		//Ratings
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

		var rating:Rating = new Rating('bad');
		rating.ratingMod = .4;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);
		
		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		ratingsData.push(rating);

		return ratingsData;
	}
}