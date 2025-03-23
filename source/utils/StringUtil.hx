package utils;

class StringUtil {
	/**
	 * Fill numbers with a specified number of digits and right-align with the number.
	 * @param value Floating-point number
	 * @param digits Integer
	 * @param code Integer (use fastCodeAt)
	 */
	public static function fillNumber(value:Float, digits:Int, code:Int):String {
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
	public static function hex2bin(str:String):String {
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
	public static function dec2bin(int:Int, digits:Int):String {
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
	 * Counts the number of occurrences of a character or substring in a string.
	 * @param str The input string.
	 * @param target The character or substring to count.
	 * @return The number of occurrences.
	 */
	public static function charAppearanceCnt(str:String, target:String):Int {
		var cnt:Int = 0;
		if (target == null || target.length == 0) return 0;
		for (i in 0...str.length) {
			if (target.length == 1) {
				if (str.charAt(i) == target) ++cnt;
			} else {
				for (j in 0...target.length) {
					if (str.charAt(i) == target.charAt(j)) ++cnt;
				}
			}
		}
		return cnt;
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
}