package utils;

import sys.thread.Thread;

class ThreadUtil {
	public static var gameThreads:Array<Thread> = [];

	public static function init() {
		for (i in 0...4) gameThreads.push(Thread.createWithEventLoop(() -> Thread.current().events.promise()));
	}

	static var __threadCycle:Int = 0;

	public static function execAsync(func:Void->Void) {
		var thread:Thread = gameThreads[(__threadCycle++) % gameThreads.length];
		thread.events.run(func);
	}

	/**
	 * Creates a new Thread with an error handler.
	 * @param func Function to execute
	 * @param autoRestart Whenever the thread should auto restart itself after crashing.
	 */
	public static function createSafe(func:Void->Void, autoRestart:Bool = false) {
		return Thread.create(function() {
			if (autoRestart) {
				while (true) {
					try {
						func();
					} catch (e:Dynamic) trace(e.details(), ERROR);
				}
			} else {
				try {
					func();
				} catch (e:Dynamic) trace(e.details(), ERROR);
			}
		});
	}
}