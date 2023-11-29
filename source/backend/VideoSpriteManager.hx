package backend;
#if VIDEOS_ALLOWED 
#if (hxCodec >= "3.0.0") import hxcodec.flixel.FlxVideoSprite as VideoSprite;
#elseif (hxCodec >= "2.6.1") import hxcodec.VideoSprite;
#elseif (hxCodec == "2.6.0") import VideoSprite;
#else import vlc.MP4Sprite as VideoSprite; #end
#end

/*A class made to handle VideoSprite from diffrent hxCodec versions*/
class VideoSpriteManager extends VideoSprite {
    public function new(x:Float, y:Float) {
        super(x, y);
        PlayState.instance.videoSprites.push(this); //hopefully will put the VideoSprite var in the array
        this.setPlayBackRate(PlayState.instance.playbackRate);
    }
    #if VIDEOS_ALLOWED

    /**
	 * Native video support for Flixel & OpenFL
	 * @param Path Example: `your/video/here.mp4`
	 * @param Loop Loop the video.
	 */
    public function startVideo(path:String, loop:Bool = false) {
        this.play(path, loop);
    }

     /**
	 * Adds a function that is called when the Video ends.
	 * @param func Example: `function() { //code to run }`
	 */
    public function setFinishCallBack(func:Dynamic) {
        this.bitmap.onEndReached.add(() -> if(func != null) func(), true);
    }

     /**
	 * Adds a function which is called when the Codec is opend(video starts).
	 * @param func Example: `function() { //code to run }`
	 */
    public function setStartCallBack(func:Dynamic) {
        if(func != null)
        this.bitmap.onOpening.add(func, true);
    }

    override public function pause() {
        super.pause();
        if (FlxG.autoPause) {
            if (FlxG.signals.focusGained.has(this.bitmap.resume)) FlxG.signals.focusGained.remove(this.bitmap.resume);
            if (FlxG.signals.focusLost.has(this.bitmap.pause)) FlxG.signals.focusLost.remove(this.bitmap.pause);
        }
    }
    override public function resume() {
        super.resume();
        if (FlxG.autoPause) {
            FlxG.signals.focusGained.add(this.bitmap.resume);
            FlxG.signals.focusLost.add(this.bitmap.pause);
        }
    }

    public function setPlayBackRate(multi:Float) {
        this.bitmap.rate = multi;
    }
    #end
}