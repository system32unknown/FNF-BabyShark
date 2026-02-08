package utils;

typedef IniMap = Map<String, Map<String, String>>;

class IniUtil {
	public static inline function parseAsset(assetPath:String):IniMap
		return parseString(Paths.getTextFromFile(assetPath));

	public static function parseString(data:String):IniMap {
		var res:IniMap = [];
		parseStringToMap(res, data);
		return res;
	}

	public static function parseStringToMap(map:IniMap, data:String) {
		var section:Map<String, String> = null;

		var regexSec:EReg = ~/^\[(.+)\]/g, regexVal = ~/^([^#;].+)=(.+)/g, quote = ~/[\\'"](.+)[\\'"]/g, iln = 0;
		do {
			var line:String = data.substring(iln, ((iln = data.indexOf('\n', iln) + 1) == 0 ? data.length : iln - 1));
			if (regexSec.match(line)) {
				if ((section = map.get(regexSec.matched(1))) == null) map.set(regexSec.matched(1), section = []);
			}
			else if (regexVal.match(line)) {
				var s:String = regexVal.matched(2).trim();
				if (quote.match(s)) s = quote.matched(1);

				if (section == null) {
					if ((section = map.get("Global")) == null) map.set("Global", section = []);
				}
				section.set(regexVal.matched(1).trim(), s);
			}
		} while (iln != 0);
	}
}