package backend;

import haxe.PosInfos;

class Log {
	public static function init() {
		haxe.Log.trace = function(v, ?posInfos) {
			Sys.println(formatOutput(v, posInfos));
		};
	}

	static function formatOutput(v:Dynamic, infos:PosInfos):String {
		var fileName = infos.fileName.replace('source/', '');
		var str = Std.string(v);
		if (infos == null)
			return str;
		var pstr = '$fileName [Line ${infos.lineNumber}]';

		if (infos.customParams != null)
			for (v in infos.customParams)
				str += ", " + Std.string(v);
		return pstr + ": " + str;
	}
}