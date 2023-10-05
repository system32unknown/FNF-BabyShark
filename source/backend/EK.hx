package backend;

class EK {
	public static var scales:Array<Float> = [.9, .85, .8, .7, .66, .6, .55, .50, .46, .39, .36, .32, .31, .31, .3, .26, .26, .22];
	public static var pixelScales:Array<Float> = [1.2, 1.15, 1.1, 1, .9, .83, .8, .74, .7, .6, .55, .5, .48, .48, .42, .38, .38, .32];

	public static var defaultMania:Int = 3;
	public static var minMania:Int = 0;
	public static var maxMania:Int = 17;
	public static function keys(maniaVal:Int) {return maniaVal + 1;}
	public static function strums(maniaVal:Int) {return (maniaVal * 2) + 1;}
}