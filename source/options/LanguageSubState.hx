package options;

class LanguageSubState extends FlxSubState {
	#if TRANSLATIONS_ALLOWED
	var grpLanguages:FlxTypedGroup<Alphabet> = new FlxTypedGroup<Alphabet>();
	var languages:Array<String> = [];
	var displayLanguages:Map<String, String> = [];
	var curSelected:Int = 0;
	public function new() {
		super();

		var bg = new FlxSprite(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.gameCenter();
		add(bg);
		add(grpLanguages);

		languages.push(ClientPrefs.defaultData.language); //English (US)
		displayLanguages.set(ClientPrefs.defaultData.language, Language.defaultLangName);
		for (directory in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/')) {
			for (file in FileSystem.readDirectory(directory)) {
				if (file.toLowerCase().endsWith('.lang')) {
					var langFile:String = file.substring(0, file.length - '.lang'.length).trim();
					if (!languages.contains(langFile)) languages.push(langFile);

					if (!displayLanguages.exists(langFile)) {
						var path:String = '$directory/$file';
						var txt:String = #if MODS_ALLOWED File.getContent #else openfl.utils.Assets.getText #end(path);

						var id:Int = txt.indexOf('\n');
						if (id > 0) { //language display name shouldnt be an empty string or null
							var name:String = txt.substr(0, id).trim();
							if (!name.contains(':')) displayLanguages.set(langFile, name);
						} else if (txt.trim().length > 0 && !txt.contains(':')) displayLanguages.set(langFile, txt.trim());
					}
				}
			}
		}

		languages.sort((a:String, b:String) -> {
			a = (displayLanguages.exists(a) ? displayLanguages.get(a) : a).toLowerCase();
			b = (displayLanguages.exists(b) ? displayLanguages.get(b) : b).toLowerCase();
			if (a < b) return -1;
			else if (a > b) return 1;
			return 0;
		});

		curSelected = languages.indexOf(ClientPrefs.data.language);
		if (curSelected < 0) {
			ClientPrefs.data.language = ClientPrefs.defaultData.language;
			curSelected = Std.int(Math.max(0, languages.indexOf(ClientPrefs.data.language)));
		}

		for (num => lang in languages) {
			var name:String = displayLanguages.get(lang);
			if (name == null) name = lang;

			var text:Alphabet = new Alphabet(0, 300, name);
			text.isMenuItem = true;
			text.targetY = num;
			text.changeX = false;
			text.distancePerItem.y = 100;
			if (languages.length < 7) {
				text.changeY = false;
				text.gameCenter(Y).y += (100 * (num - (languages.length / 2))) + 45;
			}
			text.gameCenter(X);
			grpLanguages.add(text);
		}
		changeSelected();
	}

	var changedLanguage:Bool = false;
	override function update(elapsed:Float) {
		super.update(elapsed);

		var mult:Int = (FlxG.keys.pressed.SHIFT) ? 4 : 1;
		final upJustPressed:Bool = Controls.justPressed('ui_up');
		if (upJustPressed || Controls.justPressed('ui_down')) changeSelected((upJustPressed ? -1 : 1) * mult);
		else if (FlxG.mouse.wheel != 0) changeSelected(FlxG.mouse.wheel * mult);

		if (Controls.justPressed('back')) {
			if (changedLanguage) {
				MusicBeatState.skipNextTransIn = MusicBeatState.skipNextTransOut = true;
				FlxG.resetState();
			} else close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if (Controls.justPressed('accept')) {
			FlxG.sound.play(Paths.sound('confirmMenu'), .6);
			ClientPrefs.data.language = languages[curSelected];
			ClientPrefs.save();
			Language.reloadPhrases();
			changedLanguage = true;
		}
	}

	function changeSelected(change:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + change, 0, languages.length - 1);
		for (num => lang in grpLanguages) {
			lang.targetY = num - curSelected;
			lang.alpha = .6;
			if (num == curSelected) lang.alpha = 1;
		}
		FlxG.sound.play(Paths.sound('scrollMenu'), .6);
	}
	#end
}