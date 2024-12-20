package backend;

import objects.NoteSplash;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.animation.FlxAnimationController;
import haxe.ds.IntMap;
import objects.Note;
class NoteLoader {
    public static var defaultNoteStuff:Array<Dynamic> = [];
	public static final defaultPath:String = 'noteSkins/NOTE_assets';
	public static var defaultSkin:String = 'noteSkins/NOTE_assets';
	public static var defaultNoteSprite:FlxSprite;

    public static var noteSkinFramesMap:Map<String, FlxFramesCollection> = new Map();
	public static var noteSkinAnimsMap:Map<String, FlxAnimationController> = new Map();
	public static var splashSkinFramesMap:Map<String, FlxFramesCollection> = new Map();
	public static var splashSkinAnimsMap:Map<String, FlxAnimationController> = new Map();

    static var splashFrames:FlxFramesCollection;
	static var splashAnimation:FlxAnimationController;

	//Function that initializes the first note. This way, we can recycle the notes
	public static function initDefaultSkin(?noteSkin:String, ?inEditor:Bool = false) {
        if (noteSkin.length > 0) defaultSkin = noteSkin;
        else if (ClientPrefs.data.noteSkin != 'Default') defaultSkin = 'noteSkins/NOTE_assets' + Note.getNoteSkinPostfix();
    }

    public static function initNote(noteSkin:String = "", mania:Int = 3) {
        var spr:FlxSprite = new FlxSprite();
        
        // Do this to be able to just copy over the note animations and not reallocate it
        if (noteSkin == null || noteSkin.length == 0) noteSkin = defaultSkin;
        spr.frames = Paths.getSparrowAtlas(noteSkin);
        trace('Initalizing noteSkin: $noteSkin');

        // Use a for loop for adding all of the animations in the note spritesheet, otherwise it won't find the animations for the next recycle
        for (d in 0...EK.keys(mania)) {
            if (EK.colArray[EK.gfxIndex[PlayState.mania][d]] == null) continue;
            var playAnim:String = EK.colArray[EK.gfxIndex[PlayState.mania][d]];
            var playAnimAlt:String = EK.colArrayAlt[EK.gfxIndex[PlayState.mania][d]];
    
            attemptToAddAnimationByPrefix(spr, 'Aholdend', 'pruple end hold');
            attemptToAddAnimationByPrefix(spr, playAnim + 'holdend', playAnim + ' tail0');
            attemptToAddAnimationByPrefix(spr, playAnim + 'hold', playAnim + ' hold0');
            attemptToAddAnimationByPrefix(spr, playAnim + 'holdend', playAnimAlt + ' hold end');
            attemptToAddAnimationByPrefix(spr, playAnim + 'hold', playAnimAlt + ' hold piece');
            spr.animation.addByPrefix(playAnim + 'holdend', playAnim + ' hold end');
            spr.animation.addByPrefix(playAnim + 'hold', playAnim + ' hold piece');
            attemptToAddAnimationByPrefix(spr, playAnim + 'Scroll', playAnimAlt + '0');
            spr.animation.addByPrefix(playAnim + 'Scroll', playAnim + '0');
        }

        noteSkinFramesMap.set(noteSkin, spr.frames);
        noteSkinAnimsMap.set(noteSkin, spr.animation);
    }

    static function attemptToAddAnimationByPrefix(spr:FlxSprite, name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true) {
		var animFrames:Array<flixel.graphics.frames.FlxFrame> = [];
		@:privateAccess
		spr.animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if(animFrames.length < 1) return;

		spr.animation.addByPrefix(name, prefix, framerate, doLoop);
	}

    public static function dispose():Void {
        noteSkinFramesMap.clear();
		noteSkinAnimsMap.clear();
		splashSkinFramesMap.clear();
		splashSkinAnimsMap.clear();
    }
}