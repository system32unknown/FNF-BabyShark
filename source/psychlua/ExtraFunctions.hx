package psychlua;

import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSave;
import openfl.utils.Assets;

//
// Things to trivialize some dumb stuff like splitting strings on older Lua
//
class ExtraFunctions {
	public static function implement(funk:FunkinLua) {
		// Keyboard
		funk.set("keyboardJustPressed", (name:String) -> return Reflect.getProperty(FlxG.keys.justPressed, name.toUpperCase()));
		funk.set("keyboardPressed", (name:String) -> return Reflect.getProperty(FlxG.keys.pressed, name.toUpperCase()));
		funk.set("keyboardReleased", (name:String) -> return Reflect.getProperty(FlxG.keys.justReleased, name.toUpperCase()));

		funk.set("firstKeyJustPressed", () -> {
			var result:String = cast (FlxG.keys.firstJustPressed(), FlxKey).toString();
			if (result == null || result.length < 1) result = "NONE";
			return result;
		});
		funk.set("firstKeyPressed", () -> {
			var result:String = cast (FlxG.keys.firstPressed(), FlxKey).toString();
			if (result == null || result.length < 1) result = "NONE";
			return result;
		});
		funk.set("firstKeyJustReleased", () -> {
			var result:String = cast (FlxG.keys.firstJustReleased(), FlxKey).toString();
			if (result == null || result.length < 1) result = "NONE";
			return result;
		});

		funk.set("keyJustPressed", (name:String = '') -> {
			name = name.toLowerCase();
			return switch(name) {
				case 'left': PlayState.instance.controls.NOTE_LEFT_P;
				case 'down': PlayState.instance.controls.NOTE_DOWN_P;
				case 'up': PlayState.instance.controls.NOTE_UP_P;
				case 'right': PlayState.instance.controls.NOTE_RIGHT_P;
				default: PlayState.instance.controls.justPressed(name);
			}
			return false;
		});
		funk.set("keyPressed", (name:String = '') -> {
			name = name.toLowerCase();
			return switch(name) {
				case 'left': PlayState.instance.controls.NOTE_LEFT;
				case 'down': PlayState.instance.controls.NOTE_DOWN;
				case 'up': PlayState.instance.controls.NOTE_UP;
				case 'right': PlayState.instance.controls.NOTE_RIGHT;
				default: PlayState.instance.controls.pressed(name);
			}
			return false;
		});
		funk.set("keyReleased", (name:String = '') -> {
			name = name.toLowerCase();
			return switch(name) {
				case 'left': PlayState.instance.controls.NOTE_LEFT_R;
				case 'down': PlayState.instance.controls.NOTE_DOWN_R;
				case 'up': PlayState.instance.controls.NOTE_UP_R;
				case 'right': PlayState.instance.controls.NOTE_RIGHT_R;
				default: PlayState.instance.controls.justReleased(name);
			}
			return false;
		});

		funk.set("isOfType", (tag:String, cls:String) -> return Std.isOfType(LuaUtils.getObjectDirectly(tag), Type.resolveClass(cls)));

		// Save data management
		funk.set("initSaveData", function(name:String, ?folder:String = 'psychenginemods') {
			if(PlayState.instance.modchartSaves.exists(name)) {
				FunkinLua.luaTrace('initSaveData: Save file already initialized: ' + name);
				return false;
			}
			var save:FlxSave = new FlxSave();
			save.bind(name, '${CoolUtil.getSavePath()}/$folder');
			PlayState.instance.modchartSaves.set(name, save);
			return true;
		});
		funk.set("flushSaveData", function(name:String) {
			if(PlayState.instance.modchartSaves.exists(name)) {
				PlayState.instance.modchartSaves.get(name).flush();
				return true;
			}
			FunkinLua.luaTrace('flushSaveData: Save file not initialized: ' + name, false, false, FlxColor.RED);
			return false;
		});
		funk.set("getDataFromSave", function(name:String, field:String, ?defaultValue:Dynamic = null) {
			if(PlayState.instance.modchartSaves.exists(name)) {
				var saveData = PlayState.instance.modchartSaves.get(name).data;
				if(Reflect.hasField(saveData, field)) return Reflect.field(saveData, field);
				else return defaultValue;
			}
			FunkinLua.luaTrace('getDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
			return defaultValue;
		});
		funk.set("setDataFromSave", function(name:String, field:String, value:Dynamic) {
			if(!PlayState.instance.modchartSaves.exists(name)) {
				FunkinLua.luaTrace('setDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
				return false;
			}
			Reflect.setField(PlayState.instance.modchartSaves.get(name).data, field, value);
			return true;
		});
		funk.set("eraseSaveData", function(name:String) {
			if (PlayState.instance.modchartSaves.exists(name)) {
				PlayState.instance.modchartSaves.get(name).erase();
				return;
			}
			FunkinLua.luaTrace('eraseSaveData: Save file not initialized: ' + name, false, false, FlxColor.RED);
		});

		// File management
		funk.set("checkFileExists", function(filename:String, ?absolute:Bool = false) {
			#if MODS_ALLOWED
			if(absolute) return FileSystem.exists(filename);
			return FileSystem.exists(Paths.getPath(filename, TEXT));
			#else
			if(absolute) return Assets.exists(filename, TEXT);
			return Assets.exists(Paths.getPath(filename, TEXT));
			#end
		});
		funk.set("saveFile", function(path:String, content:String, ?absolute:Bool = false) {
			try {
				if(!absolute) File.saveContent(Paths.mods(path), content);
				else File.saveContent(path, content);
				return true;
			} catch (e:Dynamic) FunkinLua.luaTrace("saveFile: Error trying to save " + path + ": " + e, false, false, FlxColor.RED);
			return false;
		});
		funk.set("deleteFile", function(path:String, ?ignoreModFolders:Bool = false) {
			try {
				var lePath:String = Paths.getPath(path, TEXT, !ignoreModFolders);
				if(Assets.exists(lePath)) {
					FileSystem.deleteFile(lePath);
					return true;
				}
			} catch (e:Dynamic) FunkinLua.luaTrace("deleteFile: Error trying to delete " + path + ": " + e, false, false, FlxColor.RED);
			return false;
		});
		funk.set("getTextFromFile", Paths.getTextFromFile);
		funk.set("directoryFileList", function(folder:String) {
			var list:Array<String> = [];
			#if sys
			if(FileSystem.exists(folder)) {
				for (folder in FileSystem.readDirectory(folder)) {
					if (!list.contains(folder)) list.push(folder);
				}
			}
			#end
			return list;
		});
		funk.set("promptFile", CoolUtil.saveFile);

		funk.set("parseJson", (location:String) -> {
			var parsed:{} = {};
			if (FileSystem.exists(Paths.getPath('data/$location')))
				parsed = tjson.TJSON.parse(File.getContent(Paths.getPath('data/$location')));
			else parsed = tjson.TJSON.parse(location);
			return parsed;
		});

		// String tools
		funk.set("stringStartsWith", StringTools.startsWith);
		funk.set("stringEndsWith", StringTools.endsWith);
		funk.set("stringSplit", (str:String, split:String) -> return str.split(split));
		funk.set("stringTrim", StringTools.trim);

		// Regex
		funk.set("regexMatch", (str:String, toMatch:String, flag:String = "i") -> return new EReg(str, flag).match(toMatch));
		funk.set("regexSubMatch", (str:String, toMatch:String, pos:Int, len:Int = -1, flag:String = "i") -> return new EReg(str, flag).matchSub(toMatch, pos, len));
		funk.set("regexFindMatchAt", function(str:String, toMatch:String, n:Int, flag:String = "i") {
			var theData:EReg = new EReg(str, flag);
			theData.match(toMatch);
			return theData.matched(n);
		});
		funk.set("regexFindFirstMatch", function(str:String, toMatch:String, flag:String = "i") {
			var theData:EReg = new EReg(str, flag);
			theData.match(toMatch);
			return theData.matchedLeft();
		});
		funk.set("regexFindLastMatch", function(str:String, toMatch:String, flag:String = "i") {
			var theData:EReg = new EReg(str, flag);
			theData.match(toMatch);
			return theData.matchedRight();
		});
		funk.set("regexMatchPosition", function(str:String, toMatch:String, flag:String = "i") {
			var data:EReg = new EReg(str, flag);
			data.match(toMatch);
			var theData:{pos:Int, len:Int} = data.matchedPos();
			return [theData.pos, theData.len];
		});
		funk.set("regexReplace", (str:String, toReplace:String, replacement:String, flag:String = "i") -> return new EReg(str, flag).replace(toReplace, replacement));
		funk.set("regexSplit", (str:String, toSplit:String, flag:String = "i") -> return new EReg(str, flag).split(toSplit));

		// Randomization
		funk.set("getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Int> = [];
			for (i in 0...excludeArray.length) {
				if (exclude == '') break;
				toExclude.push(Std.parseInt(excludeArray[i].trim()));
			}
			return FlxG.random.int(min, max, toExclude);
		});
		funk.set("getRandomFloat", function(min:Float, max:Float = 1, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Float> = [];
			for (i in 0...excludeArray.length) {
				if (exclude == '') break;
				toExclude.push(Std.parseFloat(excludeArray[i].trim()));
			}
			return FlxG.random.float(min, max, toExclude);
		});
		funk.set("getRandomBool", FlxG.random.bool);
		funk.set("getFPS", utils.system.FPSUtil.getFPSAdjust);
	}
}