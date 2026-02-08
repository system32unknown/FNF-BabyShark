package funkin.backend;

class EK {
	public static var defaultMania:Int = 3;
	public static var minMania:Int = 0;
	public static var maxMania:Int = 8;

	inline public static function keys(mania:Int):Int return mania + 1;
	inline public static function strums(mania:Int):Int return (mania + 1) * 2;

	public static var colArray:Array<String> = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'];
	public static var colArrayAlt:Array<String> = ['purple', 'blue', 'green', 'red', 'white', 'yellow', 'violet', 'black', 'dark'];
	public static var pressArrayAlt:Array<String> = ['left', 'down', 'up', 'right', 'white', 'yellow', 'violet', 'black', 'dark'];

	public static var scales:Array<Float> = [.7, .7, .7, .7, .65, .6, .55, .5, .46];
	public static var scalesPixel:Array<Float> = [1, 1, 1, 1, .93, .86, .79, .71, .66];
	public static var swidths:Array<Float> = [112, 112, 112, 112, 98, 84, 77, 70, 63];
	public static var posRest:Array<Int> = [-168, -112, -56, 0, 15, 35, 45, 55, 60];
	public static var midArray:Array<Int> = [0, 0, 1, 1, 2, 2, 3, 3, 4];

	public static var gfxIndex:Array<Array<Int>> = [
		[4],
		[0, 3],
		[0, 4, 3],
		[for (i in 0...4) i],
		[0, 1, 4, 2, 3],
		[0, 2, 3, 5, 1, 8],
		[0, 2, 3, 4, 5, 1, 8],
		[0, 1, 2, 3, 5, 6, 7, 8],
		[for (i in 0...9) i]
	];
	public static var gfxHud:Array<Array<Int>> = [
		[4],
		[0, 3],
		[0, 4, 3],
		[for (i in 0...4) i],
		[0, 1, 4, 2, 3],
		[0, 2, 3, 0, 1, 3],
		[0, 2, 3, 4, 0, 1, 3],
		[0, 1, 2, 3, 0, 1, 2, 3],
		[0, 1, 2, 3, 4, 0, 1, 2, 3]
	];
	public static var gfxDir:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT', 'SPACE'];

	public static function fillKeys():Array<Array<String>> {
		return [
			['note_1'],
			['note_left', 'note_right'],
			['note_left', 'note_3a', 'note_right'],
			['note_left', 'note_down', 'note_up', 'note_right'],
			['note_left', 'note_down', 'note_5a', 'note_up', 'note_right'],
			['note_6a', 'note_6b', 'note_6c', 'note_6d', 'note_6e', 'note_6f'],
			['note_7a', 'note_7b', 'note_7c', 'note_7d', 'note_7e', 'note_7f', 'note_7g'],
			['note_8a', 'note_8b', 'note_8c', 'note_8d', 'note_8e', 'note_8f', 'note_8g', 'note_8h'], ['note_9a', 'note_9b', 'note_9c', 'note_9d', 'note_9e', 'note_9f', 'note_9g', 'note_9h', 'note_9i']
		];
	}
}