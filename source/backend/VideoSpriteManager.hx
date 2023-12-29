package backend;

#if VIDEOS_ALLOWED 
#if (hxCodec >= "3.0.0") import hxcodec.flixel.FlxVideoSprite as VideoSprite;
#elseif (hxCodec >= "2.6.1") import hxcodec.VideoSprite;
#elseif (hxCodec == "2.6.0") import VideoSprite;
#else import vlc.MP4Sprite as VideoSprite; #end
#end
import states.PlayState;
import haxe.extern.EitherType;
import flixel.util.FlxSignal;

#if VIDEOS_ALLOWED
class VideoSpriteManager extends VideoSprite {
    var onPlayState(get, never):Bool;
    public var playbackRate(get, set):EitherType<Single, Float>;
    public var paused(default, set):Bool = false;
    public var onVideoEnd:FlxSignal;
    public var onVideoStart:FlxSignal;

    public function new(x:Float, y:Float #if (hxCodec < "2.6.0"), width:Float = 1280, height:Float = 720, autoScale:Bool = true #end) {
        super(x, y #if (hxCodec < "2.6.0"), width, height, autoScale #end);
        if(onPlayState) PlayState.instance.videoSprites.push(this); 

        onVideoEnd = new FlxSignal();
        onVideoEnd.add(() -> {
            if(onPlayState && PlayState.instance.videoSprites.contains(this))
                PlayState.instance.videoSprites.remove(this); 
            destroy();
        });
        onVideoStart = new FlxSignal();
        #if (hxCodec >= "3.0.0")
        onVideoEnd.add(destroy);
        bitmap.onOpening.add(() -> onVideoStart.dispatch());
        bitmap.onEndReached.add(() -> onVideoEnd.dispatch());
        #else
        openingCallback = () -> onVideoStart.dispatch();
        finishCallback = () -> onVideoEnd.dispatch();
        #end
    }

    public function startVideo(path:String, loop:Bool = false) {
        #if (hxCodec >= "3.0.0")
        play(path, loop);
        #else
        playVideo(path, loop, false);
        #end
        if(onPlayState) playbackRate = PlayState.instance.playbackRate;
    }

    @:noCompletion
    function set_paused(shouldPause:Bool){
        #if (hxCodec >= "3.0.0")
        var parentResume = resume;
        var parentPause = pause;
        #else
        var parentResume = bitmap.resume;
        var parentPause = bitmap.pause;
        #end

        if(shouldPause) {
            #if (hxCodec >= "3.0.0")
            pause();
            #else
            bitmap.pause();
            #end

            if(FlxG.autoPause) {
                if(FlxG.signals.focusGained.has(parentResume)) FlxG.signals.focusGained.remove(parentResume);
                if(FlxG.signals.focusLost.has(parentPause)) FlxG.signals.focusLost.remove(parentPause);
            }
        } else {
            #if (hxCodec >= "3.0.0")
            resume();
            #else
            bitmap.resume();
            #end

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
        #if (hxCodec < "3.0.0")
        bitmap.finishCallback = null;
        bitmap.onEndReached();
        #end
    }
    #end
}