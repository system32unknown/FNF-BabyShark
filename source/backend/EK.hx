package backend;

class EK {
	public static var defaultMania:Int = 3;
	public static var minMania:Int = 0;
	public static var maxMania:Int = 8;

	inline public static function keys(mania:Int) return mania + 1;
	inline public static function strums(mania:Int) return (mania * 2) + 1;

	public static var colArray:Array<String> = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'];
	public static var colArrayAlt:Array<String> = ['purple', 'blue', 'green', 'red', 'white', 'yellow', 'violet', 'black', 'dark'];
	public static var pressArrayAlt:Array<String> = ['left', 'down', 'up', 'right', 'white', 'yellow', 'violet', 'black', 'dark'];

	public static var scales:Array<Float> = [.7, .7, .7, .7, .65, .6, .55, .5, .46];
	public static var scalesPixel:Array<Float> = [1, 1, 1, 1, .93, .86, .79, .71, .66];
	public static var splashOffsetScale:Array<Float> = [1, 1, 1, 1, 1.08, 1.17, 1.27, 1.4, 1.52];
	public static var swidths:Array<Float> = [112, 112, 112, 112, 98, 84, 77, 70, 63];
	public static var posRest:Array<Int> = [-168, -112, -56, 0, 15, 35, 45, 55, 60];
	public static var gfxIndex:Array<Dynamic> = [
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
	public static var gfxHud:Array<Dynamic> = [
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

    public static function fillKeys():Array<Array<Dynamic>> {
        return [
			[
				ClientPrefs.keyBinds.get('note_1').copy()
			],[
				ClientPrefs.keyBinds.get('note_left').copy(),
				ClientPrefs.keyBinds.get('note_right').copy()
			], [
				ClientPrefs.keyBinds.get('note_left').copy(),
				ClientPrefs.keyBinds.get('note_3a').copy(),
				ClientPrefs.keyBinds.get('note_right').copy()
			], [
				ClientPrefs.keyBinds.get('note_left').copy(),
				ClientPrefs.keyBinds.get('note_down').copy(),
				ClientPrefs.keyBinds.get('note_up').copy(),
				ClientPrefs.keyBinds.get('note_right').copy()
			], [
				ClientPrefs.keyBinds.get('note_left').copy(),
				ClientPrefs.keyBinds.get('note_down').copy(),
				ClientPrefs.keyBinds.get('note_5a').copy(),
				ClientPrefs.keyBinds.get('note_up').copy(),
				ClientPrefs.keyBinds.get('note_right').copy()
			], [
				ClientPrefs.keyBinds.get('note_6a').copy(),
				ClientPrefs.keyBinds.get('note_6b').copy(),
				ClientPrefs.keyBinds.get('note_6c').copy(),
				ClientPrefs.keyBinds.get('note_6d').copy(),
				ClientPrefs.keyBinds.get('note_6e').copy(),
				ClientPrefs.keyBinds.get('note_6f').copy()
			], [
				ClientPrefs.keyBinds.get('note_7a').copy(),
				ClientPrefs.keyBinds.get('note_7b').copy(),
				ClientPrefs.keyBinds.get('note_7c').copy(),
				ClientPrefs.keyBinds.get('note_7d').copy(),
				ClientPrefs.keyBinds.get('note_7e').copy(),
				ClientPrefs.keyBinds.get('note_7f').copy(),
				ClientPrefs.keyBinds.get('note_7g').copy()
			], [
				ClientPrefs.keyBinds.get('note_8a').copy(),
				ClientPrefs.keyBinds.get('note_8b').copy(),
				ClientPrefs.keyBinds.get('note_8c').copy(),
				ClientPrefs.keyBinds.get('note_8d').copy(),
				ClientPrefs.keyBinds.get('note_8e').copy(),
				ClientPrefs.keyBinds.get('note_8f').copy(),
				ClientPrefs.keyBinds.get('note_8g').copy(),
				ClientPrefs.keyBinds.get('note_8h').copy()
			], [
				ClientPrefs.keyBinds.get('note_9a').copy(),
				ClientPrefs.keyBinds.get('note_9b').copy(),
				ClientPrefs.keyBinds.get('note_9c').copy(),
				ClientPrefs.keyBinds.get('note_9d').copy(),
				ClientPrefs.keyBinds.get('note_9e').copy(),
				ClientPrefs.keyBinds.get('note_9f').copy(),
				ClientPrefs.keyBinds.get('note_9g').copy(),
				ClientPrefs.keyBinds.get('note_9h').copy(),
				ClientPrefs.keyBinds.get('note_9i').copy()
			]
		];
    }
}