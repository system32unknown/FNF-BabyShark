package scripting.lua;

#if LUA_ALLOWED
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
using llua.Lua.Lua_helper;
#end

import haxe.Constraints.Function;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.sound.FlxSound;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.display.FlxRuntimeShader;
import substates.GameOverSubstate;
import substates.PauseSubState;
import states.*;
import game.*;
import utils.*;
import utils.system.PlatformUtil;
import shaders.ColorSwap;
import data.WeekData;

#if sys
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
#end

import Type.ValueType;
import ui.DialogueBoxPsych;
import ui.CustomFadeTransition;

class FunkinLua {
	public static var Function_Stop:Dynamic = "##PSYCHLUA_FUNCTIONSTOP";
	public static var Function_Continue:Dynamic = "##PSYCHLUA_FUNCTIONCONTINUE";
	public static var Function_StopLua:Dynamic = "##PSYCHLUA_FUNCTIONSTOPLUA";

	#if LUA_ALLOWED
	public var lua:State = null;
	#end
	public var globalScriptName:String = '';
	public var modDir:String = '';
	public var scriptName:String = '';
	public var closed:Bool = false;

	#if (hscript && HSCRIPT_ALLOWED)
	public static var hscript:HScript;
	#end

	public function new(script:String, ?scriptCode:String) {
		if (!Path.isAbsolute(script)) { // any absoluted paths, fuck it.
			var dirs = (script = format(script)).split('/'), mod = Paths.mods(), index = -1;
			for (i in 0...dirs.length) {
				if (mod.startsWith(dirs[i])) {
					modDir = ((index = i + 1) < dirs.length && Paths.isValidModDir(dirs[index])) ? dirs[index] : '';
					break;
				}
			}
			if (modDir != '' || index != -1)
				globalScriptName = Path.join([for (i in (index + (modDir != '' ? 1 : 0))...dirs.length) dirs[i]]);
		} else globalScriptName = scriptName;
		scriptName = script;

		#if LUA_ALLOWED
		lua = LuaL.newstate();

		var result:Int = LuaL.loadfile(lua, script);
		if (result == Lua.LUA_OK) {
			LuaL.openlibs(lua);
			Lua.init_callbacks(lua);

			Lua.getglobal(lua, "package");
			Lua.pushstring(lua, Paths.getLuaPackagePath());
			Lua.setfield(lua, -2, "path");
			Lua.pop(lua, 1);

			result = Lua.pcall(lua, 0, 0, 0);
		} else {
			var error:String = getErrorMessage();
			#if windows
			lime.app.Application.current.window.alert(error, 'Error on lua script! "$script"');
			#else
			luaTrace('$script\n$error', true, false, FlxColor.RED);
			#end
		}
		#if hscript HScript.initHaxeModule(); #end

		// Lua shit
		set('Function_StopLua', Function_StopLua);
		set('Function_Stop', Function_Stop);
		set('Function_Continue', Function_Continue);
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('inChartEditor', false);
		
		// Song/Week shit
		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.bpm);
		set('scrollSpeed', PlayState.SONG.speed);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', FlxG.sound.music.length);
		set('songName', PlayState.SONG.song);
		set('songPath', Paths.formatToSongPath(PlayState.SONG.song));
		set('startedCountdown', false);
		set('curStage', PlayState.SONG.stage);

		set('isStoryMode', PlayState.isStoryMode);
		set('difficulty', PlayState.storyDifficulty);

		set('difficultyName', Difficulty.getString());
		set('difficultyPath', Paths.formatToSongPath(Difficulty.getString()));
		set('weekRaw', PlayState.storyWeek);
		set('week', WeekData.weeksList[PlayState.storyWeek]);
		set('seenCutscene', PlayState.seenCutscene);

		// Camera poo
		set('cameraX', 0);
		set('cameraY', 0);

		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		// PlayState cringe ass nae nae bullcrap
		set('curBeat', 0);
		set('curStep', 0);
		set('curDecBeat', 0);
		set('curDecStep', 0);

		set('score', 0);
		set('misses', 0);
		set('accuracy', 0);
		set('hits', 0);

		set('defaultMania', PlayState.SONG.mania);

		set('rating', 0);
		set('ratingName', '');
		set('ratingRank', '');
		set('ratingFC', '');
		set('version', Main.engineVersion.version.trim());
		set('commit_hash', Main.COMMIT_HASH.trim());

		set('inGameOver', false);
		set('mustHitSection', false);
		set('altAnim', false);
		set('gfSection', false);

		// Gameplay settings
		set('healthGainMult', PlayState.instance.healthGain);
		set('healthLossMult', PlayState.instance.healthLoss);
		set('playbackRate', PlayState.instance.playbackRate);
		set('instakillOnMiss', PlayState.instance.instakillOnMiss);
		set('botPlay', PlayState.instance.cpuControlled);
		set('practice', PlayState.instance.practiceMode);

		for (i in 0...Note.ammo[PlayState.mania]) {
			set('defaultPlayerStrumX' + i, 0);
			set('defaultPlayerStrumY' + i, 0);
			set('defaultOpponentStrumX' + i, 0);
			set('defaultOpponentStrumY' + i, 0);
		}

		// Default character positions woooo
		set('defaultBoyfriendX', PlayState.instance.BF_X);
		set('defaultBoyfriendY', PlayState.instance.BF_Y);
		set('defaultOpponentX', PlayState.instance.DAD_X);
		set('defaultOpponentY', PlayState.instance.DAD_Y);
		set('defaultGirlfriendX', PlayState.instance.GF_X);
		set('defaultGirlfriendY', PlayState.instance.GF_Y);

		// Character shit
		set('boyfriendName', PlayState.SONG.player1);
		set('dadName', PlayState.SONG.player2);
		set('gfName', PlayState.SONG.gfVersion);

		// Some settings, no jokes
		set('downscroll', ClientPrefs.getPref('downScroll'));
		set('middlescroll', ClientPrefs.getPref('middleScroll'));
		set('framerate', ClientPrefs.getPref('framerate'));
		set('ghostTapping', ClientPrefs.getPref('ghostTapping'));
		set('hideHud', ClientPrefs.getPref('hideHud'));
		set('timeBarType', ClientPrefs.getPref('timeBarType'));
		set('scoreZoom', ClientPrefs.getPref('scoreZoom'));
		set('cameraZoomOnBeat', ClientPrefs.getPref('camZooms'));
		set('flashingLights', ClientPrefs.getPref('flashing'));
		set('noteOffset', ClientPrefs.getPref('noteOffset'));
		set('healthBarAlpha', ClientPrefs.getPref('healthBarAlpha'));
		set('noResetButton', ClientPrefs.getPref('noReset'));
		set('lowQuality', ClientPrefs.getPref('lowQuality'));
		set('shaders', ClientPrefs.getPref('shaders'));
		set('scriptName', scriptName);
		set('isPixelStage', PlayState.isPixelStage);
		set('curStage', PlayState.curStage);
		set('currentModDirectory', Paths.currentModDirectory);

		#if windows
		var os = 'windows';
		#else
		var os = Sys.systemName().toLowerCase();
		#end
		set('buildTarget', os);

		// custom substate
		addCallback("openCustomSubstate", function(name:String, pauseGame:Bool = false) {
			if(pauseGame) {
				PlayState.instance.persistentUpdate = false;
				PlayState.instance.persistentDraw = true;
				PlayState.instance.paused = true;
				if(FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					PlayState.instance.vocals.pause();
				}
			}
			PlayState.instance.openSubState(new CustomSubstate(name));
		});
		addCallback("closeCustomSubstate", function() {
			if(CustomSubstate.instance == null) return false;
			PlayState.instance.closeSubState();
			CustomSubstate.instance = null;
			return true;
		});

		// shader shit
		addCallback("initLuaShader", function(name:String, glslVersion:Int = 120) {
			if(!ClientPrefs.getPref('shaders')) return false;

			#if (!flash && MODS_ALLOWED && sys)
			return initLuaShader(name, glslVersion);
			#else
			luaTrace("initLuaShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		
		addCallback("setSpriteShader", function(obj:String, shader:String) {
			if(!ClientPrefs.getPref('shaders')) return false;

			#if (!flash && MODS_ALLOWED && sys)
			if(!runtimeShaders.exists(shader) && !initLuaShader(shader)) {
				luaTrace('setSpriteShader: Shader $shader is missing!', false, false, FlxColor.RED);
				return false;
			}

			var leObj:FlxSprite = LuaUtils.getVarInstance(obj, true, false);
			if(leObj != null) {
				var arr:Array<String> = runtimeShaders.get(shader);
				leObj.shader = new FlxRuntimeShader(arr[0], arr[1]);
				return true;
			}
			#else
			luaTrace("setSpriteShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		addCallback("removeSpriteShader", function(obj:String) {
			var leObj:FlxSprite = LuaUtils.getVarInstance(obj, true, false);
			if (leObj != null) {
				leObj.shader = null;
				return true;
			}
			return false;
		});

		addCallback("getShaderBool", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getBool(prop) : null;
			#else
			luaTrace("getShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		addCallback("getShaderBoolArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getBoolArray(prop) : null;
			#else
			luaTrace("getShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		addCallback("getShaderInt", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getInt(prop) : null;
			#else
			luaTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		addCallback("getShaderIntArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getIntArray(prop) : null;
			#else
			luaTrace("getShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		addCallback("getShaderFloat", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getFloat(prop) : null;
			#else
			luaTrace("getShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		addCallback("getShaderFloatArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getFloatArray(prop) : null;
			#else
			luaTrace("getShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});

		addCallback("setShaderBool", function(obj:String, prop:String, value:Bool) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setBool(prop, value);
				return true;
			}
			#else
			luaTrace("setShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});
		addCallback("setShaderBoolArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setBoolArray(prop, values);
				return true;
			}
			#else
			luaTrace("setShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});
		addCallback("setShaderInt", function(obj:String, prop:String, value:Int) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setInt(prop, value);
				return true;
			}
			#else
			luaTrace("setShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});
		addCallback("setShaderIntArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setIntArray(prop, values);
				return true;
			}
			#else
			luaTrace("setShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});
		addCallback("setShaderFloat", function(obj:String, prop:String, value:Float) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setFloat(prop, value);
				return true;
			}
			#else
			luaTrace("setShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});
		addCallback("setShaderFloatArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setFloatArray(prop, values);
				return true;
			}
			#else
			luaTrace("setShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});

		addCallback("setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				var value = Paths.image(bitmapdataPath);
				if (value == null || value.bitmap == null) return false;

				shader.setSampler2D(prop, value.bitmap);
				return true;
			}
			#else
			luaTrace("setShaderSampler2D: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});

		addCallback("getRunningScripts", function() {
			var runningScripts:Array<String> = [];
			for (idx in 0...PlayState.instance.luaArray.length)
				runningScripts.push(PlayState.instance.luaArray[idx].scriptName);

			return runningScripts;
		});

		addCallback("setOnLuas", function(?varName:String, ?scriptVar:Dynamic) {
			if (varName == null) {
				#if (linc_luajit >= "0.0.6")
				LuaL.error(lua, "bad argument #1 to 'setOnLuas' (string expected, got nil)");
				#end
				return;
			}
			PlayState.instance.setOnLuas(varName, scriptVar);
		});

		addCallback("callOnLuas", function(?funcName:String, ?args:Array<Dynamic>, ignoreStops = false, ignoreSelf = true, ?exclusions:Array<String>) {
			var scriptName:String = globalScriptName;
			if (ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
			PlayState.instance.callOnLuas(funcName, args, ignoreStops, exclusions);
		});

		addCallback("callScript", function(?luaFile:String, ?funcName:String, ?args:Array<Dynamic>) {
			luaFile = format(luaFile);

			for (luaInstance in PlayState.instance.luaArray) {
				if (luaInstance.globalScriptName == luaFile && !luaInstance.closed)
					return luaInstance.call(funcName, args);
			}

			luaTrace('callScript: The script "${luaFile}" doesn\'t exists nor is active!');
			return null;
		});

		addCallback("callCppUtil", function(platformType:String, ?args:Array<Dynamic>) {
			final trimmedpft = platformType.trim();
			if (args == null) args = [];
			final blackListcpp = ["setDPIAware"];
			if (blackListcpp.contains(trimmedpft)) return null;

			var platFunc = Reflect.field(PlatformUtil, trimmedpft);
			return Reflect.callMethod(null, platFunc, args);
		});

		addCallback("getGlobalFromScript", function(?luaFile:String, ?global:String) { // returns the global from a script
			luaFile = format(luaFile);

			for (luaInstance in PlayState.instance.luaArray) {
				if (luaInstance.globalScriptName == luaFile && !luaInstance.closed) {
					var lua:State = luaInstance.lua;
					Lua.getglobal(lua, global);

					var result:Dynamic = Convert.fromLua(lua, -1);
					Lua.pop(lua, 1);

					return result;
				}
			}
			return null;
		});
		addCallback("setGlobalFromScript", function(luaFile:String, global:String, val:Dynamic) { // returns the global from a script
			luaFile = format(luaFile);

			var got:Bool = false;
			for (luaInstance in PlayState.instance.luaArray) {
				if (luaInstance.globalScriptName == luaFile && !luaInstance.closed) {
					luaInstance.set(global, val);
					got = true;
				}
			}

			if (!got) {
				luaTrace('setGlobalFromScript: The script "${luaFile}" doesn\'t exists nor is active!');
				return false;
			}
			return true;
		});

		addCallback("isRunning", function(luaFile:String) {
			return LuaUtils.isLuaRunning(luaFile);
		});

		addCallback("addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false) { //would be dope asf.
			var cervix = luaFile + ".lua";
			if(luaFile.endsWith(".lua"))cervix=luaFile;
			var doPush = false;
			#if MODS_ALLOWED
			if(FileSystem.exists(Paths.modFolders(cervix))) {
				cervix = Paths.modFolders(cervix);
				doPush = true;
			} else if(FileSystem.exists(cervix)) {
				doPush = true;
			} else {
				cervix = Paths.getPreloadPath(cervix);
				if(FileSystem.exists(cervix)) {
					doPush = true;
				}
			}
			#else
			cervix = Paths.getPreloadPath(cervix);
			if(Assets.exists(cervix)) {
				doPush = true;
			}
			#end

			if(doPush) {
				if(!ignoreAlreadyRunning) {
					for (luaInstance in PlayState.instance.luaArray) {
						if(luaInstance.scriptName == cervix) {
							luaTrace('addLuaScript: The script "' + cervix + '" is already running!');
							return false;
						}
					}
				}
				PlayState.instance.luaArray.push(new FunkinLua(cervix));
				return true;
			}
			luaTrace("addLuaScript: Script doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		addCallback("removeLuaScript", function(luaFile:String) {
			luaFile = format(luaFile);

			var got:Bool = false;
			for (luaInstance in PlayState.instance.luaArray) {
				if (luaInstance.globalScriptName == luaFile && !luaInstance.closed) {
					luaInstance.closed = true;
					got = true;
				}
			}

			if (!got) {
				luaTrace('removeLuaScript: The script "${luaFile}" doesn\'t exists nor is active!');
				return false;
			}
			return true;
		});

		addCallback("loadSong", function(?name:String = null, ?difficultyNum:Int = -1) {
			if(name == null || name.length <= 0) name = PlayState.SONG.song;
			if (difficultyNum == -1) difficultyNum = PlayState.storyDifficulty;

			var poop = Highscore.formatSong(name, difficultyNum);
			PlayState.SONG = Song.loadFromJson(poop, name);
			PlayState.storyDifficulty = difficultyNum;
			PlayState.instance.persistentUpdate = false;
			LoadingState.loadAndSwitchState(new PlayState());

			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;
			if(PlayState.instance.vocals != null) {
				PlayState.instance.vocals.pause();
				PlayState.instance.vocals.volume = 0;
			}
		});

		addCallback("loadGraphic", function(variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0) {
			var spr:FlxSprite = LuaUtils.getVarInstance(variable);

			if (spr == null || image == null || image.length <= 0) return false;
			var animated = gridX != 0 || gridY != 0;

			spr.loadGraphic(Paths.image(image), animated, gridX, gridY);
			return true;
		});
		addCallback("loadFrames", function(variable:String, image:String, spriteType:String = "sparrow") {
			var spr:FlxSprite = LuaUtils.getVarInstance(variable);
			if (spr == null || image == null || image.length <= 0) return false;

			LuaUtils.loadFrames(spr, image, spriteType);
			return true;
		});

		addCallback("getPref", function(pref:String, ?defaultValue:Dynamic) {
			return ClientPrefs.getPref(pref, defaultValue);
		});
		addCallback("setPref", function(pref:String, ?value:Dynamic = null) {
			ClientPrefs.prefs.set(pref, value);
		});

		addCallback("getProperty", function(variable:String) {
			var result:Dynamic = null;
			var killMe:Array<String> = variable.split('.');
			if (killMe.length > 1)
				result = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1]);
			else result = LuaUtils.getVarInArray(LuaUtils.getTargetInstance(), variable);

			return result;
		});
		addCallback("setProperty", function(variable:String, value:Dynamic) {
			var killMe:Array<String> = variable.split('.');
			if (killMe.length > 1) {
				LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1], value);
				return true;
			}
			LuaUtils.setVarInArray(LuaUtils.getTargetInstance(), variable, value);
			return true;
		});
		addCallback("getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic) {
			var shitMyPants:Array<String> = obj.split('.');
			var realObject:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if(shitMyPants.length > 1)
				realObject = LuaUtils.getPropertyLoop(shitMyPants, true, false);

			if (Std.isOfType(realObject, FlxTypedGroup)) {
				return LuaUtils.getGroupStuff(realObject.members[index], variable);
			}

			var leArray:Dynamic = realObject[index];
			if (leArray != null) {
				var result:Dynamic = null;
				if(Type.typeof(variable) == ValueType.TInt)
					result = leArray[variable];
				else result = LuaUtils.getGroupStuff(leArray, variable);
				return result;
			}
			luaTrace("Object #" + index + " from group: " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		addCallback("setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic) {
			var shitMyPants:Array<String> = obj.split('.');
			var realObject:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if (shitMyPants.length > 1)
				realObject = LuaUtils.getPropertyLoop(shitMyPants, true, false);

			if (Std.isOfType(realObject, FlxTypedGroup)) {
				LuaUtils.setGroupStuff(realObject.members[index], variable, value);
				return;
			}

			var leArray:Dynamic = realObject[index];
			if(leArray != null) {
				if(Type.typeof(variable) == ValueType.TInt) {
					leArray[variable] = value;
					return;
				}
				LuaUtils.setGroupStuff(leArray, variable, value);
			}
		});
		addCallback("removeFromGroup", function(obj:String, index:Int, dontDestroy:Bool = false) {
			if(Std.isOfType(Reflect.getProperty(LuaUtils.getTargetInstance(), obj), FlxTypedGroup)) {
				var sex = Reflect.getProperty(LuaUtils.getTargetInstance(), obj).members[index];
				if(!dontDestroy) sex.kill();
				Reflect.getProperty(LuaUtils.getTargetInstance(), obj).remove(sex, true);
				if(!dontDestroy) sex.destroy();
				return;
			}
			Reflect.getProperty(LuaUtils.getTargetInstance(), obj).remove(Reflect.getProperty(LuaUtils.getTargetInstance(), obj)[index]);
		});

		addCallback("getPropertyFromClass", function(classVar:String, variable:String) {
			@:privateAccess
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1) {
				var coverMeInPiss:Dynamic = LuaUtils.getVarInArray(Type.resolveClass(classVar), killMe[0]);
				for (i in 1...killMe.length - 1) {
					coverMeInPiss = LuaUtils.getVarInArray(coverMeInPiss, killMe[i]);
				}
				return LuaUtils.getVarInArray(coverMeInPiss, killMe[killMe.length - 1]);
			}
			if (classVar == 'ClientPrefs') {
				var pref:Dynamic = ClientPrefs.getPref(variable);
				if (pref != null) return pref;
			}
			return LuaUtils.getVarInArray(Type.resolveClass(classVar), variable);
		});
		addCallback("setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic) {
			@:privateAccess
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1) {
				var coverMeInPiss:Dynamic = LuaUtils.getVarInArray(Type.resolveClass(classVar), killMe[0]);
				for (i in 1...killMe.length - 1) {
					coverMeInPiss = LuaUtils.getVarInArray(coverMeInPiss, killMe[i]);
				}
				LuaUtils.setVarInArray(coverMeInPiss, killMe[killMe.length - 1], value);
				return true;
			}
			if (classVar == 'ClientPrefs') {
				if (ClientPrefs.prefs.exists(variable)) {
					ClientPrefs.prefs.set(variable, value);
					return true;
				}
			}
			LuaUtils.setVarInArray(Type.resolveClass(classVar), variable, value);
			return true;
		});

		addCallback("callFromObject", function(variable:String, ?arguments:Array<Dynamic>) {
			if (arguments != null) arguments = [];
			var result:Dynamic = null;
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1)
				result = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1]);
			else result = LuaUtils.getVarInArray(LuaUtils.getTargetInstance(), variable);
			return Reflect.callMethod(null, result, arguments);
		});
		addCallback("callFromClass", function(classVar:String, variable:String, ?arguments:Array<Dynamic>) {
			if (arguments != null) arguments = [];
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1) {
				var coverMeInPiss:Dynamic = LuaUtils.getVarInArray(Type.resolveClass(classVar), killMe[0]);
				for (i in 1...killMe.length - 1) {
					coverMeInPiss = LuaUtils.getVarInArray(coverMeInPiss, killMe[i]);
				}
				return Reflect.callMethod(null, LuaUtils.getVarInArray(coverMeInPiss, killMe[killMe.length - 1]), arguments);
			}
			return Reflect.callMethod(null, LuaUtils.getVarInArray(Type.resolveClass(classVar), variable), arguments);
		});

		//shitass stuff for epic coders like me B)  *image of obama giving himself a medal*
		addCallback("getObjectOrder", function(obj:String) {
			var poop:FlxBasic = LuaUtils.getVarInstance(obj);
			if (poop != null) return LuaUtils.getTargetInstance().members.indexOf(poop);
			return -1;
		});
		addCallback("setObjectOrder", function(obj:String, position:Int) {
			var poop:FlxBasic = LuaUtils.getVarInstance(obj);
			if (poop == null) return false;

			LuaUtils.getTargetInstance().remove(poop, true);
			LuaUtils.getTargetInstance().insert(position, poop);
			return true;
		});

		// gay ass tweens
		addCallback("startTween", function(tag:String, vars:String, values:Any = null, duration:Float, options:Any = null) {
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(penisExam != null) {
				if(values != null) {
					var myOptions:LuaUtils.LuaTweenOptions = LuaUtils.getLuaTween(options);
					PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, values, duration, {
						type: myOptions.type,
						ease: myOptions.ease,
						startDelay: myOptions.startDelay,
						loopDelay: myOptions.loopDelay,

						onUpdate: function(twn:FlxTween) {
							if(myOptions.onUpdate != null) PlayState.instance.callOnLuas(myOptions.onUpdate, [tag, vars]);
						}, onStart: function(twn:FlxTween) {
							if(myOptions.onStart != null) PlayState.instance.callOnLuas(myOptions.onStart, [tag, vars]);
						}, onComplete: function(twn:FlxTween) {
							if(myOptions.onComplete != null) PlayState.instance.callOnLuas(myOptions.onComplete, [tag, vars]);
							if(twn.type == FlxTweenType.ONESHOT || twn.type == FlxTweenType.BACKWARD) PlayState.instance.modchartTweens.remove(tag);
						}
					}));
				} else luaTrace('startTween: No values on 2nd argument!', false, false, FlxColor.RED);
			} else luaTrace('startTween: Couldnt find object: ' + vars, false, false, FlxColor.RED);
		});
		addCallback("doTween", function(tag:String, variable:String, fieldsNValues:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, variable);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, fieldsNValues, duration * PlayState.instance.playbackRate, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else luaTrace('doTween: Couldnt find object: ' + variable, false, false, FlxColor.RED);
		});
		addCallback("doTweenAdvAngle", function(tag:String, vars:String, value:Array<Float>, duration:Float, ease:String) {
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.angle(penisExam, value[0], value[1], duration * PlayState.instance.playbackRate, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else luaTrace('doTweenAdvAngle: Couldnt find object: ' + vars, false, false, FlxColor.RED);
		});
		addCallback("doTweenColor", function(tag:String, vars:String, targetColor:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(penisExam != null) {
				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;
				PlayState.instance.modchartTweens.set(tag, FlxTween.color(penisExam, duration * PlayState.instance.playbackRate, curColor, targetColor, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.modchartTweens.remove(tag);
						PlayState.instance.callOnLuas('onTweenCompleted', [tag, vars]);
					}
				}));
			} else luaTrace('doTweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
		});

		// bisexual note tween
		addCallback("noteTween", function(tag:String, note:Int, fieldsNValues:Dynamic, duration:Float, ease:String) {
			LuaUtils.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, fieldsNValues, duration * PlayState.instance.playbackRate, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		addCallback("mouseClicked", function(button:String) {
			return switch(button.trim().toLowerCase()) {
				case 'middle': FlxG.mouse.justPressedMiddle;
				case 'right': FlxG.mouse.justPressedRight;
				default: FlxG.mouse.justPressed;
			}
		});
		addCallback("mousePressed", function(button:String) {
			return switch(button.trim().toLowerCase()) {
				case 'middle': FlxG.mouse.pressedMiddle;
				case 'right': FlxG.mouse.pressedRight;
				default: FlxG.mouse.pressed;
			}
		});
		addCallback("mouseReleased", function(button:String) {
			return switch(button.trim().toLowerCase()) {
				case 'middle': FlxG.mouse.justReleasedMiddle;
				case 'right': FlxG.mouse.justReleased;
				default: FlxG.mouse.justReleased;
			}
		});

		addCallback("cancelTween", function(tag:String) {
			LuaUtils.cancelTween(tag);
		});

		addCallback("runTimer", function(tag:String, time:Float = 1, loops:Int = 1) {
			LuaUtils.cancelTimer(tag);
			PlayState.instance.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer) {
				if(tmr.finished) {
					PlayState.instance.modchartTimers.remove(tag);
				}
				PlayState.instance.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
			}, loops));
		});
		addCallback("cancelTimer", function(tag:String) {
			LuaUtils.cancelTimer(tag);
		});

		//stupid bietch ass functions
		addCallback("addScore", function(value:Int = 0) {
			PlayState.instance.songScore += value;
			PlayState.instance.RecalculateRating();
		});
		addCallback("addMisses", function(value:Int = 0) {
			PlayState.instance.songMisses += value;
			PlayState.instance.RecalculateRating();
		});
		addCallback("addHits", function(value:Int = 0) {
			PlayState.instance.songHits += value;
			PlayState.instance.RecalculateRating();
		});
		addCallback("setScore", function(value:Int = 0) {
			PlayState.instance.songScore = value;
			PlayState.instance.RecalculateRating();
		});
		addCallback("setMisses", function(value:Int = 0) {
			PlayState.instance.songMisses = value;
			PlayState.instance.RecalculateRating();
		});
		addCallback("setHits", function(value:Int = 0) {
			PlayState.instance.songHits = value;
			PlayState.instance.RecalculateRating();
		});
		addCallback("getScore", function() {
			return PlayState.instance.songScore;
		});
		addCallback("getMisses", function() {
			return PlayState.instance.songMisses;
		});
		addCallback("getAccuracy", function() {
			return PlayState.instance.accuracy;
		});
		addCallback("getHits", function() {
			return PlayState.instance.songHits;
		});

		addCallback("getHighscore", function(song:String, diff:Int) {
			return Highscore.getScore(song, diff);
		});
		addCallback("getSavedRating", function(song:String, diff:Int) {
			return Highscore.getRating(song, diff);
		});
		addCallback("getWeekScore", function(week:String, diff:Int) {
			return Highscore.getWeekScore(week, diff);
		});

		addCallback("setHealth", function(value:Float = 0) {
			PlayState.instance.health = value;
		});
		addCallback("addHealth", function(value:Float = 0) {
			PlayState.instance.health += value;
		});
		addCallback("getHealth", function() {
			return PlayState.instance.health;
		});

		addCallback("FlxColor", function(?color:String = '') { return LuaUtils.getColorByString(color); });
		addCallback("getColorFromName", function(?color:String = '') { return LuaUtils.getColorByString(color); });

		addCallback("getColorFromHex", function(color:String) {
			return FlxColor.fromString(color);
		});
		addCallback("getColorFromRgb", function(rgb:Array<Int>) {
			return FlxColor.fromRGB(rgb[0], rgb[1], rgb[2]);
		});
		addCallback("getDominantColor", function(tag:String) {
			if (tag == null) return 0;
			return CoolUtil.dominantColor(LuaUtils.getObjectDirectly(tag));
		});

		addCallback("addCharacterToList", function(name:String, type:String) {
			var charType:Int = 0;
			switch(type.toLowerCase()) {
				case 'dad': charType = 1;
				case 'gf' | 'girlfriend': charType = 2;
			}
			PlayState.instance.addCharacterToList(name, charType);
		});
		addCallback("precacheImage", function(name:String) {
			Paths.returnGraphic(name);
		});
		addCallback("precacheSound", function(name:String) {
			Paths.sound(name);
		});
		addCallback("precacheMusic", function(name:String) {
			Paths.music(name);
		});

		addCallback("triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic) {
			var value1:String = arg1;
			var value2:String = arg2;
			PlayState.instance.triggerEventNote(name, value1, value2, Conductor.songPosition);
			return true;
		});

		addCallback("startCountdown", function() {
			PlayState.instance.startCountdown();
			return true;
		});
		addCallback("endSong", function() {
			PlayState.instance.KillNotes();
			PlayState.instance.endSong();
			return true;
		});
		addCallback("restartSong", function(?skipTransition:Bool = false) {
			PlayState.instance.persistentUpdate = false;
			PauseSubState.restartSong(skipTransition);
			return true;
		});
		addCallback("exitSong", function(?skipTransition:Bool = false) {
			if(skipTransition) {
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
			}

			PlayState.cancelMusicFadeTween();
			CustomFadeTransition.nextCamera = PlayState.instance.camOther;
			if(FlxTransitionableState.skipNextTransIn)
				CustomFadeTransition.nextCamera = null;

			if(PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else MusicBeatState.switchState(new FreeplayState());

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
			PlayState.instance.transitioning = true;
			WeekData.loadTheFirstEnabledMod();
			return true;
		});
		addCallback("getSongPosition", function() {
			return Conductor.songPosition;
		});

		addCallback("getCharacterX", function(type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent': return PlayState.instance.dadGroup.x;
				case 'gf' | 'girlfriend': return PlayState.instance.gfGroup.x;
				default: return PlayState.instance.boyfriendGroup.x;
			}
		});
		addCallback("setCharacterX", function(type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent': PlayState.instance.dadGroup.x = value;
				case 'gf' | 'girlfriend': PlayState.instance.gfGroup.x = value;
				default: PlayState.instance.boyfriendGroup.x = value;
			}
		});
		addCallback("getCharacterY", function(type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent': return PlayState.instance.dadGroup.y;
				case 'gf' | 'girlfriend': return PlayState.instance.gfGroup.y;
				default: return PlayState.instance.boyfriendGroup.y;
			}
		});
		addCallback("setCharacterY", function(type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent': PlayState.instance.dadGroup.y = value;
				case 'gf' | 'girlfriend': PlayState.instance.gfGroup.y = value;
				default: PlayState.instance.boyfriendGroup.y = value;
			}
		});

		addCallback("changeMania", function(newValue:Int, skipTwn:Bool = false) {
			PlayState.instance.changeMania(newValue, skipTwn);
		});
		addCallback("generateStaticArrows", function(player:Int) {
			PlayState.instance.generateStaticArrows(player);
		});

		addCallback("cameraSetTarget", function(target:String) {
			PlayState.instance.moveCamera(target);
		});
		addCallback("cameraShake", function(camera:String, intensity:Float, duration:Float) {
			LuaUtils.cameraFromString(camera).shake(intensity, duration * PlayState.instance.playbackRate);
		});

		addCallback("cameraFlash", function(camera:String, color:Dynamic, duration:Float, forced:Bool) {
			LuaUtils.cameraFromString(camera).flash(color, duration * PlayState.instance.playbackRate, null, forced);
		});
		addCallback("cameraFade", function(camera:String, color:Dynamic, duration:Float, forced:Bool) {
			LuaUtils.cameraFromString(camera).fade(color, duration * PlayState.instance.playbackRate, false, null, forced);
		});
		addCallback("setRatingPercent", function(value:Float) {
			PlayState.instance.ratingPercent = value;
		});
		addCallback("setRatingName", function(value:String) {
			PlayState.instance.ratingName = value;
		});
		addCallback("setRatingFC", function(value:String) {
			PlayState.instance.ratingFC = value;
		});
		addCallback("getMouseX", function(camera:String) {
			return FlxG.mouse.getScreenPosition(LuaUtils.cameraFromString(camera)).x;
		});
		addCallback("getMouseY", function(camera:String) {
			return FlxG.mouse.getScreenPosition(LuaUtils.cameraFromString(camera)).y;
		});

		addCallback("getMidpointX", function(obj:String) {
			var obj:FlxObject = LuaUtils.getVarInstance(obj);
			if (obj != null) return obj.getMidpoint().x;
			return 0;
		});
		addCallback("getMidpointY", function(obj:String) {
			var obj:FlxObject = LuaUtils.getVarInstance(obj);
			if (obj != null) return obj.getMidpoint().y;
			return 0;
		});
		addCallback("getGraphicMidpointX", function(obj:String) {
			var spr:FlxSprite  = LuaUtils.getVarInstance(obj);
			if (spr != null) return spr.getGraphicMidpoint().x;
			return 0;
		});
		addCallback("getGraphicMidpointY", function(obj:String) {
			var spr:FlxSprite  = LuaUtils.getVarInstance(obj);
			if (spr != null) return spr.getGraphicMidpoint().y;
			return 0;
		});
		addCallback("getScreenPositionX", function(obj:String) {
			var poop:FlxObject = LuaUtils.getVarInstance(obj);
			if (poop != null) return poop.getScreenPosition().x;
			return 0;
		});
		addCallback("getScreenPositionY", function(obj:String) {
			var poop:FlxObject = LuaUtils.getVarInstance(obj);
			if (poop != null) return poop.getScreenPosition().y;
			return 0;
		});
		addCallback("characterDance", function(character:String) {
			switch(character.toLowerCase()) {
				case 'dad': PlayState.instance.dad.dance();
				case 'gf' | 'girlfriend': if(PlayState.instance.gf != null) PlayState.instance.gf.dance();
				default: PlayState.instance.boyfriend.dance();
			}
		});

		addCallback("makeLuaSprite", function(tag:String, image:String, x:Float, y:Float) {
			tag = tag.replace('.', '');
			LuaUtils.resetSpriteTag(tag);

			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if(image != null && image.length > 0) leSprite.loadGraphic(Paths.image(image));
			leSprite.antialiasing = ClientPrefs.getPref('globalAntialiasing');

			PlayState.instance.modchartSprites.set(tag, leSprite);
		});
		addCallback("makeAnimatedLuaSprite", function(tag:String, image:String, x:Float, y:Float, ?spriteType:String = "sparrow") {
			tag = tag.replace('.', '');
			LuaUtils.resetSpriteTag(tag);

			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			leSprite.antialiasing = ClientPrefs.getPref('globalAntialiasing');
			LuaUtils.loadFrames(leSprite, image, spriteType);
			
			PlayState.instance.modchartSprites.set(tag, leSprite);
		});
		addCallback("makeLuaSpriteGroup", function(tag:String, ?x:Float = 0, ?y:Float = 0, ?maxSize:Int = 0) {
			tag = tag.replace('.', '');
			LuaUtils.resetSpriteTag(tag);

			var leGroup:ModchartGroup = new ModchartGroup(x, y, maxSize);
			PlayState.instance.modchartGroups.set(tag, leGroup);
		});

		addCallback("makeGraphic", function(obj:String, width:Int, height:Int, color:Dynamic) {
			var spr:FlxSprite = LuaUtils.getVarInstance(obj, true, false);

			if (spr == null) return false;
			spr.makeGraphic(width, height, color);
			return true;
		});
		addCallback("addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			if(PlayState.instance.getLuaObject(obj, false) != null) {
				var cock:FlxSprite = PlayState.instance.getLuaObject(obj,false);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
				return;
			}

			var cock:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if(cock != null) {
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});

		addCallback("addAnimation", function(obj:String, name:String, frames:Array<Int>, framerate:Int = 24, loop:Bool = true) {
			if(PlayState.instance.getLuaObject(obj, false) != null) {
				var cock:FlxSprite = PlayState.instance.getLuaObject(obj,false);
				cock.animation.add(name, frames, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
				return;
			}

			var cock:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if(cock != null) {
				cock.animation.add(name, frames, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});

		addCallback("addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, loop:Bool = false) {
			return addAnimByIndices(obj, name, prefix, indices, framerate, loop);
		});

		addCallback("playAnim", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0) {
			if(PlayState.instance.getLuaObject(obj, false) != null) {
				var luaObj:FlxSprite = PlayState.instance.getLuaObject(obj,false);
				if(luaObj.animation.getByName(name) != null) {
					luaObj.animation.play(name, forced, reverse, startFrame);
					if(Std.isOfType(luaObj, ModchartSprite)) {
						//convert luaObj to ModchartSprite
						var obj:Dynamic = luaObj;
						var luaObj:ModchartSprite = obj;

						var daOffset = luaObj.animOffsets.get(name);
						if (luaObj.animOffsets.exists(name)) {
							luaObj.offset.set(daOffset[0], daOffset[1]);
						}
					}
				}
				return true;
			}

			var spr:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if(spr != null) {
				if(spr.animation.getByName(name) != null) {
					if(Std.isOfType(spr, Character)) {
						//convert spr to Character
						var obj:Dynamic = spr;
						var spr:Character = obj;
						spr.playAnim(name, forced, reverse, startFrame);
					} else spr.animation.play(name, forced, reverse, startFrame);
				}
				return true;
			}
			return false;
		});
		addCallback("playAnimGroup", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0) {
			var leGroup:ModchartGroup = PlayState.instance.modchartGroups.get(obj);
			if (leGroup != null) {
				leGroup.forEach(function(spr:ModchartSprite) {
					var offsetX:Float = 0;
					var offsetY:Float = 0;

					if (spr.animOffsets.exists(name)) {
						offsetX = spr.animOffsets.get(name)[0];
						offsetY = spr.animOffsets.get(name)[1];
					}

					if (spr.animation.getByName(name) != null) {
						spr.animation.play(name, forced, reverse, startFrame);
						spr.offset.set(offsetX, offsetY);
					}
				});
				return true;	
			}
			return false;
		});
		addCallback("addOffset", function(obj:String, anim:String, x:Float, y:Float) {
			if(PlayState.instance.modchartSprites.exists(obj)) {
				PlayState.instance.modchartSprites.get(obj).animOffsets.set(anim, [x, y]);
				return true;
			}

			var char:Character = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if(char != null) {
				char.addOffset(anim, x, y);
				return true;
			}
			return false;
		});

		addCallback("setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float) {
			var obj:FlxObject = LuaUtils.getVarInstance(obj);
			if (obj == null) return false;

			obj.scrollFactor.set(scrollX, scrollY);
			return true;
		});
		addCallback("setGroupScrollFactor", function(obj:String, ?scrollX:Float = 0, ?scrollY:Float = 0) {
			var leGroup:ModchartGroup = PlayState.instance.modchartGroups.get(obj);
			if (leGroup != null) {	
				leGroup.scrollFactor.set(scrollX, scrollY);
			}
		});

		addCallback("addSpriteToGroup", function(tag:String, spr:String) {
			var leGroup:ModchartGroup = PlayState.instance.modchartGroups.get(tag);
			if (leGroup != null) {
				var leSprite:ModchartSprite = PlayState.instance.modchartSprites.get(spr);
				if (leSprite != null) {
					leGroup.add(leSprite);
				}
			}
		});

		addCallback("addLuaSpriteGroup", function(tag:String, front:Bool = false) {
			var leGroup:ModchartGroup = PlayState.instance.modchartGroups.get(tag);
			if (leGroup != null) {
				if (!leGroup.wasAdded) {
					if (front)
						LuaUtils.getTargetInstance().add(leGroup);
					else {
						if(PlayState.instance.isDead)
							GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), leGroup);
						else {
							var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
							if(PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position)
								position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
							else if(PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position)
								position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
							PlayState.instance.insert(position, leGroup);
						}
					}
					leGroup.wasAdded = true;
				}
			}
		});
		addCallback("addLuaSprite", function(tag:String, front:Bool = false) {
			var shit:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
			if (shit == null || shit.wasAdded) return false;

			if(front) LuaUtils.getTargetInstance().add(shit);
			else {
				if(PlayState.instance.isDead)
					GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), shit);
				else {
					var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
					if(PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position)
						position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
					else if(PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position)
						position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
					PlayState.instance.insert(position, shit);
				}
			}

			return shit.wasAdded = true;
		});
		addCallback("setGraphicSize", function(obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true) {
			var poop:FlxSprite = LuaUtils.getVarInstance(obj);
			if (poop == null) return false;

			poop.setGraphicSize(x, y);
			if (updateHitbox) poop.updateHitbox();
			return true;
		});
		addCallback("setGroupGraphicSize", function(tag:String, x:Int, y:Int = 0, updateHitbox:Bool = true) {
			var leGroup:ModchartGroup = PlayState.instance.modchartGroups.get(tag);
			if (leGroup != null) {
				leGroup.setGraphicSize(x, y);
				if (updateHitbox)
					leGroup.updateHitbox();
			}
		});
		addCallback("scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true) {
			var poop:FlxSprite = LuaUtils.getVarInstance(obj);
			if (poop == null) return false;

			poop.scale.set(x, y);
			if (updateHitbox) poop.updateHitbox();
			return true;
		});
		addCallback("scaleGroup", function(tag:String, x:Float, y:Float, updateHitbox:Bool = true) {
			var leGroup:ModchartGroup = PlayState.instance.modchartGroups.get(tag);
			if (leGroup != null) {
				leGroup.scale.set(x, y);
				if (updateHitbox) leGroup.updateHitbox();
			}
		});
		addCallback("updateGroupHitbox", function(tag:String) {
			var leGroup:ModchartGroup = PlayState.instance.modchartGroups.get(tag);
			if (leGroup != null) {
				leGroup.updateHitbox();	
			}
		});
		addCallback("updateHitbox", function(obj:String) {
			if(PlayState.instance.getLuaObject(obj) != null) {
				var shit:FlxSprite = PlayState.instance.getLuaObject(obj);
				shit.updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if(poop != null) {
				poop.updateHitbox();
				return;
			}
			luaTrace('updateHitbox: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		addCallback("updateHitboxFromGroup", function(group:String, index:Int) {
			if(Std.isOfType(Reflect.getProperty(LuaUtils.getTargetInstance(), group), FlxTypedGroup)) {
				Reflect.getProperty(LuaUtils.getTargetInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(LuaUtils.getTargetInstance(), group)[index].updateHitbox();
		});

		addCallback("centerOffsets", function(obj:String) {
			if(PlayState.instance.getLuaObject(obj) != null) {
				var shit:FlxSprite = PlayState.instance.getLuaObject(obj);
				shit.centerOffsets();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if(poop != null) {
				poop.centerOffsets();
				return;
			}
			luaTrace('centerOffsets: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		addCallback("centerOffsetsFromGroup", function(group:String, index:Int) {
			if(Std.isOfType(Reflect.getProperty(LuaUtils.getTargetInstance(), group), FlxTypedGroup)) {
				Reflect.getProperty(LuaUtils.getTargetInstance(), group).members[index].centerOffsets();
				return;
			}
			Reflect.getProperty(LuaUtils.getTargetInstance(), group)[index].centerOffsets();
		});

		addCallback("removeSpriteFromGroup", function(tag:String, spr:String, destroy:Bool = true) {
			var leGroup:ModchartGroup = PlayState.instance.modchartGroups.get(tag);
			if (leGroup != null) {
				var leSprite:ModchartSprite = PlayState.instance.modchartSprites.get(spr);
				if (leSprite != null && leGroup.members.contains(leSprite)) {
					leGroup.remove(leSprite);
					if (destroy) leGroup.destroy();
				}
			}
		});
		addCallback("removeLuaSprite", function(tag:String, destroy:Bool = true) {
			var pee:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
			if (pee == null) return false;

			if (destroy) pee.kill();
			if (pee.wasAdded) {
				LuaUtils.getTargetInstance().remove(pee, true);
				pee.wasAdded = false;
			}
			if (destroy) {
				pee.destroy();
				PlayState.instance.modchartSprites.remove(tag);
			}
			return true;
		});

		addCallback("setColorSwap", function(obj:String, hue:Float = 0, saturation:Float = 0, brightness:Float = 0) {
			var real = PlayState.instance.getLuaObject(obj);
			var color:ColorSwap = new ColorSwap();
			color.hue = hue;
			color.saturation = saturation;
			color.brightness = brightness;
			if(real != null) {
				real.shader = color.shader;
				return true;
			}

			var object:FlxSprite = LuaUtils.getVarInstance(obj);
			if(object == null) {
				luaTrace("setColorSwap: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
				return false;
			} 
			object.shader = color.shader;
			return true;
		});

		addCallback("stampSprite", function(sprite:String, brush:String, x:Int, y:Int) {
			if(!PlayState.instance.modchartSprites.exists(sprite) || !PlayState.instance.modchartSprites.exists(brush)) return false;

			PlayState.instance.modchartSprites.get(sprite).stamp(PlayState.instance.modchartSprites.get(brush), x, y);
			return true;
		});

		addCallback("luaSpriteExists", function(tag:String) {
			return PlayState.instance.modchartSprites.exists(tag);
		});
		addCallback("luaTextExists", function(tag:String) {
			return PlayState.instance.modchartTexts.exists(tag);
		});
		addCallback("luaSoundExists", function(tag:String) {
			return PlayState.instance.modchartSounds.exists(tag);
		});

		addCallback("setHealthBarColors", function(leftHex:Dynamic, rightHex:Dynamic) {
			var left = leftHex;
			var right = rightHex;

			if (leftHex == null) left = PlayState.instance.dad.getColor();
			if (rightHex == null) right = PlayState.instance.boyfriend.getColor();

			PlayState.instance.healthBar.createFilledBar(left, right);
			PlayState.instance.healthBar.updateBar();
		});
		addCallback("setHealthBarColorsWithGradient", function(leftHex:Array<Dynamic>, rightHex:Array<Dynamic>) {
			var left:Array<FlxColor> = [leftHex[0], leftHex[1]];
			var right:Array<FlxColor> = [rightHex[0], rightHex[1]];

			PlayState.instance.healthBar.createGradientBar(left, right, 1, 90);
			PlayState.instance.healthBar.updateBar();
		});
		addCallback("setTimeBarColors", function(leftHex:Dynamic, rightHex:Dynamic) {
			PlayState.instance.timeBar.createFilledBar(leftHex, rightHex);
			PlayState.instance.timeBar.updateBar();
		});
		addCallback("setTimeBarColorsWithGradient", function(leftHex:Array<Dynamic>, rightHex:Array<Dynamic>) {
			var left:Array<FlxColor> = [leftHex[0], leftHex[1]];
			var right:Array<FlxColor> = [rightHex[0], rightHex[1]];
			
			PlayState.instance.timeBar.createGradientBar(left, right, 1, 90);
			PlayState.instance.timeBar.updateBar();
		});

		addCallback("setObjectCamera", function(obj:String, camera:String = '') {
			var poop:FlxBasic = LuaUtils.getVarInstance(obj);
			if (poop == null) return false;

			poop.cameras = [LuaUtils.cameraFromString(camera)];
			return true;
		});
		addCallback("setBlendMode", function(obj:String, blend:String = '') {
			var spr:FlxSprite = LuaUtils.getVarInstance(obj);
			if (spr == null) return false;

			spr.blend = LuaUtils.blendModeFromString(blend);
			return true;
		});
		addCallback("screenCenterGroup", function(tag:String, pos:String = 'xy') {
			var leGroup:ModchartGroup = PlayState.instance.modchartGroups.get(tag);
			if (leGroup != null) {
				switch (pos.toLowerCase().trim()) {
					case 'x': leGroup.screenCenter(X);
					case 'y': leGroup.screenCenter(Y);
					case 'xy': leGroup.screenCenter();
					default: return;
				}
			}
		});
		addCallback("screenCenter", function(obj:String, pos:String = 'xy') {
			var spr:FlxSprite = LuaUtils.getVarInstance(obj);
			if (spr == null) return false;

			switch(pos.trim().toLowerCase()) {
				case 'x': spr.screenCenter(X);
				case 'y': spr.screenCenter(Y);
				default: spr.screenCenter(XY);
			}
			return true;
		});
		addCallback("objectsOverlap", function(obj1:String, obj2:String) {
			var guh1:FlxBasic = LuaUtils.getVarInstance(obj1), guh2:FlxBasic = LuaUtils.getVarInstance(obj2);
			if (guh1 == null || guh2 == null) return false;
			return FlxG.overlap(guh1, guh2);
		});
		addCallback("getPixelColor", function(obj:String, x:Int, y:Int) {
			var spr:FlxSprite = LuaUtils.getVarInstance(obj);
			if(spr == null) return 0;

			if(spr.framePixels != null) spr.framePixels.getPixel32(x, y);
			return spr.pixels.getPixel32(x, y);
		});

		addCallback("startDialogue", function(dialogueFile:String, music:String = null) {
			var path:String;
			#if MODS_ALLOWED
			path = Paths.modsJson("charts/" + Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);
			if(!FileSystem.exists(path))
			#end
				path = Paths.json("charts/" + Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);
			luaTrace('startDialogue: Trying to load dialogue: ' + path);
			#if MODS_ALLOWED
			if(FileSystem.exists(path))
			#else
			if(Assets.exists(path))
			#end {
				var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
				if(shit.dialogue.length > 0) {
					PlayState.instance.startDialogue(shit, music);
					luaTrace('Successfully loaded dialogue', false, false, FlxColor.GREEN);
					return true;
				} else luaTrace('Your dialogue file is badly formatted!', false, false, FlxColor.RED);
			} else {
				luaTrace('startDialogue: Dialogue file not found', false, false, FlxColor.RED);
				if(PlayState.instance.endingSong)
					PlayState.instance.endSong();
				else PlayState.instance.startCountdown();
			}
			return false;
		});
		addCallback("startVideo", function(videoFile:String) {
			#if VIDEOS_ALLOWED
			if(FileSystem.exists(Paths.video(videoFile))) {
				PlayState.instance.startVideo(videoFile);
				return true;
			}
			
			luaTrace('startVideo: Video file not found: ' + videoFile, false, false, FlxColor.RED);
			return false;

			#else
			PlayState.instance.startAndEnd();
			return true;
			#end
		});
		addCallback("startVideoSprite", function(videoFile:String, x:Float = 0, y:Float = 0, op:Float = 1, cam:String = 'world', ?loop:Bool = false, ?pauseMusic:Bool = false) {
			#if VIDEOS_ALLOWED
			if(FileSystem.exists(Paths.video(videoFile))) {
				PlayState.instance.startVideoSprite(videoFile, x, y, op, cam, loop, pauseMusic);
				return true;
			} else luaTrace('startVideoSprite: Video file not found: ' + videoFile, false, false, FlxColor.RED);
			return false;
			#else
			PlayState.instance.startAndEnd();
			return true;
			#end
		});

		addCallback("playMusic", function(sound:String, volume:Float = 1, loop:Bool = false) {
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});
		addCallback("playSound", function(sound:String, volume:Float = 1, ?tag:String = null) {
			if(tag != null && tag.length > 0) {
				tag = tag.replace('.', '');
				if(PlayState.instance.modchartSounds.exists(tag)) {
					PlayState.instance.modchartSounds.get(tag).stop();
				}
				PlayState.instance.modchartSounds.set(tag, FlxG.sound.play(Paths.sound(sound), volume, false, function() {
					PlayState.instance.modchartSounds.remove(tag);
					PlayState.instance.callOnLuas('onSoundFinished', [tag]);
				}));
				return;
			}
			FlxG.sound.play(Paths.sound(sound), volume);
		});
		addCallback("stopSound", function(tag:String) {
			if(tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).stop();
				PlayState.instance.modchartSounds.remove(tag);
			}
		});
		addCallback("pauseSound", function(tag:String) {
			if(tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).pause();
			}
		});
		addCallback("resumeSound", function(tag:String) {
			if(tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).play();
			}
		});
		addCallback("soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			if(tag == null || tag.length < 1) {
				FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			} else if(PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).fadeIn(duration * PlayState.instance.playbackRate, fromValue, toValue);
			}
		});
		addCallback("soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0) {
			if(tag == null || tag.length < 1) {
				FlxG.sound.music.fadeOut(duration, toValue);
			} else if(PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).fadeOut(duration * PlayState.instance.playbackRate, toValue);
			}
		});
		addCallback("soundFadeCancel", function(tag:String) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music.fadeTween != null) {
					FlxG.sound.music.fadeTween.cancel();
				}
			} else if(PlayState.instance.modchartSounds.exists(tag)) {
				var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);
				if(theSound.fadeTween != null) {
					theSound.fadeTween.cancel();
					PlayState.instance.modchartSounds.remove(tag);
				}
			}
		});
		addCallback("getSoundVolume", function(tag:String) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null)
					return FlxG.sound.music.volume;
			} else if(PlayState.instance.modchartSounds.exists(tag)) {
				return PlayState.instance.modchartSounds.get(tag).volume;
			}
			return 0;
		});
		addCallback("setSoundVolume", function(tag:String, value:Float) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null)
					FlxG.sound.music.volume = value;
			} else if(PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).volume = value;
			}
		});
		addCallback("getSoundTime", function(tag:String) {
			if(tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag))
				return PlayState.instance.modchartSounds.get(tag).time;
			return 0;
		});
		addCallback("setSoundTime", function(tag:String, value:Float) {
			if(tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag)) {
				var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);
				if(theSound != null) theSound.time = value;
			}
		});
		addCallback("getSoundPitch", function(tag:String) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null)
					return FlxG.sound.music.pitch;
			} else if (PlayState.instance.modchartSounds.exists(tag))
				return PlayState.instance.modchartSounds.get(tag).pitch;
			
			return 1;
		});
		addCallback("setSoundPitch", function(tag:String, value:Float = 1) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null)
					FlxG.sound.music.pitch = value;
			} else if (PlayState.instance.modchartSounds.exists(tag)) {
				var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);
				if(theSound != null) theSound.pitch = value;
			}
		});

		addCallback("debugPrint", function(text1:Dynamic = '', text2:Dynamic = '', text3:Dynamic = '', text4:Dynamic = '', text5:Dynamic = '') {
			if (text1 == null) text1 = '';
			if (text2 == null) text2 = '';
			if (text3 == null) text3 = '';
			if (text4 == null) text4 = '';
			if (text5 == null) text5 = '';
			luaTrace(text1 + text2 + text3 + text4 + text5, true, false);
		});
		addCallback("debugPrintArray", function(text:Array<Dynamic>, divider:Dynamic = ' ') {
			var array_text = '';
			if (text == null) text = [];

			for (_text in text) {
				if (_text == null) array_text += '' + divider;
				else array_text += _text + divider;
			}

			luaTrace(array_text, true, false);
		});

		addCallback("close", function() {
			return closed = true;
		});

		addCallback("changePresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
			#if discord_rpc
			DiscordClient.changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
			#end
		});

		// LUA TEXTS
		addCallback("makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float) {
			tag = tag.replace('.', '');
			LuaUtils.resetTextTag(tag);
			PlayState.instance.modchartTexts.set(tag, new ModchartText(x, y, text, width));
		});

		addCallback("setTextString", function(tag:String, text:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.text = text;
				return true;
			}
			luaTrace("setTextString: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		addCallback("setTextSize", function(tag:String, size:Int) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.size = size;
				return true;
			}
			luaTrace("setTextSize: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		addCallback("setTextWidth", function(tag:String, width:Float) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.fieldWidth = width;
				return true;
			}
			luaTrace("setTextWidth: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		addCallback("setTextBorder", function(tag:String, size:Int, color:Dynamic) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.borderSize = size;
				obj.borderColor = color;
				return true;
			}
			luaTrace("setTextBorder: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		addCallback("setTextBorderStyle", function(tag:String, borderStyle:String = 'NONE') {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.borderStyle = NONE;
				switch(borderStyle.trim().toLowerCase()) {
					case 'none': obj.borderStyle = NONE;
					case 'shadow': obj.borderStyle = SHADOW;
					case 'outline': obj.borderStyle = OUTLINE;
					case 'outline_fast': obj.borderStyle = OUTLINE_FAST;
				}
			}
		});
		addCallback("setTextColor", function(tag:String, color:Dynamic) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.color = color;
				return true;
			}
			luaTrace("setTextColor: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		addCallback("setTextFont", function(tag:String, newFont:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.font = Paths.font(newFont);
				return true;
			}
			luaTrace("setTextFont: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		addCallback("setTextItalic", function(tag:String, italic:Bool) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.italic = italic;
				return true;
			}
			luaTrace("setTextItalic: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		addCallback("setTextAlignment", function(tag:String, alignment:String = 'left') {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.alignment = LEFT;
				switch(alignment.trim().toLowerCase()) {
					case 'right': obj.alignment = RIGHT;
					case 'center': obj.alignment = CENTER;
				}
				return true;
			}
			luaTrace("setTextAlignment: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		addCallback("getTextString", function(tag:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null && obj.text != null) {
				return obj.text;
			}
			luaTrace("getTextString: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		addCallback("getTextSize", function(tag:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				return obj.size;
			}
			luaTrace("getTextSize: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return -1;
		});
		addCallback("getTextFont", function(tag:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				return obj.font;
			}
			luaTrace("getTextFont: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		addCallback("getTextWidth", function(tag:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				return obj.fieldWidth;
			}
			luaTrace("getTextWidth: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return 0;
		});

		addCallback("addLuaText", function(tag:String) {
			if(PlayState.instance.modchartTexts.exists(tag)) {
				var shit:ModchartText = PlayState.instance.modchartTexts.get(tag);
				if(!shit.wasAdded) {
					LuaUtils.getTargetInstance().add(shit);
					shit.wasAdded = true;
				}
			}
		});
		addCallback("removeLuaText", function(tag:String, destroy:Bool = true) {
			if(!PlayState.instance.modchartTexts.exists(tag)) return;

			var text:ModchartText = PlayState.instance.modchartTexts.get(tag);
			if(destroy) text.kill();

			if(text.wasAdded) {
				LuaUtils.getTargetInstance().remove(text, true);
				text.wasAdded = false;
			}

			if(destroy) {
				text.destroy();
				PlayState.instance.modchartTexts.remove(tag);
			}
		});

		DeprecatedFunctions.implement(this);
		ExtraFunctions.implement(this);
		#if (hscript && HSCRIPT_ALLOWED) HScript.implement(this); #end

		call('onCreate', []);
		if (closed) return stop();
		#end
	}

	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function getShader(obj:String):FlxRuntimeShader {
		var leObj:FlxSprite = LuaUtils.getVarInstance(obj, true, false);
		if (leObj != null) return cast leObj.shader;
		return null;
	}

	inline public function addCallback(name:String, func:Function) {
		return lua.add_callback(name, func);
	}

	public function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, color:FlxColor = FlxColor.WHITE) {
		#if LUA_ALLOWED
		if(ignoreCheck || getBool('luaDebugMode')) {
			if(deprecated && !getBool('luaDeprecatedWarnings')) return;
			PlayState.instance.addTextToDebug(text, color);
			haxe.Log.trace(text, cast {fileName: scriptName, lineNumber: 0});
		}
		#end
	}

	function getErrorMessage(status:Int = 0):String {
		#if LUA_ALLOWED
		if (lua == null) return null;
		var v:String = Lua.tostring(lua, -1);
		Lua.pop(lua, 1);

		if (v != null) v = v.trim();
		if (v == null || v == "") {
			return switch(status) {
				case Lua.LUA_ERRSYNTAX: "Syntax Error";
				case Lua.LUA_ERRRUN: return "Runtime Error";
				case Lua.LUA_ERRMEM: return "Memory Allocation Error";
				case Lua.LUA_ERRERR: return "Crtical Error";
				default: "Unknown Error";
			}
		}
		return v;
		#else
		return null;
		#end
	}

	public var lastCalledFunction:String = '';
	public function call(func:String, args:Array<Dynamic>):Dynamic {
		#if LUA_ALLOWED
		if (closed) return Function_Continue;
		lastCalledFunction = func;

		Lua.getglobal(lua, func);
		var type:Int = Lua.type(lua, -1);

		if (type != Lua.LUA_TFUNCTION) {
			if (type > Lua.LUA_TNIL)
				luaTrace('ERROR ($func)): attempt to call a ${Lua.typename(lua, type)} value as a callback', false, false, FlxColor.RED);

			Lua.pop(lua, 1);
			return Function_Continue;
		}

		var nargs:Int = 0;
		if (args != null) for (arg in args) {
			if (Convert.toLua(lua, arg)) nargs++;
			else luaTrace('WARNING ($func)): attempt to insert ${Type.typeof(arg)} (unsupported value type) as a argument', false, false, FlxColor.ORANGE);
		}
		var status:Int = Lua.pcall(lua, nargs, 1, 0);

		if (status != Lua.LUA_OK) {
			luaTrace('ERROR ($func)): ${getErrorMessage(status)}', false, false, FlxColor.RED);
			return Function_Continue;
		}

		var resultType:Int = Lua.type(lua, -1);
		if (!resultIsAllowed(resultType)) {
			luaTrace('WARNING ($func): unsupported returned value type ("${Lua.typename(lua, resultType)}")', false, false, FlxColor.ORANGE);
			Lua.pop(lua, 1);
			return Function_Continue;
		}

		var result:Dynamic = cast Convert.fromLua(lua, -1);
		if (result == null) result = Function_Continue;

		Lua.pop(lua, 1);
		return result;
		#else
		return Function_Continue;
		#end
	}

	static function addAnimByIndices(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, loop:Bool = false) {
		var strIndices:Array<String> = indices.trim().split(',');
		var die:Array<Int> = [for (i in 0...strIndices.length) Std.parseInt(strIndices[i])];

		if(PlayState.instance.getLuaObject(obj, false) != null) {
			var pussy:FlxSprite = PlayState.instance.getLuaObject(obj, false);
			pussy.animation.addByIndices(name, prefix, die, '', framerate, loop);
			if(pussy.animation.curAnim == null) pussy.animation.play(name, true);
			return true;
		}

		var pussy:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
		if(pussy != null) {
			pussy.animation.addByIndices(name, prefix, die, '', framerate, loop);
			if(pussy.animation.curAnim == null) pussy.animation.play(name, true);
			return true;
		}
		return false;
	}

	#if LUA_ALLOWED
	inline function resultIsAllowed(type:Int):Bool {
		return type >= Lua.LUA_TNIL && type <= Lua.LUA_TTABLE && type != Lua.LUA_TLIGHTUSERDATA;
	}
	#end

	public function set(variable:String, data:Dynamic) {
		#if LUA_ALLOWED
		if (lua == null) return;

		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
		#end
	}

	#if LUA_ALLOWED
	public function getBool(variable:String) {
		#if LUA_ALLOWED
		if (lua == null) return false;
		Lua.getglobal(lua, variable);

		var result:Bool = Lua.toboolean(lua, -1);
		Lua.pop(lua, 1);

		return result;
		#end
		return false;
	}
	#end

	public function stop() {
		#if (hscript && HSCRIPT_ALLOWED)
		if(hscript != null) hscript = null;
		#end
		PlayState.instance.luaArray.remove(this);
		closed = true;
		#if LUA_ALLOWED
		if(lua == null) return;
		Lua.close(lua);
		lua = null;
		#end
	}

	public static function format(luaFile:String):String {
		return Path.normalize((luaFile = luaFile.toLowerCase()).endsWith('.lua') ? luaFile : '${luaFile}.lua');
	}

	//clone functions
	public function oldTweenFunction(tag:String, vars:String, tweenValue:Any, duration:Float, ease:String, funcName:String) {
		var target:Dynamic = LuaUtils.tweenPrepare(tag, vars);
		if(target != null) {
			PlayState.instance.modchartTweens.set(tag, FlxTween.tween(target, tweenValue, duration, {ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween) {
					PlayState.instance.callOnLuas('onTweenCompleted', [tag, vars]);
					PlayState.instance.modchartTweens.remove(tag);
				}
			}));
		} else luaTrace('$funcName: Couldnt find object: $vars', false, false, FlxColor.RED);
	}
	
	public function initLuaShader(name:String, ?glslVersion:Int = 120) {
		if(!ClientPrefs.getPref('shaders')) return false;

		#if (!flash && sys)
		if(runtimeShaders.exists(name)) {
			luaTrace('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/shaders/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));
		
		for (folder in foldersToCheck) {
			if(FileSystem.exists(folder)) {
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if(FileSystem.exists(frag)) {
					frag = File.getContent(frag);
					found = true;
				} else frag = null;

				if(FileSystem.exists(vert)) {
					vert = File.getContent(vert);
					found = true;
				} else vert = null;

				if(found) {
					runtimeShaders.set(name, [frag, vert]);
					return true;
				}
			}
		}
		luaTrace('Missing shader $name .frag AND .vert files!', false, false, FlxColor.RED);
		#else
		luaTrace('This platform doesn\'t support Runtime Shaders!', false, false, FlxColor.RED);
		#end
		return false;
	}
}