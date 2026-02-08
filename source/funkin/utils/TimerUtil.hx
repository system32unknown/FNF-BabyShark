package funkin.utils;

/**
 * A data structure representing a sequence event.
 */
typedef SequenceEvent = {
	/**
	 * The time in seconds to wait before triggering the event.
	 */
	time:Float,

	/**
	 * The callback to run when the event is triggered.
	 */
	callback:() -> Void
};

/**
 * A timer-based event sequence.
 */
@:nullSafety
class Sequence {
	/**
	 * Create a new sequence.
	 * @param events A list of `SequenceEvent`s.
	 * @param mult Optional multiplier for callback times. Useful for frame-based or music-based timing.
	 * @param start Whether to immediately start the sequence.
	 */
	public function new(events:Array<SequenceEvent>, mult:Float = 1, start:Bool = true):Void {
		if (events.length == 0) return;

		mult = Math.max(0, mult);

		for (event in events) {
			timers.push(new FlxTimer().start(event.time * mult, (timer:FlxTimer) -> {
				event.callback();
				timers.remove(timer);
			}));
		}

		running = start;
	}

	/**
	 * The list of uncompleted timers for their respective events.
	 */
	final timers:Array<FlxTimer> = [];

	/**
	 * Controls whether this sequence is running or not.
	 */
	public var running(get, set):Bool;

	var _running:Bool = false;

	function get_running():Bool {
		return completed ? false : _running;
	}

	function set_running(v:Bool):Bool {
		if (completed) return false;
		for (timer in timers) timer.active = v;
		_running = v;
		return _running;
	}

	/**
	 * Whether this sequence has completed.
	 */
	public var completed(get, never):Bool;
	function get_completed():Bool {
		return timers.length == 0;
	}

	/**
	 * Clean up and destroy this sequence.
	 */
	public function destroy():Void {
		while (!completed) {
			var timer:Null<FlxTimer> = timers.pop();
			timer?.cancel();
			timer?.destroy();
		}
	}
}