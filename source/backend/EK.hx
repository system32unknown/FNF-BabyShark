package backend;

class EK {
	public static var scales:Array<Float> = [.9, .85, .8, .7, .66, .6, .55, .50, .46, .39, .36, .32, .31, .31, .3, .26, .26, .22];
    public static var offsetX:Array<Float> = [150, 89, 45, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    public static var restPosition:Array<Float> = [0, -5, 0, 0, 16, 23, 25, 25, 24, 17, 16, 12, 15, 18, 19, 13, 14, 10];
    public static var gridSizes:Array<Int> = [40, 40, 40, 40, 40, 40, 40, 40, 40, 35, 30, 25, 25, 20, 20, 20, 20, 15];
    public static var splashScales:Array<Float> = [1.3, 1.2, 1.1, 1, 1, .9, .8, .7, .6, .5, .4, .3, .3, .3, .2, .18, .18, .15];
	public static var xmlMax:Int = 17; // This specifies the max of the splashes can go

	public static var defaultMania:Int = 3;
	public static var minMania:Int = 0;
	public static var maxMania:Int = 17;
	public static function keys(maniaVal:Int) return maniaVal + 1;
	public static function strums(maniaVal:Int) return (maniaVal * 2) + 1;
}