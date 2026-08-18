package debug;

// crash handler stuff
import flixel.util.FlxSignal.FlxTypedSignal;
import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
import lime.system.System;

/**
 * Global crash handler for capturing and logging uncaught errors.
 *
 * This class hooks into native (C++) and OpenFL error systems
 * to ensure crashes are properly logged and reported.
 */
@:nullSafety
class CrashHandler {
	public static final LOG_FOLDER:String = 'logs';

	/**
	 * Called before exiting the game when a standard error occurs, like a thrown exception.
	 * @param message The error message.
	 */
	public static var errorSignal(default, null):FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

	/**
	 * Called before exiting the game when a critical error occurs, like a stack overflow or null object reference.
	 * CAREFUL: The game may be in an unstable state when this is called.
	 * @param message The error message.
	 */
	public static var criticalErrorSignal(default, null):FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

	/**
	 * Initializes the crash handler.
	 *
	 * Sets up platform-specific error handlers and registers
	 * an OpenFL uncaught error listener.
	 */
	public static function init():Void {
		FlxG.stage.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onErrorOFL);
		#if cpp untyped __global__.__hxcpp_set_critical_error_handler(onCriticalError); #end
	}

	/**
	 * Handles OpenFL uncaught errors.
	 *
	 * Extracts a readable error message from the event and forwards
	 * it to the main error handler.
	 *
	 * @param e The uncaught error event.
	 */
	static function onErrorOFL(e:UncaughtErrorEvent):Void {
		var message:String = '';
		if (Std.isOfType(e.error, Error)) {
			var err:Error = cast(e.error, Error);
			message = err.getStackTrace() ?? err.message;
		} else if (Std.isOfType(e.error, ErrorEvent)) message = cast(e.error, ErrorEvent).text;
		else message = Std.string(e.error);

		e.preventDefault();
		e.stopImmediatePropagation();

		onError(message);
	}

	/**
	 * Main crash handler logic.
	 *
	 * The report is saved to the `./crash/` directory and displayed
	 * to the user before exiting the application.
	 *
	 * @param message The error message or stack trace.
	 */
	static function onError(message:String):Void {
		final defines:Map<String, Dynamic> = macros.DefinesMacro.defines;

		var errMsg:String = 'Uncaught Error: $message\n' + getError();
		errMsg += '\nPlatform: ${System.platformLabel} ${System.platformVersion} [Target: ${scripting.ScriptUtils.getTarget()}]';
		var currentState:String = 'No state loaded';
		if (FlxG.game != null && FlxG.state != null) {
			var currentStateCls:Null<Class<Dynamic>> = Type.getClass(FlxG.state);
			if (currentStateCls != null) currentState = Type.getClassName(currentStateCls) ?? 'No state loaded';
		}
		errMsg += '\nFlixel Current State: $currentState';
		errMsg += '\nPlease report this error to the GitHub page: https://github.com/system32unknown/AlterEngine\n\nCustom Crash Handler written by: sqirra-rng and Codename Engine Team and Altertoriel';
		errMsg += '\nHaxe: ${defines['haxe']} / Flixel: ${defines['flixel']} / OpenFL: ${defines['openfl']} / Lime: ${defines['lime']}';
		if (Mods.currentModDirectory != '') errMsg += '\nCurrent Active Mod: ${Mods.currentModDirectory}';

		errorSignal.dispatch(errMsg);
		try {
			#if sys logErrorMsg(errMsg); #end
		} catch (e:Dynamic) Sys.println('Error!\nCouldn\'t save the crash dump because:\n$e');

		utils.system.NativeUtil.showMessageBox("Fatal Uncaught Exception", errMsg, MSG_ERROR);
		#if DISCORD_ALLOWED DiscordClient.shutdown(); #end
		System.exit(1);
	}

	static function onCriticalError(message:String):Void {
		try {
			criticalErrorSignal.dispatch(message);
			#if sys logErrorMsg(message, true); #end
		} catch (e:Dynamic) Sys.println('Error!\nCouldn\'t save the critial crash dump because:\n$e');

		utils.system.NativeUtil.showMessageBox("Fatal Uncaught Exception", message, MSG_ERROR);
		#if DISCORD_ALLOWED DiscordClient.shutdown(); #end
		System.exit(1);
	}

	#if sys
	static function logErrorMsg(msg:String, critical:Bool = false):Void {
		final path:String = '$LOG_FOLDER/crash${critical ? '-critical' : ''}-${Date.now().toString().replace(" ", "_").replace(":", "'")}.log';
		if (!FileSystem.exists(LOG_FOLDER)) FileSystem.createDirectory(LOG_FOLDER);
		File.saveContent(path, msg);

		Sys.println("\n" + msg);
		Sys.println('Crash dump saved in ${haxe.io.Path.normalize(path)}');
	}
	#end

	/**
	 * Builds a formatted stack trace string from the current exception stack.
	 *
	 * Iterates through the call stack and formats each entry
	 * into a human-readable format.
	 *
	 * @return A formatted stack trace string.
	 */
	static function getError():String {
		var error:String = '';
		for (stackItem in haxe.CallStack.exceptionStack(true)) {
			switch (stackItem) {
				case FilePos(_, file, line, column):
					error += ' in $file#$line';
					if (column != null) error += ':$column';
				case CFunction: error += '[Function] ';
				case Module(m): error += '[Module($m)] ';
				case Method(cl, m): error += '[Function($cl.$m)] ';
				case LocalFunction(v): error += '[LocalFunction($v)] ';
			}
			error += '\n';
		}
		return error;
	}
}