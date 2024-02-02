package backend;

import haxe.extern.EitherType;
import flixel.util.FlxSignal;

#if VIDEOS_ALLOWED
class VideoSpriteManager extends hxvlc.flixel.FlxVideoSprite {
    var onPlayState(get, never):Bool;
    public var playbackRate(get, set):EitherType<Single, Float>;
    public var paused(default, set):Bool = false;
    public var onVideoEnd:FlxSignal;
    public var onVideoStart:FlxSignal;

    public function new(x:Int, y:Int) {
        super(x, y);
        if(onPlayState) PlayState.instance.videoSprites.push(this); 

        onVideoEnd = new FlxSignal();
        onVideoEnd.add(() -> {
            if(onPlayState && PlayState.instance.videoSprites.contains(this))
                PlayState.instance.videoSprites.remove(this); 
            destroy();
        });
        onVideoStart = new FlxSignal();
        onVideoEnd.add(destroy);
        bitmap.onOpening.add(() -> onVideoStart.dispatch());
        bitmap.onEndReached.add(() -> onVideoEnd.dispatch());
    }

    public function startVideo(path:String, ?args:Array<String>) {
        if (load(path, args)) play();
        if (onPlayState) playbackRate = PlayState.instance.playbackRate;
    }

    @:noCompletion
    function set_paused(shouldPause:Bool){
        var parentResume = resume;
        var parentPause = pause;

        if(shouldPause) {
            pause();

            if(FlxG.autoPause) {
                if(FlxG.signals.focusGained.has(parentResume)) FlxG.signals.focusGained.remove(parentResume);
                if(FlxG.signals.focusLost.has(parentPause)) FlxG.signals.focusLost.remove(parentPause);
            }
        } else {
            resume();

            if(FlxG.autoPause) {
                FlxG.signals.focusGained.add(parentResume);
                FlxG.signals.focusLost.add(parentPause);
            }
        }
        return shouldPause;
    }

    @:noCompletion function set_playbackRate(multi:EitherType<Single, Float>) return bitmap.rate = multi;
    @:noCompletion function get_playbackRate():Float return bitmap.rate;
    @:noCompletion function get_onPlayState():Bool return Std.isOfType(MusicBeatState.getState(), PlayState);

    public function altDestroy() {
        super.destroy();
        bitmap.dispose();
    }
    #end
}