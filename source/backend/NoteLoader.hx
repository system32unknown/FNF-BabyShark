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

		SpriteUtil.addAnimSafe(spr, 'purpleholdend', 'pruple end hold');
		for (i in 0...4) {
			var anim:String = objects.Note.colArray[i];

			SpriteUtil.addAnimSafe(spr, anim + 'holdend', anim + ' hold end');
			SpriteUtil.addAnimSafe(spr, anim + 'hold', anim + ' hold piece');
			SpriteUtil.addAnimSafe(spr, anim + 'Scroll', anim + '0');
		}

		noteSkinFramesMap.set(noteSkin, spr.frames);
		noteSkinAnimsMap.set(noteSkin, spr.animation);
	}

	public static function dispose():Void {
		noteSkinFramesMap.clear();
		noteSkinAnimsMap.clear();
	}
}