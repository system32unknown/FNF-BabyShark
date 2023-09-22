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
        states.PlayState.instance.videoSprites.push(this); //hopefully will put the VideoSprite var in the array
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
        this.bitmap.onEndReached.add(function() {
            if(func != null) func();
        }, true);
    }

     /**
	 * Adds a function which is called when the Codec is opend(video starts).
	 * @param func Example: `function() { //code to run }`
	 */
    public function setStartCallBack(func:Dynamic) {
        if(func != null)
        this.bitmap.onOpening.add(func, true);
    }
    /*if you want do smth such as pausing the video just do this -> yourVideo.bitmap.pause();
     same thing for resume but call resume(); instead*/
    #end
}