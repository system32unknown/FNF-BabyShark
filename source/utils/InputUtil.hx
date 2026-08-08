package utils;

import flixel.input.keyboard.FlxKey;

@:nullSafety
class InputUtil {
	/**
	 * Returns true if all of the keys in keyArray are being pressed,
	 * but also only fires once on the last key in the array being justPressed
	 * @param keyArray An array of FlxKeys
	 * @return Bool True if all of the keys in keyArray are being pressed, with at least one of them being in a JUST_PRESSED state
	 */
	public static function allPressedWithDebounce(keyArray:Array<FlxKey>):Bool {
		return allPressed(keyArray) && FlxG.keys.anyJustPressed(keyArray);
	}

	/**
	 * Returns true if all of the keys in keyArray are being pressed
	 * @param keyArray An array of FlxKeys
	 * @return Bool True if all keys in keyArray are being pressed
	 */
	public static function allPressed(keyArray:Array<FlxKey>):Bool {
		return !anyNotPressed(keyArray);
	}

	/**
	 * Returns if any key is not being pressed (or just pressed)
	 * @param keyArray An array of FlxKeys
	 * @return Bool True if there's any key in keyArray that isn't being pressed
	 */
	public static function anyNotPressed(keyArray:Array<FlxKey>):Bool {
		var isKeyNotPressed:FlxKey->Bool = key -> return FlxG.keys.checkStatus(key, RELEASED) || FlxG.keys.checkStatus(key, JUST_RELEASED);
		return Lambda.exists(keyArray, isKeyNotPressed);
	}

	/**
	 * Returns if any key is being pressed (or was just pressed)
	 * @param keyArray An array of FlxKeys
	 * @return `true` if there's any key in keyArray that isn't being pressed
	 */
	public static function anyPressed(keyArray:Array<FlxKey>):Bool {
		var isKeyBeingPressed:FlxKey->Bool = key -> return FlxG.keys.checkStatus(key, PRESSED) || FlxG.keys.checkStatus(key, JUST_PRESSED);
		return Lambda.exists(keyArray, isKeyBeingPressed);
	}
	
	/**
	 * Get the key name for a given key code.
	 * @param key The key code to get the name of
	 * @return The name of the key
	 */
	public static function getKeyName(key:FlxKey):String {
		switch (key) {
			case BACKSPACE: return "BckSpc";
			case CONTROL: return "Ctrl";
			case ALT: return "Alt";
			case CAPSLOCK: return "Caps";
			case PAGEUP: return "PgUp";
			case PAGEDOWN: return "PgDown";

			// Number Keys
			case ZERO: return "0";
			case ONE: return "1";
			case TWO: return "2";
			case THREE: return "3";
			case FOUR: return "4";
			case FIVE: return "5";
			case SIX: return "6";
			case SEVEN: return "7";
			case EIGHT: return "8";
			case NINE: return "9";

			// Numpads
			case NUMPADZERO: return "#0";
			case NUMPADONE: return "#1";
			case NUMPADTWO: return "#2";
			case NUMPADTHREE: return "#3";
			case NUMPADFOUR: return "#4";
			case NUMPADFIVE: return "#5";
			case NUMPADSIX: return "#6";
			case NUMPADSEVEN: return "#7";
			case NUMPADEIGHT: return "#8";
			case NUMPADNINE: return "#9";
			case NUMPADMULTIPLY: return "#*";
			case NUMPADPLUS: return "#+";
			case NUMPADMINUS: return "#-";
			case NUMPADPERIOD: return "#.";

			case SEMICOLON: return ";";
			case COMMA: return ",";
			case PERIOD: return ".";
			case GRAVEACCENT: return "`";
			case LBRACKET: return "[";
			case RBRACKET: return "]";
			case QUOTE: return "'";
			case PRINTSCREEN: return "PrtScrn";
			case NONE: return '---';
			default:
				var label:String = Std.string(key);
				if (label.toLowerCase() == 'null') return '---';

				var arr:Array<String> = label.split('_');
				for (i in 0...arr.length) arr[i] = StringUtil.capitalize(arr[i]);
				return arr.join(' ');
		}
	}
}