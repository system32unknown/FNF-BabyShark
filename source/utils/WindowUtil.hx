package utils;

import flixel.util.FlxSignal.FlxTypedSignal;
#if FEATURE_DEBUG_TRACY
import cpp.vm.tracy.TracyProfiler;
import openfl.events.Event;
#end

@:nullSafety
class WindowUtil {
	/**
	 * A regex to match valid URLs.
	 */
	public static final URL_REGEX:EReg = ~/^https?:\/?\/?(?:www\.)?[-a-zA-Z0-9@:%_\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)$/;

	/**
	 * Sanitizes a URL via a regex.
	 *
	 * @param targetUrl The URL to sanitize.
	 * @return The sanitized URL, or an empty string if the URL is invalid.
	 */
	public static function sanitizeURL(targetUrl:String):String {
		targetUrl = (targetUrl ?? '').trim();
		if (targetUrl == '') return '';

		final lowerUrl:String = targetUrl.toLowerCase();
		if (!lowerUrl.startsWith('http:') && !lowerUrl.startsWith('https:')) targetUrl = 'http://' + targetUrl;
		if (URL_REGEX.match(targetUrl)) return URL_REGEX.matched(0);

		return '';
	}

	/**
	 * Runs platform-specific code to open a URL in a web browser.
	 * @param site The URL to open.
	 */
	public static function openURL(site:String):Void {
		// Ensure you can't open protocols such as steam://, file://, etc
		var protocol:Array<String> = site.split('://');
		if (protocol.length == 1) site = 'https://$site';
		else if (protocol[0] != 'http' && protocol[0] != 'https') throw 'openURL can only open http and https links.';

		site = sanitizeURL(site);
		if (site == '') throw 'Invalid URL: "$site"';

		#if linux
		Sys.command('/usr/bin/xdg-open $site &');
		#else
		FlxG.openURL(site);
		#end
	}

	/**
	 * Dispatched when the game window is closed.
	 */
	public static var windowExit:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

	/**
	 * Wires up FlxSignals that happen based on window activity.
	 * For example, we can run a callback when the window is closed.
	 */
	public static function initWindowEvents():Void {
		// onExit is called when the game window is closed.
		FlxG.stage.application.onExit.add((exitCode:Int) -> windowExit.dispatch(exitCode));
	}

	#if FEATURE_DEBUG_TRACY
	/**
	 * Initialize Tracy.
	 * NOTE: Call this from the main thread ONLY!
	 */
	public static function initTracy():Void {
		FlxG.stage.addEventListener(Event.EXIT_FRAME, (e:Event) -> TracyProfiler.frameMark());
		TracyProfiler.setThreadName("main");
	}
	#end
}