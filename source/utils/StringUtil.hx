package utils;

class StringUtil {
	/**
	 * Fill numbers with a specified number of digits and right-align with the number.
	 * @param value Floating-point number
	 * @param digits Integer
	 * @param code Integer (use fastCodeAt)
	 */
	inline public static function fillNumber(value:Float, digits:Int, code:Int):String {
		var length:Int = Std.string(value).length;
		var str:String = null;
		var format:StringBuf = new StringBuf();

		if (length < digits) {
			for (_ in 0...(digits - length)) format.addChar(code);
			format.add(Std.string(value));
		} else format.add(Std.string(value));

		str = format.toString();
		format = null;
		return str;
	}

	/**
	 * Formats a given time in seconds into a human-readable string (weeks, days, hours, minutes, seconds).
	 * @param time Floating-point number representing total seconds.
	 * @param precision Integer specifying decimal precision.
	 * @param timePre Integer for additional time formatting.
	 * @return Formatted time string.
	 */
	public static function formatTime(time:Float, precision:Int = 0, timePre:Int = 0):String {
		var secs:String = '' + Math.floor(time) % 60;
		var mins:String = '' + Math.floor(time / 60) % 60;
		var hour:String = '' + Math.floor(time / 3600) % 24;
		var days:String = '' + Math.floor(time / 86400) % 7;
		var weeks:String = '' + Math.floor(time / (86400 * 7));

		if (secs.length < 2) secs = '0$secs';

		var formattedtime:String = '$mins:$secs';
		if (hour != '0' && days == '0') {
			if (mins.length < 2) mins = '0$mins';
			formattedtime = '$hour:$mins:$secs';
		}

		if (days != '0' && weeks == '0') formattedtime = '${days}d ${hour}h ${mins}m ${secs}s';
		if (weeks != '0') formattedtime = '${weeks}w ${days}d ${hour}h ${mins}m ${secs}s';

		if (precision > 0) {
			var secondsForMS:Float = time % 60;

			formattedtime += ".";
			var seconds:Int = Math.floor((secondsForMS - Std.int(secondsForMS)) * precision);
			formattedtime += fillNumber(seconds, timePre, '0'.charCodeAt(0));
		}
		return formattedtime;
	}

	/**
	 * Generates a random string of a specified length.
	 * @param max The length of the random string.
	 * @param includespace Whether to include spaces or newlines.
	 * @param chance The probability of inserting a space or newline.
	 * @return A randomly generated string.
	 */
	public static function getRNGTxt(max:Int, ?includespace:Bool, ?chance:Int = 50):String {
		var temp_str:String = "";
		for (_ in 0...max) {
			temp_str += String.fromCharCode(FlxG.random.int(65, 122));
			if (includespace && FlxG.random.bool(chance)) temp_str += "\n";
		}
		return temp_str;
	}

	/**
	 * Capitalizes the first letter of a string.
	 * @param text The input string.
	 * @return The capitalized string.
	 */
	inline public static function capitalize(text:String):String {
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();
	}

	/**
	 * Converts a hexadecimal string to a binary string.
	 * @param str The hexadecimal input.
	 * @return The binary representation of the input string.
	 */
	inline public static function hex2bin(str:String):String {
		var returnVal:String = "";
		var tmpStr:String = "";
		var hex:Int = 0;
		for (i in 0...str.length) {
			hex = Std.parseInt("0x" + str.charAt(i));
			tmpStr = "";
			for (j in 0...4) tmpStr = ((hex & 1 << j) == 1 << j ? "1" : "0") + tmpStr;
			returnVal += tmpStr + " ";
		}
		return returnVal.substr(0, returnVal.length - 1);
	}

	/**
	 * Converts a decimal number to a binary string with a specified number of digits.
	 * @param int The decimal number.
	 * @param digits The number of binary digits to return.
	 * @return The binary representation of the input number.
	 */
	inline public static function dec2bin(int:Int, digits:Int):String {
		var str:String = "";
		digits = FlxMath.minInt(digits, 32);

		while (digits > 0) {
			str = Std.string(int % 2) + str;
			int >>= 1;
			digits--;
		}
		return str;
	}

	/**
	 * Reverses a given string.
	 * @param str The input string.
	 * @return The reversed string.
	 */
	public static function reverseString(str:String):String {
		var reversed:String = "";
		for (i in 0...str.length) reversed = str.charAt(i) + reversed;
		return reversed;
	}

	/**
	 * Generates a snapshot version string based on the given date.
	 * The format of the version string is "YYwWc", where:
	 * - YY is the last two digits of the year.
	 * - W is the week number of the year (starting from the first Sunday).
	 * - c is a character suffix starting from 'a'.
	 *
	 * @param date The date from which to generate the version string.
	 * @param suffix An optional integer that determines the suffix character (default is 0, corresponding to 'a').
	 * @return A formatted string representing the snapshot version.
	 */
	public static function getSnapshotVer(date:Date, suffix:Int = 0):String {
		var year:Int = date.getFullYear() % 100; // Get last two digits of the year
		var startOfYear:Date = new Date(date.getFullYear(), 0, 1, 0, 0, 0); // Haxe Date expects hour, minute, and second as well
		var pastDaysOfYear:Int = Math.floor((date.getTime() - startOfYear.getTime()) / (1000 * 60 * 60 * 24));
		var week:Int = Math.ceil((pastDaysOfYear + startOfYear.getDay() + 1) / 7);

		return year + "w" + week + String.fromCharCode(97 + suffix);
	}

	/**
	 * Converts a large floating-point number into a compact, readable format using
	 * the illion system (e.g., "1.2 million", "3.5 billion").
	 *
	 * @param number The number to be converted.
	 * @return A string representing the compact number format.
	 */
	public static function toCompactNumber(number:Float):String {
		var suffixes1:Array<String> = ['ni', 'mi', 'bi', 'tri', 'quadri', 'quinti', 'sexti', 'septi', 'octi', 'noni'];
		var tenSuffixes:Array<String> = ['', 'deci', 'viginti', 'triginti', 'quadraginti', 'quinquaginti', 'sexaginti', 'septuaginti', 'octoginti', 'nonaginti', 'centi'];
		var decSuffixes:Array<String> = ['', 'un', 'duo', 'tre', 'quattuor', 'quin', 'sex', 'septe', 'octo', 'nove'];
		var centiSuffixes:Array<String> = ['centi', 'ducenti', 'trecenti', 'quadringenti', 'quingenti', 'sescenti', 'septingenti', 'octingenti', 'nongenti'];

		var magnitude:Int = 0;
		var num:Float = number;
		var tenIndex:Int = 0;

		while (num >= 1000.) {
			num /= 1000.;

			if (magnitude == suffixes1.length - 1) tenIndex++;
			magnitude++;

			if (magnitude == 21) {
				tenIndex++;
				magnitude = 11;
			}
		}

		// Determine which set of suffixes to use
		var suffixSet:Array<String> = (magnitude <= suffixes1.length) ? suffixes1 : ((magnitude <= suffixes1.length + decSuffixes.length) ? decSuffixes : centiSuffixes);

		// Use the appropriate suffix based on magnitude
		var suffix:String = (magnitude <= suffixes1.length) ? suffixSet[magnitude - 1] : suffixSet[magnitude - 1 - suffixes1.length];
		var tenSuffix:String = (tenIndex <= 10) ? tenSuffixes[tenIndex] : centiSuffixes[tenIndex - 11];

		// Use the floor value for the compact representation
		var compactValue:Float = Math.floor(num * 100) / 100;

		if (compactValue <= .001) return "0";
		else {
			var illionRepresentation:String = "";
			if (magnitude > 0) illionRepresentation += suffix + tenSuffix;
			if (magnitude > 1) illionRepresentation += "llion";

			return compactValue + (magnitude == 0 ? "" : " ") + (magnitude == 1 ? 'thousand' : illionRepresentation);
		}
	}

	public static function sortByAlphabet(arr:Array<String>):Array<String> {
		arr.sort((a:String, b:String) -> {
			a = a.toUpperCase();
			b = b.toUpperCase();

			if (a < b) return -1;
			else if (a > b) return 1;
			else return 0;
		});
		return arr;
	}

	inline public static function customNumberDelimiter(value:Dynamic, ?numFormat:Bool = false):String {
		if (!numFormat || value == null) return value;

		var defined:String = null;
		if (value is String) {
			if (!Math.isNaN(Std.parseFloat(value))) {
				defined = value;
			} else throw "Given string, but It cannot convert to number";
		} else if (value is Float || value is Int) {
			defined = Std.string(value);
		} else throw "It's invalid type";

		var decimal:Bool = defined.lastIndexOf(".") != -1;
		var cnt:Int = 0;
		var pos:Int = defined.length - 1;
		for (_ in 0...defined.length) {
			var char:Int = defined.fastCodeAt(pos);
			if (decimal) {
				if (char == ".".code) {
					decimal = false;
				}
			} else {
				if (48 <= char && char < 58) ++cnt;
				if (cnt > 3) {
					cnt -= 3;
					defined = defined.substr(0, pos + 1) + "," + defined.substr(pos + 1);
				}
			}
			--pos;
		}
		return defined;
	}

	inline public static function floatToStringPrecision(n:Float, prec:Int):String {
		n = Math.round(n * Math.pow(10, prec));
		var str:String = '' + n;
		var len:Int = str.length;
		if (len <= prec) {
			while (len < prec) {
				str = '0' + str;
				len++;
			}
			return '0.' + str;
		} else return str.substr(0, str.length - prec) + '.' + str.substr(str.length - prec);
	}

	/**
	 * Replaces in a string any kind of IP with `[Your IP]` making the string safer to trace.
	 * @param msg String to check and edit
	 * @return String Result without any kind of IP
	 */
	public static inline function removeIP(msg:String):String {
		return ~/\d+.\d+.\d+.\d+/.replace(msg, "[Your IP]");
	}
}