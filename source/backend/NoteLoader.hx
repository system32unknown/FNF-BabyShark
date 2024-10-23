package backend;

import flixel.graphics.frames.FlxFramesCollection;
import flixel.animation.FlxAnimationController;
import objects.Note;

class NoteLoader {
	public static var defaultNoteSprite:FlxSprite;

	public static var noteSkinFramesMap:Map<String, FlxFramesCollection> = new Map();
	public static var noteSkinAnimsMap:Map<String, FlxAnimationController> = new Map();

	public static function initNote(keys:Int = 4, noteSkin:String) {
		var spr:FlxSprite = new FlxSprite();
		spr.frames = Paths.getSparrowAtlas(noteSkin);

		// Use a for loop for adding all of the animations in the note spritesheet, otherwise it won't find the animations for the next recycle
		for (d in 0...keys) {
            var playAnim:String = EK.colArray[EK.gfxIndex[PlayState.mania][d]];
            var playAnimAlt:String = EK.colArrayAlt[EK.gfxIndex[PlayState.mania][d]];

			checkAnimPrefix(spr.animation, 'Aholdend', 'pruple end hold', 24, true);
			checkAnimPrefix(spr.animation, playAnim + 'holdend', playAnim + ' tail0', 24, true);
			checkAnimPrefix(spr.animation, playAnim + 'hold', playAnim + ' hold0', 24, true);
			checkAnimPrefix(spr.animation, playAnim + 'holdend', playAnimAlt + ' hold end', 24, true);
			checkAnimPrefix(spr.animation, playAnim + 'hold', playAnimAlt + ' hold piece', 24, true);
			spr.animation.addByPrefix(playAnim + 'holdend', playAnim + ' hold end', 24, true);
			spr.animation.addByPrefix(playAnim + 'hold', playAnim + ' hold piece', 24, true);
		}
		noteSkinFramesMap.set(noteSkin, spr.frames);
		noteSkinAnimsMap.set(noteSkin, spr.animation);
	}

	function checkAnimPrefix(anim:FlxAnimationController, name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true) {
		var animFrames:Array<flixel.graphics.frames.FlxFrame> = [];
		@:privateAccess
		anim.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if(animFrames.length < 1) return;

		anim.addByPrefix(name, prefix, framerate, doLoop);
	}
}
