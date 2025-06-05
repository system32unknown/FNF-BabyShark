package utils;

typedef IniMap = Map<String, Map<String, String>>;

class IniUtil {
	static var comment:EReg = ~/^#.*/;
	static var section:EReg = ~/^\[([^\]]+)\]/;
	static var def:EReg = ~/^([^:=]+)[:=](.*)/;

	public static inline function parseAsset(assetPath:String, ?defaultVariables:IniMap):IniMap
		return parseString(Paths.getTextFromFile(assetPath), defaultVariables);

	public static function parseString(data:String, ?defaultVariables:IniMap):IniMap {
		var finalMap:IniMap = [];
		if (defaultVariables != null) for (k => e in defaultVariables) finalMap[k] = e;

		var currentSection = "";
		var lastDef = null;
		for (line in data.split("\n")) {
			line = line.trim();
			if (line.length == 0) continue;
			if (comment.match(line)) continue;
			else if (section.match(line)) {
				currentSection = section.matched(1); // new section
			} else if (def.match(line)) {
				if (!finalMap.exists(currentSection)) finalMap[currentSection] = new Map();
				finalMap[currentSection][def.matched(1)] = def.matched(2);
				lastDef = def.matched(1);
			} else {
				if (lastDef == null) throw "Config formatting error";
				finalMap[currentSection][lastDef] += " " + line;
			}
		}
		return finalMap;
	}
}