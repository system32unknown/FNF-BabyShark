package psychlua;

#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if MODS_ALLOWED import tjson.TJSON as Json; #end
import flixel.util.FlxSave;
import openfl.utils.Assets;

//
// Things to trivialize some dumb stuff like splitting strings on older Lua
//
class ExtraFunctions {
	public static function implement(funk:FunkinLua) {
		// Keyboard
		funk.addCallback("keyboardJustPressed", function(name:String) {
			return Reflect.getProperty(FlxG.keys.justPressed, name.toUpperCase());
		});
		funk.addCallback("keyboardPressed", function(name:String) {
			return Reflect.getProperty(FlxG.keys.pressed, name.toUpperCase());
		});
		funk.addCallback("keyboardReleased", function(name:String) {
			return Reflect.getProperty(FlxG.keys.justReleased, name.toUpperCase());
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
			if(PlayState.instance.modchartSaves.exists(name)) {
				FunkinLua.luaTrace('initSaveData: Save file already initialized: ' + name);
				return false;
			}
			var save:FlxSave = new FlxSave();
			save.bind(name, '${CoolUtil.getSavePath()}/$folder');
			PlayState.instance.modchartSaves.set(name, save);
			return true;
		});
		funk.addCallback("flushSaveData", function(name:String) {
			if(PlayState.instance.modchartSaves.exists(name)) {
				PlayState.instance.modchartSaves.get(name).flush();
				return true;
			}
			FunkinLua.luaTrace('flushSaveData: Save file not initialized: ' + name, false, false, FlxColor.RED);
			return false;
		});
		funk.addCallback("getDataFromSave", function(name:String, field:String, ?defaultValue:Dynamic = null) {
			if(PlayState.instance.modchartSaves.exists(name)) {
				var saveData = PlayState.instance.modchartSaves.get(name).data;
				if(Reflect.hasField(saveData, field))
					return Reflect.field(saveData, field);
				else return defaultValue;
			}
			FunkinLua.luaTrace('getDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
			return defaultValue;
		});
		funk.addCallback("setDataFromSave", function(name:String, field:String, value:Dynamic) {
			if(!PlayState.instance.modchartSaves.exists(name)) {
				FunkinLua.luaTrace('setDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
				return false;
			}
			Reflect.setField(PlayState.instance.modchartSaves.get(name).data, field, value);
			return true;
		});

		// File management
		funk.addCallback("checkFileExists", function(filename:String, ?absolute:Bool = false) {
			#if MODS_ALLOWED
			if(absolute) return FileSystem.exists(filename);

			var path:String = Paths.modFolders(filename);
			if(FileSystem.exists(path)) return true;
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
				FunkinLua.luaTrace("saveFile: Error trying to save " + path + ": " + e, false, false, FlxColor.RED);
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
				FunkinLua.luaTrace("deleteFile: Error trying to delete " + path + ": " + e, false, false, FlxColor.RED);
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
					if (!list.contains(folder))
						list.push(folder);
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

			if (#if sys FileSystem #else Assets #end.exists(json)) foundJson = true;
			else {
				FunkinLua.luaTrace('parseJson: Invalid json file path!', false, false, FlxColor.RED);
				foundJson = false;
			}

			if (foundJson) {
				var parsedJson = Json.parse(File.getContent(json));				
				PlayState.instance.variables.set(varName, parsedJson);
				return true;
			}
			return false;
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
		funk.addCallback("getFPS", function(type:String, num:Float) {
			return utils.system.FPSUtil.getFPSAdjust(type, num);
		});
	}
}