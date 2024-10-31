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
 
		if(length < digits) {
			for (_ in 0...(digits - length)) format.addChar(code);
			format.add(Std.string(value));
		} else format.add(Std.string(value));
 
		str = format.toString();
		format = null;
		return str;
	}

    // formatTime but epic
	public static function formatTime(time:Float, precision:Int = 0):String {
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

		if (days != '0' && weeks == '0') formattedtime = days + 'd ' + hour + 'h ' + mins + "m " + secs + 's';
		if (weeks != '0') formattedtime = weeks + 'w ' + days + 'd ' + hour + 'h ' + mins + "m " + secs + 's';

		if (precision > 0) {
			var secondsForMS:Float = time % 60;
			var seconds:Int = Std.int((secondsForMS - Std.int(secondsForMS)) * Math.pow(10, precision));
			formattedtime += ".";
			if (precision > 1 && Std.string(seconds).length < precision) {
				for (_ in 0...precision - Std.string(seconds).length)
                    formattedtime += '0';
			}
			formattedtime += seconds;
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
}