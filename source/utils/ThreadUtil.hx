package utils;

import sys.thread.Thread;

/**
 * Utility class to handle multithreading logic for the game.
 * Provides functionality for initializing threads, executing functions asynchronously,
 * and safely creating threads with error handling and optional auto-restart.
 */
class ThreadUtil {
	/**
	 * Array storing all threads used for game logic execution.
	 */
	public static var gameThreads:Array<Thread> = [];
	static var initialized:Bool = false;

	/**
	 * Initializes a set of game threads with event loops for asynchronous task handling.
	 * This setup creates 4 threads that can be used to distribute workload.
	 */
	public static function init() {
		if (initialized) return;
		for (i in 0...4) gameThreads.push(Thread.createWithEventLoop(() -> Thread.current().events.promise()));
		initialized = true;
	}

	/**
	 * Internal counter used to cycle through threads in a round-robin fashion.
	 */
	static var __threadCycle:Int = 0;

	/**
	 * Executes a given function asynchronously on one of the initialized threads.
	 * Threads are chosen using round-robin scheduling.
	 * @param func The function to be executed asynchronously.
	 */
	public static function execAsync(func:Void->Void) {
		var thread:Thread = gameThreads[(__threadCycle++) % gameThreads.length];
		thread.events.run(func);
	}

	/**
	 * Creates and starts a new thread to safely execute a function, optionally restarting the thread upon errors.
	 * Useful for resilient background tasks where failure recovery is needed.
	 *
	 * @param func The function to be executed in the new thread.
	 * @param autoRestart If true, the thread will restart itself after crashing.
	 * @return The created thread.
	 */
	public static function createSafe(func:Void->Void, autoRestart:Bool = false):Thread {
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