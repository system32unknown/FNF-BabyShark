package backend;

class EK {
	public static var colArray:Array<String> = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'];
	public static var colArrayAlt:Array<String> = ['purple', 'blue', 'green', 'red', 'white', 'yellow', 'violet', 'black', 'dark'];
	public static var pressArrayAlt:Array<String> = ['left', 'down', 'up', 'right', 'white', 'yellow', 'violet', 'black', 'dark'];

	public static var scales:Array<Float> = [0.7, 0.7, 0.7, 0.7, 0.65, 0.6, 0.55, 0.5, 0.46];
	public static var scalesPixel:Array<Float> = [1, 1, 1, 1, 0.93, 0.86, 0.79, 0.71, 0.66];
	public static var splashOffsetScale:Array<Float> = [1, 1, 1, 1, 1.08, 1.17, 1.27, 1.4, 1.52];
	public static var swidths:Array<Float> = [112, 112, 112, 112, 98, 84, 77, 70, 63];
	public static var posRest:Array<Int> = [-168, -112, -56, 0, 15, 35, 45, 55, 60];
	public static var gfxIndex:Array<Dynamic> = [
		[4],
		[0, 3],
		[0, 4, 3],
		[0, 1, 2, 3],
		[0, 1, 4, 2, 3],
		[0, 2, 3, 5, 1, 8],
		[0, 2, 3, 4, 5, 1, 8],
		[0, 1, 2, 3, 5, 6, 7, 8],
		[0, 1, 2, 3, 4, 5, 6, 7, 8]
	];
	public static var gfxHud:Array<Dynamic> = [
		[4],
		[0, 3],
		[0, 4, 3],
		[0, 1, 2, 3],
		[0, 1, 4, 2, 3],
		[0, 2, 3, 0, 1, 3],
		[0, 2, 3, 4, 0, 1, 3],
		[0, 1, 2, 3, 0, 1, 2, 3],
		[0, 1, 2, 3, 4, 0, 1, 2, 3]
	];
	public static var gfxDir:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT', 'SPACE'];
}