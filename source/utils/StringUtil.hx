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

    public static function getRNGTxt(max:Int, ?includespace:Bool, ?chance:Int = 50):String {
        var temp_str:String = "";
        for (_ in 0...max) {
            temp_str += String.fromCharCode(FlxG.random.int(65, 122));
			if (includespace && FlxG.random.bool(chance)) temp_str += "\n";
		}
        return temp_str;
    }

    inline public static function capitalize(text:String):String {
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();
	}

	public static function hex2bin(str:String):String {
		var returnVal:String = "";
		var tmpStr:String = "";
		var hex:Int = 0;
		for (i in 0...str.length) {
			hex = Std.parseInt("0x" + str.charAt(i));
			tmpStr = "";
			for (j in 0...4) {
				tmpStr = ((hex & 1 << j) == 1 << j ? "1" : "0") + tmpStr;
			}
			returnVal += tmpStr + " ";
		}
		return returnVal.substr(0, returnVal.length - 1);
	}
	public static function dec2bin(int:Int, digits:Int):String {
		var str:String = "";
		digits = FlxMath.minInt(digits, 32);

		while (digits > 0) {
			str = Std.string(int % 2) + str;
			int >>= 1; digits--;
		}
		return str;
	}

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
	public static function reverseString(str:String):String {
		var reversed:String = "";
		for (i in 0...str.length) reversed = str.charAt(i) + reversed;
		return reversed;
	}
}