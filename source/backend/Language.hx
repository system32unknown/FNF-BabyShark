package backend;

class Language {
	public static var defaultLangName:String = 'English (US)'; // en-US
	#if TRANSLATIONS_ALLOWED static var phrases:Map<String, String> = []; #end

	public static function reloadPhrases() {
		#if TRANSLATIONS_ALLOWED
		var langFile:String = Settings.data.language;
		var loadedText:Array<String> = Mods.mergeAllTextsNamed('data/$langFile.lang');

		phrases.clear();
		var hasPhrases:Bool = false;
		for (num => phrase in loadedText) {
			phrase = phrase.trim();
			if (num < 1 && !phrase.contains(':')) {
				// First line ignores formatting and shit if the line doesn't have ":" because its language_name
				phrases.set('language_name', phrase.trim());
				continue;
			}

			if (phrase.length < 4 || phrase.startsWith('//')) continue; 

			var n:Int = phrase.indexOf(':');
			if (n < 0) continue;

			var key:String = phrase.substr(0, n).trim().toLowerCase();

			var value:String = phrase.substr(n);
			n = value.indexOf('"');
			if (n < 0) continue;

			phrases.set(key, value.substring(n + 1, value.lastIndexOf('"')).replace('\\n', '\n'));
			hasPhrases = true;
		}

		if (!hasPhrases) Settings.data.language = Settings.default_data.language;

		var alphaPath:String = getFileTranslation('images/alphabet');
		if (alphaPath.startsWith('images/')) alphaPath = alphaPath.substr('images/'.length);
		var pngPos:Int = alphaPath.indexOf('.png');
		if (pngPos > -1) alphaPath = alphaPath.substring(0, pngPos);
		Alphabet.loadData(alphaPath);
		#else
		Alphabet.loadData();
		#end
	}

	inline public static function getPhrase(key:String, ?defaultPhrase:String, values:Array<Dynamic> = null):String {
		#if TRANSLATIONS_ALLOWED
		var str:String = phrases.get(formatKey(key)) ?? defaultPhrase;
		#else
		var str:String = defaultPhrase;
		#end

		if (str == null) str = key;
		if (values != null) for (num => value in values) str = str.replace('{${num + 1}}', value);
		return str;
	}

	// More optimized for file loading
	inline public static function getFileTranslation(key:String):String {
		#if TRANSLATIONS_ALLOWED
		var str:String = phrases.get(key.trim().toLowerCase());
		if (str != null) key = str;
		#end
		return key;
	}
	
	#if TRANSLATIONS_ALLOWED
	inline static function formatKey(key:String):String {
		final hideChars:EReg = ~/[~&\\\/;:<>#.,'"%?!]/g;
		return hideChars.replace(key.replace(' ', '_'), '').toLowerCase().trim();
	}
	#end
}