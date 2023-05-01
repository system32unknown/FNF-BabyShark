package scripting.lua;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if MODS_ALLOWED import haxe.Json; #end

import flixel.util.FlxSave;
import openfl.utils.Assets;

import utils.CoolUtil;

//
// Things to trivialize some dumb stuff like splitting strings on older Lua
//
class ExtraFunctions
{
	public static function implement(funk:FunkinLua)
	{
		// Keyboard & Gamepads
		funk.addCallback("keyboardJustPressed", function(name:String) {
			return Reflect.getProperty(FlxG.keys.justPressed, name);
		});
		funk.addCallback("keyboardPressed", function(name:String) {
			return Reflect.getProperty(FlxG.keys.pressed, name);
		});
		funk.addCallback("keyboardReleased", function(name:String) {
			return Reflect.getProperty(FlxG.keys.justReleased, name);
		});

		funk.addCallback("anyGamepadJustPressed", function(name:String) {
			return FlxG.gamepads.anyJustPressed(name);
		});
		funk.addCallback("anyGamepadPressed", function(name:String) {
			return FlxG.gamepads.anyPressed(name);
		});
		funk.addCallback("anyGamepadReleased", function(name:String) {
			return FlxG.gamepads.anyJustReleased(name);
		});

		funk.addCallback("gamepadAnalogX", function(id:Int, ?leftStick:Bool = true) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.;
			return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		funk.addCallback("gamepadAnalogY", function(id:Int, ?leftStick:Bool = true) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.;
			return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		funk.addCallback("gamepadJustPressed", function(id:Int, name:String) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;
			return Reflect.getProperty(controller.justPressed, name) == true;
		});
		funk.addCallback("gamepadPressed", function(id:Int, name:String) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;
			return Reflect.getProperty(controller.pressed, name) == true;
		});
		funk.addCallback("gamepadReleased", function(id:Int, name:String) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;
			return Reflect.getProperty(controller.justReleased, name) == true;
		});

		funk.addCallback("keyJustPressed", function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return PlayState.instance.controls.NOTE_LEFT_P;
				case 'down': return PlayState.instance.controls.NOTE_DOWN_P;
				case 'up': return PlayState.instance.controls.NOTE_UP_P;
				case 'right': return PlayState.instance.controls.NOTE_RIGHT_P;
				default: return PlayState.instance.controls.justPressed(name);
			}
			return false;
		});
		funk.addCallback("keyPressed", function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return PlayState.instance.controls.NOTE_LEFT;
				case 'down': return PlayState.instance.controls.NOTE_DOWN;
				case 'up': return PlayState.instance.controls.NOTE_UP;
				case 'right': return PlayState.instance.controls.NOTE_RIGHT;
				default: return PlayState.instance.controls.pressed(name);
			}
			return false;
		});
		funk.addCallback("keyReleased", function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return PlayState.instance.controls.NOTE_LEFT_R;
				case 'down': return PlayState.instance.controls.NOTE_DOWN_R;
				case 'up': return PlayState.instance.controls.NOTE_UP_R;
				case 'right': return PlayState.instance.controls.NOTE_RIGHT_R;
				default: return PlayState.instance.controls.justReleased(name);
			}
			return false;
		});

		// Save data management
		funk.addCallback("initSaveData", function(name:String, ?folder:String = 'psychenginemods') {
			if(!PlayState.instance.modchartSaves.exists(name)) {
				funk.luaTrace('initSaveData: Save file already initialized: ' + name);
				return;
			}
			var save:FlxSave = new FlxSave();
			save.bind(name, CoolUtil.getSavePath() + '/' + folder);
			PlayState.instance.modchartSaves.set(name, save);
		});
		funk.addCallback("flushSaveData", function(name:String) {
			if(PlayState.instance.modchartSaves.exists(name)) {
				PlayState.instance.modchartSaves.get(name).flush();
				return;
			}
			funk.luaTrace('flushSaveData: Save file not initialized: ' + name, false, false, FlxColor.RED);
		});
		funk.addCallback("getDataFromSave", function(name:String, field:String, ?defaultValue:Dynamic = null) {
			if(!PlayState.instance.modchartSaves.exists(name)) {
				funk.luaTrace('getDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
				return defaultValue;
			}
			return Reflect.field(PlayState.instance.modchartSaves.get(name).data, field);
		});
		funk.addCallback("setDataFromSave", function(name:String, field:String, value:Dynamic) {
			if(!PlayState.instance.modchartSaves.exists(name)) {
				funk.luaTrace('setDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
				return;
			}
			Reflect.setField(PlayState.instance.modchartSaves.get(name).data, field, value);
			
		});
		funk.addCallback("loadJsonOptions", function(inclMainFol:Bool = true, ?modNames:Array<String> = null) {
			#if MODS_ALLOWED
			if (modNames == null) modNames = [];
			if (modNames.length < 1) modNames.push(Paths.currentModDirectory);
			for(mod in Paths.getModDirectories(inclMainFol)) if(modNames.contains(mod) || (inclMainFol && mod == '')) {
				var path:String = haxe.io.Path.join([Paths.mods(), mod, 'options']);
				if(FileSystem.exists(path)) for(file in FileSystem.readDirectory(path)) {
					var folder:String = path + '/' + file;
					if(FileSystem.isDirectory(folder)) for(rawFile in FileSystem.readDirectory(folder)) if(rawFile.endsWith('.json')) {
						var rawJson = File.getContent(folder + '/' + rawFile);
						if (rawJson != null && rawJson.length > 0) {
							var json = Json.parse(rawJson);
							if (!ClientPrefs.modsOptsSaves.exists(mod)) ClientPrefs.modsOptsSaves.set(mod, []);
							if (!ClientPrefs.modsOptsSaves[mod].exists(json.variable)) {
								if (!Reflect.hasField(json, 'defaultValue')) {
									var type:String = 'bool';
									if (Reflect.hasField(json, 'type')) type = json.type;
									ClientPrefs.modsOptsSaves[mod][json.variable] = CoolUtil.getOptionDefVal(type, Reflect.field(json, 'options'));
								} else ClientPrefs.modsOptsSaves[mod][json.variable] = json.defaultValue;
							}
						}
					}
				}
			}
			return ClientPrefs.modsOptsSaves.toString();
			#else
			funk.luaTrace('loadJsonOptions: Platform unsupported for Json Options!', false, false, FlxColor.RED);
			return false;
			#end
		});
		funk.addCallback("getOptionSave", function(variable:String, isJson:Bool = false, ?modName:String = null) {
			if (!isJson)
				return ClientPrefs.getPref(variable);
			else if (isJson) {
				#if MODS_ALLOWED
				if (modName == null) modName = Paths.currentModDirectory;
				if (ClientPrefs.modsOptsSaves.exists(modName) && ClientPrefs.modsOptsSaves[modName].exists(variable)) {
					return ClientPrefs.modsOptsSaves[modName][variable];
				}
				#else
				funk.luaTrace('getOptionSave: Platform unsupported for Json Options!', false, false, FlxColor.RED);
				#end
			}
			return null;
		});
		funk.addCallback("setOptionSave", function(variable:String, value:Dynamic, isJson:Bool = false, ?modName:String = null) {
			if (!isJson) {
				ClientPrefs.prefs.set(variable, value);
				return ClientPrefs.getPref(variable) != null ? true : false;
			} else if (isJson) {
				#if MODS_ALLOWED
				if (modName == null) modName = Paths.currentModDirectory;
				if (ClientPrefs.modsOptsSaves.exists(modName) && ClientPrefs.modsOptsSaves[modName].exists(variable)) {
					ClientPrefs.modsOptsSaves[modName][variable] = value;
					return true;
				}
				#else
				funk.luaTrace('setOptionSave: Platform unsupported for Json Options!', false, false, FlxColor.RED);
				#end
			}
			return false;
		});
		funk.addCallback("saveSettings", function() {
			ClientPrefs.saveSettings();
			return true;
		});

		// File management
		funk.addCallback("checkFileExists", function(filename:String, ?absolute:Bool = false) {
			#if MODS_ALLOWED
			if(absolute) return FileSystem.exists(filename);

			var path:String = Paths.modFolders(filename);
			if(FileSystem.exists(path)) {
				return true;
			}
			return FileSystem.exists(Paths.getPath('assets/$filename', TEXT));
			#else
			if(absolute) return Assets.exists(filename);
			return Assets.exists(Paths.getPath('assets/$filename', TEXT));
			#end
		});
		funk.addCallback("saveFile", function(path:String, content:String, ?absolute:Bool = false) {
			try {
				if(!absolute)
					File.saveContent(Paths.mods(path), content);
				else File.saveContent(path, content);

				return true;
			} catch (e:Dynamic) {
				funk.luaTrace("saveFile: Error trying to save " + path + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		funk.addCallback("deleteFile", function(path:String, ?ignoreModFolders:Bool = false) {
			try {
				#if MODS_ALLOWED
				if(!ignoreModFolders) {
					var lePath:String = Paths.modFolders(path);
					if(FileSystem.exists(lePath)) {
						FileSystem.deleteFile(lePath);
						return true;
					}
				}
				#end

				var lePath:String = Paths.getPath(path, TEXT);
				if(Assets.exists(lePath)) {
					FileSystem.deleteFile(lePath);
					return true;
				}
			} catch (e:Dynamic) {
				funk.luaTrace("deleteFile: Error trying to delete " + path + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		funk.addCallback("getTextFromFile", function(path:String, ?ignoreModFolders:Bool = false) {
			return Paths.getTextFromFile(path, ignoreModFolders);
		});
		funk.addCallback("directoryFileList", function(folder:String) {
			var list:Array<String> = [];
			#if sys
			if(FileSystem.exists(folder)) {
				for (folder in FileSystem.readDirectory(folder)) {
					if (!list.contains(folder)) {
						list.push(folder);
					}
				}
			}
			#end
			return list;
		});
		funk.addCallback("promptSaveFile", function(fileName:String, content:String, extension:String) {
			CoolUtil.saveFile({
				fileDefaultName: fileName,
				format: extension,
				content: content
			});
		});

		funk.addCallback("parseJson", function(jsonStr:String, varName:String) {
			var json = Paths.modFolders('data/' + jsonStr + '.json');
			var foundJson:Bool;

			#if sys
				if (FileSystem.exists(json)) foundJson = true;
				else {
					funk.luaTrace('parseJson: Invalid json file path!', false, false, FlxColor.RED);
					foundJson = false;
					return;	
				}
			#else
				if (Assets.exists(json)) foundJson = true;
				else {
					funk.luaTrace('parseJson: Invalid json file path!', false, false, FlxColor.RED);
					foundJson = false;
					return;	
				}
			#end

			if (foundJson) {
				var parsedJson = haxe.Json.parse(File.getContent(json));				
				PlayState.instance.variables.set(varName, parsedJson);
			}
		});

		// String tools
		funk.addCallback("stringStartsWith", function(str:String, start:String) {
			return str.startsWith(start);
		});
		funk.addCallback("stringEndsWith", function(str:String, end:String) {
			return str.endsWith(end);
		});
		funk.addCallback("stringSplit", function(str:String, split:String) {
			return str.split(split);
		});
		funk.addCallback("stringTrim", function(str:String) {
			return str.trim();
		});

		// Regex
		funk.addCallback("regexMatch", function(str:String, toMatch:String, flag:String = "i") {
			return new EReg(str, flag).match(toMatch);
		});
		funk.addCallback("regexSubMatch", function(str:String, toMatch:String, pos:Int, len:Int = -1, flag:String = "i") {
			return new EReg(str, flag).matchSub(toMatch, pos, len);
		});
		funk.addCallback("regexFindMatchAt", function(str:String, toMatch:String, n:Int, flag:String = "i") {
			var theData = new EReg(str, flag);
			theData.match(toMatch);
			return theData.matched(n);
		});
		funk.addCallback("regexFindFirstMatch", function(str:String, toMatch:String, flag:String = "i") {
			var theData = new EReg(str, flag);
			theData.match(toMatch);
			return theData.matchedLeft();
		});
		funk.addCallback("regexFindLastMatch", function(str:String, toMatch:String, flag:String = "i") {
			var theData = new EReg(str, flag);
			theData.match(toMatch);
			return theData.matchedRight();
		});
		funk.addCallback("regexMatchPosition", function(str:String, toMatch:String, flag:String = "i") {
			var data = new EReg(str, flag);
			data.match(toMatch);
			var theData = data.matchedPos();
			return [theData.pos, theData.len];
		});
		funk.addCallback("regexReplace", function(str:String, toReplace:String, replacement:String, flag:String = "i") {
			return new EReg(str, flag).replace(toReplace, replacement);
		});
		funk.addCallback("regexSplit", function(str:String, toSplit:String, flag:String = "i") {
			return new EReg(str, flag).split(toSplit);
		});

		// Randomization
		funk.addCallback("getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Int> = [];
			for (i in 0...excludeArray.length)
				toExclude.push(Std.parseInt(excludeArray[i].trim()));
			return FlxG.random.int(min, max, toExclude);
		});
		funk.addCallback("getRandomFloat", function(min:Float, max:Float = 1, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Float> = [];
			for (i in 0...excludeArray.length)
				toExclude.push(Std.parseFloat(excludeArray[i].trim()));
			return FlxG.random.float(min, max, toExclude);
		});
		funk.addCallback("getRandomBool", function(chance:Float = 50) {
			return FlxG.random.bool(chance);
		});

		funk.addCallback("getGameplayChangerValue", function(tag:String) {
			return ClientPrefs.getGameplaySetting(tag, false);
		});
	}
}