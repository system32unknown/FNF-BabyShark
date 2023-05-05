package lime.media;

import lime.app.Event;
import lime.math.Vector4;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class AudioSource {
	public var onComplete = new Event<Void->Void>();
	public var onLoop = new Event<Void->Void>();
	public var buffer:AudioBuffer;
	public var playing(get, null):Bool;
	public var currentTime(get, set):Float;
	public var gain(get, set):Float;
	public var length(get, set):Float;
	public var loops(get, set):Int;
	public var loopTime(get, set):Float;
	public var pitch(get, set):Float;
	public var offset:Float;
	public var position(get, set):Vector4;

	@:noCompletion private var __backend:AudioSourceBackend;

	public function new(buffer:AudioBuffer = null, offset:Float = 0, length:Null<Float> = null, loops:Int = 0) {
		this.buffer = buffer;
		this.offset = offset;

		__backend = new AudioSourceBackend(this);

		if (length != null && length != 0) this.length = length;
		this.loops = loops;

		if (buffer != null) init();
	}

	@:noCompletion inline public function dispose():Void
		__backend.dispose();

	@:noCompletion inline function init():Void
		__backend.init();

	@:noCompletion inline public function play():Void
		__backend.play();

	@:noCompletion inline public function pause():Void
		__backend.pause();

	@:noCompletion inline public function stop():Void
		__backend.stop();

	// Get & Set Methods
	@:noCompletion inline function get_playing():Bool
		@:privateAccess return __backend.playing;

	@:noCompletion inline function get_currentTime():Float
		return __backend.getCurrentTime();

	@:noCompletion inline function set_currentTime(value:Float):Float
		return __backend.setCurrentTime(value);

	@:noCompletion inline function get_gain():Float
		return __backend.getGain();

	@:noCompletion inline function set_gain(value:Float):Float
		return __backend.setGain(value);

	@:noCompletion inline function get_length():Float
		return __backend.getLength();

	@:noCompletion inline function set_length(value:Float):Float
		return __backend.setLength(value);

	@:noCompletion inline function get_loops():Int
		return __backend.getLoops();

	@:noCompletion inline function set_loops(value:Int):Int
		return __backend.setLoops(value);

	@:noCompletion inline function get_loopTime():Float
		return __backend.getLoopTime();

	@:noCompletion inline function set_loopTime(value:Float):Float
		return __backend.setLoopTime(value);

	@:noCompletion inline function get_pitch():Float
		return __backend.getPitch();

	@:noCompletion inline function set_pitch(value:Float):Float
		return __backend.setPitch(Math.max(0, value));

	@:noCompletion inline function get_position():Vector4
		return __backend.getPosition();

	@:noCompletion inline function set_position(value:Vector4):Vector4
		return __backend.setPosition(value);
}

@:noCompletion typedef AudioSourceBackend = lime._internal.backend.native.NativeAudioSource;