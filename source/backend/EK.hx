package backend;

class EK {
	public static var defaultMania:Int = 3;
	public static var minMania:Int = 0;
	public static var maxMania:Int = 17;
	public static function keys(maniaVal:Int) {
		return maniaVal + 1;
	}
	public static function strums(maniaVal:Int) {
		return (maniaVal * 2) + 1;
	}
}