package scripting;

import objects.Bar;
import openfl.display.BlendMode;
import data.StageData;

class ScriptUtils {
	public static var Function_Stop:String = "##PSYCH_FUNCTIONSTOP";
	public static var Function_Continue:String = "##PSYCH_FUNCTIONCONTINUE";
	public static var Function_StopHScript:String = "##PSYCH_FUNCTIONSTOPHSCRIPT";
	public static var Function_StopAll:String = "##PSYCH_FUNCTIONSTOPALL";

	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic, allowMaps:Bool = false):Any {
		var splitProps:Array<String> = variable.split('[');
		if (splitProps.length > 1) {
			var target:Dynamic = null;
			if (MusicBeatState.getVariables().exists(splitProps[0])) {
				var retVal:Dynamic = MusicBeatState.getVariables().get(splitProps[0]);
				if (retVal != null) target = retVal;
			} else target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length) {
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				if (i >= splitProps.length - 1) target[j] = value; // Last array
				else target = target[j]; // Anything else
			}
			return target;
		}

		if (allowMaps && isMap(instance)) {
			instance.set(variable, value);
			return value;
		}

		if (instance is MusicBeatState && MusicBeatState.getVariables().exists(variable)) {
			MusicBeatState.getVariables().set(variable, value);
			return value;
		}
		Reflect.setProperty(instance, variable, value);
		return value;
	}

	public static function getVarInArray(instance:Dynamic, variable:String, allowMaps:Bool = false):Any {
		var splitProps:Array<String> = variable.split('[');
		if (splitProps.length > 1) {
			var target:Dynamic = null;
			if (MusicBeatState.getVariables().exists(splitProps[0])) {
				var retVal:Dynamic = MusicBeatState.getVariables().get(splitProps[0]);
				if (retVal != null) target = retVal;
			} else target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length) {
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				target = target[j];
			}
			return target;
		}

		if (allowMaps && isMap(instance)) return instance.get(variable);

		if (instance is MusicBeatState && MusicBeatState.getVariables().exists(variable)) {
			var retVal:Dynamic = MusicBeatState.getVariables().get(variable);
			if (retVal != null) return retVal;
		}
		return Reflect.getProperty(instance, variable);
	}

	public static function getModSetting(saveTag:String, ?modName:String = null):Dynamic {
		#if MODS_ALLOWED
		if (FlxG.save.data.modSettings == null) FlxG.save.data.modSettings = new Map<String, Dynamic>();

		var settings:Map<String, Dynamic> = FlxG.save.data.modSettings.get(modName);
		var path:String = Paths.mods('$modName/data/settings.json');
		if (FileSystem.exists(path)) {
			if (settings == null || !settings.exists(saveTag)) {
				if (settings == null) settings = new Map<String, Dynamic>();
				try {
					var parsedJson:Dynamic = tjson.TJSON.parse(File.getContent(path));
					for (i in 0...parsedJson.length) {
						var sub:Dynamic = parsedJson[i];
						if (sub != null && sub.save != null && !settings.exists(sub.save)) {
							if (sub.type != 'keybind' && sub.type != 'key' && sub.value != null) settings.set(sub.save, sub.value);
							else settings.set(sub.save, {keyboard: (sub.keyboard ?? 'NONE')});
						}
					}
					FlxG.save.data.modSettings.set(modName, settings);
				} catch (e:Dynamic) {
					var errorTitle:String = 'Mod name: ' + Mods.currentModDirectory;
					var errorMsg:String = 'An error occurred: $e';
					utils.system.NativeUtil.showMessageBox(errorMsg, errorTitle);
					Logs.error('$errorTitle - $errorMsg');
				}
			}
		} else {
			FlxG.save.data.modSettings.remove(modName);
			#if HSCRIPT_ALLOWED
			PlayState.instance.addTextToDebug('getModSetting: $path could not be found!', FlxColor.RED);
			#else
			FlxG.log.warn('getModSetting: $path could not be found!');
			#end
			return null;
		}

		if (settings.exists(saveTag)) return settings.get(saveTag);
		#if HSCRIPT_ALLOWED
		PlayState.instance.addTextToDebug('getModSetting: "$saveTag" could not be found inside $modName\'s settings!', FlxColor.RED);
		#else
		FlxG.log.warn('getModSetting: "$saveTag" could not be found inside $modName\'s settings!');
		#end
		#end
		return null;
	}

	public static function isMap(variable:Dynamic):Bool {
		return (variable.exists != null && variable.keyValueIterator != null);
	}

	public static function getPropertyLoop(split:Array<String>, ?getProperty:Bool = true, ?allowMaps:Bool = false):Dynamic {
		var obj:Dynamic = getObjectDirectly(split[0]);
		var end:Int = split.length;
		if (getProperty) end = split.length - 1;

		for (i in 1...end) obj = getVarInArray(obj, split[i], allowMaps);
		return obj;
	}

	public static function getObjectDirectly(objectName:String, ?allowMaps:Bool = false):Dynamic {
		switch (objectName) {
			case 'this' | 'instance' | 'game': return PlayState.instance;

			default:
				var obj:Dynamic = MusicBeatState.getVariables().get(objectName);
				if (obj == null) obj = getVarInArray(getTargetInstance(), objectName, allowMaps);
				return obj;
		}
	}

	public static inline function getTargetInstance():flixel.FlxState {
		if (PlayState.instance != null) return PlayState.instance.isDead ? substates.GameOverSubstate.instance : PlayState.instance;
		return MusicBeatState.getState();
	}

	public static function setBarColors(bar:Bar, color1:String, color2:String) {
		final left_color:Null<FlxColor> = (color1 != null && color1 != '' ? Util.colorFromString(color1) : null);
		final right_color:Null<FlxColor> = (color2 != null && color2 != '' ? Util.colorFromString(color2) : null);
		bar.setColors(left_color, right_color);
	}

	public static inline function getLowestCharacterGroup():FlxSpriteGroup {
		var stageData:StageFile = StageData.getStageFile(PlayState.SONG.stage);
		var group:FlxSpriteGroup = (stageData.hide_girlfriend ? PlayState.instance.boyfriendGroup : PlayState.instance.gfGroup);
		var pos:Int = PlayState.instance.members.indexOf(group);

		var newPos:Int = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
		if (newPos < pos) {
			group = PlayState.instance.boyfriendGroup;
			pos = newPos;
		}

		newPos = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
		if (newPos < pos) {
			group = PlayState.instance.dadGroup;
			pos = newPos;
		}
		return group;
	}

	inline public static function blendModeFromString(blend:String):BlendMode
		return cast(blend.toLowerCase().trim() : BlendMode);

	public static function getTargetOS():String {
		#if windows
		#if x86_BUILD
		return 'windows_x86';
		#else
		return 'windows';
		#end
		#elseif linux
		return 'linux';
		#elseif (mac || macos)
		return 'mac';
		#else
		return 'unknown';
		#end
	}

	public static function getTarget():String {
		#if cpp
		return 'C++';
		#elseif hl
		return 'Hashlink';
		#elseif neko
		return 'Neko';
		#else
		return 'Unknown';
		#end
	}
}