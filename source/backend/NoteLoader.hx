package backend;

class NoteLoader {
	static inline var DEFAULT_SKIN:String = 'noteSkins/NOTE_assets';

	public static var noteSkinFramesMap:Map<String, flixel.graphics.frames.FlxFramesCollection> = [];
	public static var noteSkinAnimsMap:Map<String, flixel.animation.FlxAnimationController> = [];

	public static function initNote(noteSkin:String = null) {
		if (noteSkin == null || noteSkin.length == 0) noteSkin = DEFAULT_SKIN;
		if (noteSkinFramesMap.exists(noteSkin)) return;

		trace('Initializing noteSkin: $noteSkin');

		var spr:FlxSprite = new FlxSprite();
		spr.frames = Paths.getSparrowAtlas(noteSkin);
		initAnimations(spr);

		noteSkinFramesMap.set(noteSkin, spr.frames);
		noteSkinAnimsMap.set(noteSkin, spr.animation);
	}

	static function initAnimations(spr:FlxSprite):Void {
		for (d in 0...EK.keys(PlayState.mania)) {
			var gfx:Int = EK.gfxIndex[PlayState.mania][d];
			var anim:String = EK.colArray[gfx];
			var animAlt:String = EK.colArrayAlt[gfx];

			if (anim == null) continue;

			addAnimSafe(spr, 'Aholdend', 'pruple end hold');

			addAnimSafe(spr, anim + 'holdend', anim + ' tail0');
			addAnimSafe(spr, anim + 'hold', anim + ' hold0');

			addAnimSafe(spr, anim + 'holdend', animAlt + ' hold end');
			addAnimSafe(spr, anim + 'hold', animAlt + ' hold piece');

			addAnimSafe(spr, anim + 'holdend', anim + ' hold end');
			addAnimSafe(spr, anim + 'hold', anim + ' hold piece');

			addAnimSafe(spr, anim + 'Scroll', animAlt + '0');
			addAnimSafe(spr, anim + 'Scroll', anim + '0');
		}
	}

	static function addAnimSafe(spr:FlxSprite, name:String, prefix:String, framerate:Float = 24, loop:Bool = true):Void {
		if (spr.animation.getByName(name) != null) return;

		var frames:Array<flixel.graphics.frames.FlxFrame> = [];
		@:privateAccess
		spr.animation.findByPrefix(frames, prefix);
		if (frames.length == 0) return;

		spr.animation.addByPrefix(name, prefix, framerate, loop);
	}

	public static function dispose():Void {
		noteSkinFramesMap.clear();
		noteSkinAnimsMap.clear();
	}
}