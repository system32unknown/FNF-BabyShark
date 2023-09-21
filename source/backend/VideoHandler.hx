package backend;

#if VIDEOS_ALLOWED 
#if (hxCodec >= "3.0.0") import hxcodec.flixel.FlxVideo as BaseVideoHandler;
#elseif (hxCodec >= "2.6.1") import hxcodec.VideoHandler as BaseVideoHandler;
#elseif (hxCodec == "2.6.0") import VideoHandler as BaseVideoHandler;
#else import vlc.MP4Handler as BaseVideoHandler; #end
#end

/*A class made to handle Video functions from diffrent hxCodec versions*/
class VideoHandler extends BaseVideoHandler {
    public function new() {super();}
    #if VIDEOS_ALLOWED
    /**
	 * Native video support for Flixel & OpenFL
	 * @param Path Example: `your/video/here.mp4`
	 * @param Loop Loop the video.
	 */
    public function startVideo(path:String, loop:Bool = false) {
        super.play(path, loop);
    }

    /**
	 * Adds a function that is called when the Video ends.
	 * @param func Example: `function() {//code to run}`
	 */
    public function setFinishCallBack(func:Dynamic) {
        super.onEndReached.add(() -> {
            dispose();
            if(func != null) func();
        }, true);
    }

    /**
	 * Adds a function which is called when the Codec is opend(video starts).
	 * @param func Example: `function() {//code to run}`
	 */
    public function setStartCallBack(func:Dynamic) {
        if(func != null)
        super.onOpening.add(func, true);
    }

    //if you want do smth such as pausing the video just do this -> yourVideo.pause();, , same thing for resume but call resume(); instead
    #end
}