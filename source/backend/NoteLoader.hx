package backend;

import utils.SpriteUtil;

class NoteLoader {
	static inline var DEFAULT_SKIN:String = 'noteSkins/NOTE_assets';

	public static var noteSkinFramesMap:Map<String, flixel.graphics.frames.FlxFramesCollection> = [];
	public static var noteSkinAnimsMap:Map<String, flixel.animation.FlxAnimationController> = [];

	public static function initNote(noteSkin:String = null):Void {
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

			SpriteUtil.addAnimSafe(spr, 'Aholdend', 'pruple end hold');

			SpriteUtil.addAnimSafe(spr, anim + 'holdend', anim + ' tail0');
			SpriteUtil.addAnimSafe(spr, anim + 'hold', anim + ' hold0');

			SpriteUtil.addAnimSafe(spr, anim + 'holdend', animAlt + ' hold end');
			SpriteUtil.addAnimSafe(spr, anim + 'hold', animAlt + ' hold piece');

			SpriteUtil.addAnimSafe(spr, anim + 'holdend', anim + ' hold end');
			SpriteUtil.addAnimSafe(spr, anim + 'hold', anim + ' hold piece');

			SpriteUtil.addAnimSafe(spr, anim + 'Scroll', animAlt + '0');
			SpriteUtil.addAnimSafe(spr, anim + 'Scroll', anim + '0');
		}
	}

	public static function dispose():Void {
		noteSkinFramesMap.clear();
		noteSkinAnimsMap.clear();
	}
}