package backend;

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
	 * @param autoDestroy Whether to destroy this sequence after its completion.
	 */
	public function new(events:Array<SequenceEvent>, mult:Float = 1, start:Bool = true, autoDestroy:Bool = true) {
		this.events = events.copy();

		if (this.events.length == 0) return;

		this.multiplier = Math.max(0, mult);
		this.autoDestroy = autoDestroy;

		this.events.sort((a:SequenceEvent, b:SequenceEvent) -> {
			// Providing a negative time should make it positive to mimic how FlxTimers work.
			a.time = Math.abs(a.time);
			b.time = Math.abs(b.time);
			return Reflect.compare(a.time, b.time);
		});

		timer.start(currentEvent.time * multiplier, _ -> {
			currentEvent.callback();
			eventCount++;

			if (!completed) timer.reset((currentEvent.time - events[eventCount - 1].time) * multiplier);
			else if (this.autoDestroy) destroy();
		});

		running = start;
	}

	/**
	 * The internal timer used by this sequence.
	 */
	final timer:FlxTimer = new FlxTimer();

	/**
	 * A multiplier for callback times. Useful for frame-based or music-based timing.
	 */
	public var multiplier:Float;

	/**
	 * The current event being executed. Will be null if this sequence has finished.
	 */
	public var currentEvent(get, never):Null<SequenceEvent>;
	inline function get_currentEvent():Null<SequenceEvent> {
		return events[eventCount];
	}

	/**
	 * The events for this sequence.
	 */
	var events:Array<SequenceEvent>;

	/**
	 * The amount of currently finished events.
	 */
	var eventCount:Int = 0;

	/**
	 * Controls whether this sequence is running or not.
	 */
	public var running(get, set):Bool;

	function get_running():Bool {
		return completed ? false : (timer.active && !timer.finished);
	}

	function set_running(v:Bool):Bool {
		if (completed) return false;
		return timer.active = v;
	}

	/**
	 * Whether this sequence has completed.
	 */
	public var completed(get, never):Bool;
	function get_completed():Bool {
		return eventCount >= events.length;
	}

	/**
	 * Whether this sequence should be destroyed after completing.
	 */
	public var autoDestroy:Bool;

	/**
	 * Starts the sequence from the beginning.
	 */
	public function start():Void {
		if (events.length == 0) {
			Logs.warn('There was an attempt to start a sequence with no events. Was it destroyed?');
			return;
		}
		eventCount = 0;
		timer.reset(currentEvent.time * multiplier);
	}

	/**
	 * Cancels out all the events in the sequence.
	 */
	public function stop():Void {
		eventCount = events.length;
		timer.cancel();
	}

	/**
	 * Clean up and destroy this sequence.
	 * Note that this will render the sequence unusable.
	 */
	public function destroy():Void {
		timer.cancel();
		timer.destroy();
		while (events.length > 0) events.pop();
		eventCount = 0;
	}
}