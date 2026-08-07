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
	 * Formats a duration (in seconds) into a human-readable string.
	 *
	 * Output rules (compatible with the original intent):
	 * - Default: "m:ss"
	 * - If hours > 0 and days == 0: "h:mm:ss"
	 * - If days > 0 and weeks == 0: "{d}d {h}h {m}m {s}s"
	 * - If weeks > 0: "{w}w {d}d {h}h {m}m {s}s"
	 *
	 * Fractional seconds:
	 * - If `precision > 0`, appends ".<fraction>".
	 * - `precision` here is the scale factor (kept compatible with your original math).
	 * If you want “decimal digits”, see the note below.
	 *
	 * @param time Total duration in seconds (can be fractional).
	 * @param precision Scale factor for fractional part (kept as-is from original code).
	 * @param timePre Minimum width for the fractional part (left-padded with zeros).
	 * @return Formatted time string.
	 */
	public static function formatTime(time:Float, precision:Int = 0, timePre:Int = 0):String {
		// Clamp negatives to 0 (prevents weird modulo results)
		if (time <= 0) return (precision > 0) ? "0:00." + fillNumber(0, timePre, '0'.code) : "0:00";

		final total:Int = Std.int(Math.floor(time));

		var s:Int = total % 60;
		var m:Int = Std.int(total / 60) % 60;
		var h:Int = Std.int(total / 3600) % 24;
		var d:Int = Std.int(total / 86400) % 7;
		var w:Int = Std.int(total / (86400 * 7));

		inline function pad2(n:Int):String return (n < 10 ? "0" : "") + n;

		var out:String;
		if (w > 0) {
			out = '${w}w ${d}d ${h}h ${m}m ${s}s';
		} else if (d > 0) {
			out = '${d}d ${h}h ${m}m ${s}s';
		} else if (h > 0) {
			out = '${h}:${pad2(m)}:${pad2(s)}';
		} else {
			out = '${m}:${pad2(s)}';
		}

		if (precision > 0) {
			var frac:Float = time - total;
			var ms:Int = Std.int(Math.floor(frac * precision));
			out += "." + fillNumber(ms, timePre, '0'.code);
		}

		return out;
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
	 * Reverses a given string.
	 * @param str The input string.
	 * @return The reversed string.
	 */
	public static function reverseString(str:String):String {
		var reversed:String = "";
		for (i in 0...str.length) reversed = str.charAt(i) + reversed;
		return reversed;
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
		} else throw "It's invalid type. You need the number or numerical string.";

		var decimal:Bool = defined.lastIndexOf(".") != -1;
		var cnt:Int = 0;
		var pos:Int = defined.length - 1;
		for (_ in 0...defined.length) {
			var char:Int = defined.fastCodeAt(pos);
			if (decimal) {
				if (char == ".".code) decimal = false;
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
}