package backend;

import haxe.extern.EitherType;
import flixel.util.FlxSignal;

#if VIDEOS_ALLOWED
class VideoManager extends hxvlc.flixel.FlxVideo {
    public var playbackRate(get, set):EitherType<Single, Float>;
    public var paused(default, set):Bool = false;
    public var onVideoEnd:FlxSignal;
    public var onVideoStart:FlxSignal;

    public function new(autoDispose:Bool = true, ?smoothing:Bool = true) {
        super();
        onVideoEnd = new FlxSignal();
        onVideoStart = new FlxSignal();    

        if(autoDispose) onEndReached.add(() -> dispose(), true);

        onOpening.add(onVideoStart.dispatch);
        onEndReached.add(onVideoEnd.dispatch);
    }

    public function startVideo(path:String, ?args:Array<String>) {
        if (load(path, args)) play();
    }

    @:noCompletion
    function set_paused(shouldPause:Bool) {
        if(shouldPause) {
            pause();
            if(FlxG.autoPause) {
                if(FlxG.signals.focusGained.has(pause)) FlxG.signals.focusGained.remove(pause);
                if(FlxG.signals.focusLost.has(resume)) FlxG.signals.focusLost.remove(resume);
            }
        } else {
            resume();
            if(FlxG.autoPause) {
                FlxG.signals.focusGained.add(pause);
                FlxG.signals.focusLost.add(resume);
            }
        }
        return shouldPause;
    }

    @:noCompletion function set_playbackRate(multi:EitherType<Single, Float>) return rate = multi;
    @:noCompletion function get_playbackRate():Float return rate;
    #end
}