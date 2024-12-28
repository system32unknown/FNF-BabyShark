package backend;

import flixel.graphics.frames.FlxFramesCollection;
import flixel.animation.FlxAnimationController;
class NoteLoader {
	public static var defaultSkin:String = 'noteSkins/NOTE_assets';

    public static var noteSkinFramesMap:Map<String, FlxFramesCollection> = new Map<String, FlxFramesCollection>();
	public static var noteSkinAnimsMap:Map<String, FlxAnimationController> = new Map<String, FlxAnimationController>();

    public static function initNote(noteSkin:String = "") {
        var spr:FlxSprite = new FlxSprite();
        
        // Do this to be able to just copy over the note animations and not reallocate it
        if (noteSkin == null || noteSkin.length == 0) noteSkin = defaultSkin;
        spr.frames = Paths.getSparrowAtlas(noteSkin);
        trace('Initalizing noteSkin: $noteSkin');

        // Use a for loop for adding all of the animations in the note spritesheet, otherwise it won't find the animations for the next recycle
        for (d in 0...EK.keys(PlayState.mania)) {
            var gfx:Int = EK.gfxIndex[PlayState.mania][d];
            if (EK.colArray[gfx] == null) continue;
            var playAnim:String = EK.colArray[gfx];
            var playAnimAlt:String = EK.colArrayAlt[gfx];
    
            addByPrefixCheck(spr, 'Aholdend', 'pruple end hold');
            addByPrefixCheck(spr, playAnim + 'holdend', playAnim + ' tail0');
            addByPrefixCheck(spr, playAnim + 'hold', playAnim + ' hold0');
            addByPrefixCheck(spr, playAnim + 'holdend', playAnimAlt + ' hold end');
            addByPrefixCheck(spr, playAnim + 'hold', playAnimAlt + ' hold piece');
            spr.animation.addByPrefix(playAnim + 'holdend', playAnim + ' hold end');
            spr.animation.addByPrefix(playAnim + 'hold', playAnim + ' hold piece');
            addByPrefixCheck(spr, playAnim + 'Scroll', playAnimAlt + '0');
            spr.animation.addByPrefix(playAnim + 'Scroll', playAnim + '0');
        }
        noteSkinFramesMap.set(noteSkin, spr.frames);
        noteSkinAnimsMap.set(noteSkin, spr.animation);
    }

    static function addByPrefixCheck(spr:FlxSprite, name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true) {
		var animFrames:Array<flixel.graphics.frames.FlxFrame> = [];
		@:privateAccess
		spr.animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if(animFrames.length < 1) return;

		spr.animation.addByPrefix(name, prefix, framerate, doLoop);
	}

    public static function dispose():Void {
        noteSkinFramesMap.clear();
		noteSkinAnimsMap.clear();
    }
}