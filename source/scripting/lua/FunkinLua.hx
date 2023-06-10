package scripting.lua;

#if LUA_ALLOWED
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
#end

import haxe.Constraints.Function;
import flixel.FlxBasic;
import flixel.FlxObject;
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

	public function new(script:String) {
		if (!Path.isAbsolute(script)) { // any absoluted paths, fuck it.
			var dirs = (script = format(script)).split('/'), mod = Paths.mods(), index = -1;
			for (i in 0...dirs.length) {
				if (mod.startsWith(dirs[i])) {
					modDir = ((index = i + 1) < dirs.length && Mods.isValidModDir(dirs[index])) ? dirs[index] : '';
					break;
				}
			}
			if (modDir != '' || index != -1)
				globalScriptName = Path.join([for (i in (index + (modDir != '' ? 1 : 0))...dirs.length) dirs[i]]);
		} else globalScriptName = scriptName;
		this.scriptName = script;

		#if LUA_ALLOWED
		lua = LuaL.newstate();

		var result:Int = LuaL.loadfile(lua, scriptName);
		if (result == Lua.LUA_OK) {
			LuaL.openlibs(lua);
			Lua_helper.init_callbacks(lua);
			
			initGlobals();

			Lua_helper.link_extra_arguments(lua, [this]);
			Lua_helper.link_static_callbacks(lua);

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
		#if hscript HScript.initHaxeModule(this); #end

		addCallback("openCustomSubstate", function(_, name:String, pauseGame:Bool = false) {
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
		addCallback("closeCustomSubstate", function(_) {
			if(CustomSubstate.instance == null) return false;
			PlayState.instance.closeSubState();
			CustomSubstate.instance = null;
			return true;
		});

		// shader shit
		addCallback("initLuaShader", function(l:FunkinLua, name:String, glslVersion:Int = 120) {
			if(!ClientPrefs.getPref('shaders')) return false;

			#if (!flash && MODS_ALLOWED && sys)
			return initLuaShader(name, glslVersion);
			#else
			l.luaTrace("initLuaShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		
		addCallback("setSpriteShader", function(l:FunkinLua, obj:String, shader:String) {
			if(!ClientPrefs.getPref('shaders')) return false;

			#if (!flash && MODS_ALLOWED && sys)
			if(!runtimeShaders.exists(shader) && !initLuaShader(shader)) {
				l.luaTrace('setSpriteShader: Shader $shader is missing!', false, false, FlxColor.RED);
				return false;
			}

			var leObj:FlxSprite = LuaUtils.getVarInstance(obj, true, false);
			if(leObj != null) {
				var arr:Array<String> = runtimeShaders.get(shader);
				leObj.shader = new FlxRuntimeShader(arr[0], arr[1]);
				return true;
			}
			#else
			l.luaTrace("setSpriteShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		addCallback("removeSpriteShader", function(_, obj:String) {
			var leObj:FlxSprite = LuaUtils.getVarInstance(obj, true, false);
			if (leObj != null) {
				leObj.shader = null;
				return true;
			}
			return false;
		});

		addCallback("getShaderBool", function(l:FunkinLua, obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getBool(prop) : null;
			#else
			l.luaTrace("getShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		addCallback("getShaderBoolArray", function(l:FunkinLua, obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getBoolArray(prop) : null;
			#else
			l.luaTrace("getShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		addCallback("getShaderInt", function(l:FunkinLua, obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getInt(prop) : null;
			#else
			l.luaTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		addCallback("getShaderIntArray", function(l:FunkinLua, obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getIntArray(prop) : null;
			#else
			l.luaTrace("getShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		addCallback("getShaderFloat", function(l:FunkinLua, obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getFloat(prop) : null;
			#else
			l.luaTrace("getShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		addCallback("getShaderFloatArray", function(l:FunkinLua, obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getFloatArray(prop) : null;
			#else
			l.luaTrace("getShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});

		addCallback("setShaderBool", function(l:FunkinLua, obj:String, prop:String, value:Bool) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setBool(prop, value);
				return true;
			}
			#else
			l.luaTrace("setShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});
		addCallback("setShaderBoolArray", function(l:FunkinLua, obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setBoolArray(prop, values);
				return true;
			}
			#else
			l.luaTrace("setShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});
		addCallback("setShaderInt", function(l:FunkinLua, obj:String, prop:String, value:Int) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setInt(prop, value);
				return true;
			}
			#else
			l.luaTrace("setShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});
		addCallback("setShaderIntArray", function(l:FunkinLua, obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setIntArray(prop, values);
				return true;
			}
			#else
			l.luaTrace("setShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});
		addCallback("setShaderFloat", function(l:FunkinLua, obj:String, prop:String, value:Float) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setFloat(prop, value);
				return true;
			}
			#else
			l.luaTrace("setShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});
		addCallback("setShaderFloatArray", function(l:FunkinLua, obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setFloatArray(prop, values);
				return true;
			}
			#else
			l.luaTrace("setShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});

		addCallback("setShaderSampler2D", function(l:FunkinLua, obj:String, prop:String, bitmapdataPath:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				var value = Paths.image(bitmapdataPath);
				if (value == null || value.bitmap == null) return false;

				shader.setSampler2D(prop, value.bitmap);
				return true;
			}
			#else
			l.luaTrace("setShaderSampler2D: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});

		addCallback("getRunningScripts", function(_) {
			return [for (script in PlayState.instance.luaArray) script];
		});

		addCallback("setOnLuas", function(_, varName:String, scriptVar:Dynamic) {
			if (varName == null) return;
			PlayState.instance.setOnLuas(varName, scriptVar);
		});

		addCallback("callOnLuas", function(l:FunkinLua, funcName:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null) {
			if(funcName == null){
				#if (linc_luajit >= "0.0.6")
				LuaL.error(lua, "bad argument #1 to 'callOnLuas' (string expected, got nil)");
				#end
				return false;
			}

			if(args == null) args = [];
			if(exclusions == null) exclusions = [];

			PlayState.instance.callOnLuas(funcName, args, ignoreStops, exclusions);
			return true;
		});

		addCallback("callScript", function(l:FunkinLua, luaFile:String, funcName:String, args:Array<Dynamic>):Dynamic {
			luaFile = format(luaFile);

			for (luaInstance in PlayState.instance.luaArray) {
				if (luaInstance.globalScriptName == luaFile && !luaInstance.closed)
					return luaInstance.call(funcName, args);
			}

			l.luaTrace('callScript: The script "${luaFile}" doesn\'t exists nor is active!');
			return null;
		});

		addCallback("callCppUtil", function(_, platformType:String, ?args:Array<Dynamic>) {
			final trimmedpft = platformType.trim();
			if (args == null) args = [];
			final blackListcpp = ["setDPIAware"];
			if (blackListcpp.contains(trimmedpft)) return null;

			var platFunc = Reflect.field(PlatformUtil, trimmedpft);
			return Reflect.callMethod(null, platFunc, args);
		});

		addCallback("setGlobalFromScript", function(l:FunkinLua, luaFile:String, global:String, val:Dynamic):Bool {
			luaFile = format(luaFile);

			var got:Bool = false;
			for (luaInstance in PlayState.instance.luaArray) {
				if (luaInstance.globalScriptName == luaFile && !luaInstance.closed) {
					luaInstance.set(global, val);
					got = true;
				}
			}

			if (!got) {
				l.luaTrace('setGlobalFromScript: The script "${luaFile}" doesn\'t exists nor is active!');
				return false;
			}
			return true;
		});
		addCallback("getGlobalFromScript", function(_, luaFile:String, global:String):Dynamic {
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

		addCallback("isRunning", function(_, luaFile:String) {
			return LuaUtils.isLuaRunning(luaFile);
		});

		addCallback("addLuaScript", function(l:FunkinLua, luaFile:String, ?ignoreAlreadyRunning:Bool = false):Bool { //would be dope asf.
			luaFile = format(luaFile);

			if (!ignoreAlreadyRunning && LuaUtils.isLuaRunning(luaFile)) {
				l.luaTrace('addLuaScript: The script "${luaFile}" is already running!');
				return false;
			}

			var res:FunkinLua = PlayState.instance.executeLua(luaFile);
			if (res == null) {
				l.luaTrace('addLuaScript: The script "${luaFile}" doesn\'t exist!', false, false, FlxColor.RED);
				return false;
			}
			return true;
		});
		addCallback("removeLuaScript", function(l:FunkinLua, luaFile:String):Bool {
			luaFile = format(luaFile);

			var got:Bool = false;
			for (luaInstance in PlayState.instance.luaArray) {
				if (luaInstance.globalScriptName == luaFile && !luaInstance.closed) {
					luaInstance.closed = true;
					got = true;
				}
			}

			if (!got) {
				l.luaTrace('removeLuaScript: The script "${luaFile}" doesn\'t exists nor is active!');
				return false;
			}
			return true;
		});

		addCallback("loadSong", function(_,  ?name:String = null, ?difficultyNum:Int = -1) {
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

		addCallback("loadGraphic", function(_,  variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0) {
			var spr:FlxSprite = LuaUtils.getVarInstance(variable);

			if (spr == null || image == null || image.length <= 0) return false;
			var animated = gridX != 0 || gridY != 0;

			spr.loadGraphic(Paths.image(image), animated, gridX, gridY);
			return true;
		});
		addCallback("loadFrames", function(_,  variable:String, image:String, spriteType:String = "sparrow") {
			var spr:FlxSprite = LuaUtils.getVarInstance(variable);
			if (spr == null || image == null || image.length <= 0) return false;

			LuaUtils.loadFrames(spr, image, spriteType);
			return true;
		});

		addCallback("getPref", function(_, pref:String, ?defaultValue:Dynamic) {
			return ClientPrefs.getPref(pref, defaultValue);
		});
		addCallback("setPref", function(_, pref:String, ?value:Dynamic = null) {
			ClientPrefs.prefs.set(pref, value);
		});

		addCallback("getProperty", true, function(state:State, lua:FunkinLua):Int {
			if (!LuaUtils.hasValidArgs(state, 1)) return 1;
			var variable:String = Convert.fromLua(state, 1);

			if ((variable is String)) {
				if (!Convert.toLua(state, LuaUtils.getVarInstance(variable, false))) Lua.pushnil(state);
			} else {
				if (lua.getBool('luaBackwardCompatibility')) return Lua.gettop(state);
				Lua.pushnil(state);
			}

			return 1;
		});
		addCallback("setProperty", true, function(state:State, lua:FunkinLua):Int {
			if (!LuaUtils.hasValidArgs(state, 1)) return 1;
			var args = Lua.gettop(state), variable:String = Convert.fromLua(state, 1);

			if ((variable is String)) Lua.pushboolean(state, LuaUtils.setVarInstance(variable, args > 1 ? Convert.fromLua(state, 2) : null));
			else Lua.pushboolean(state, false);

			return 1;
		});
		addCallback("getPropertyFromGroup", true, function(state:State, lua:FunkinLua):Int {
			if (!LuaUtils.hasValidArgs(state, 3)) return 1;
			var obj:String = Convert.fromLua(state, 1), index:Int = Convert.fromLua(state, 2), variable:Dynamic = Convert.fromLua(state, 3);
			var realObject:Dynamic = LuaUtils.getVarInstance(obj, false), isNull = false;

			if (Std.isOfType(realObject, FlxTypedGroup)) {
				if (!Convert.toLua(state, LuaUtils.getGroupStuff(realObject.members[index], variable))) isNull = true;
			} else {
				var leArray:Dynamic = realObject[index];
				if (leArray != null) {
					var result:Dynamic = null;
					if ((variable is Int)) result = leArray[variable];
					else result = LuaUtils.getGroupStuff(leArray, variable);

					if (!Convert.toLua(state, result)) isNull = true;
				} else Lua.pushnil(state);
			}

			if (isNull) {
				if (lua.getBool('luaBackwardCompatibility')) return Lua.gettop(state);
				else Lua.pushnil(state);
			}
			return 1;
		});
		addCallback("setPropertyFromGroup", true, function(state:State, lua:FunkinLua):Int {
			if (!LuaUtils.hasValidArgs(state, 3)) return 1;
			var args = Lua.gettop(state);
			var obj:String = Convert.fromLua(state, 1), index:Int = Convert.fromLua(state, 2), variable:Dynamic = Convert.fromLua(state, 3);
			var value:Dynamic = args > 3 ? Convert.fromLua(state, 4) : null, realObject:Dynamic = LuaUtils.getVarInstance(obj, false), isNull = false;

			if (Std.isOfType(realObject, FlxTypedGroup)) {
				LuaUtils.setGroupStuff(realObject.members[index], variable, value);
				Lua.pushboolean(state, true);
			} else {
				var leArray:Dynamic = realObject[index];
				if (leArray != null) {
					if ((variable is Int)) leArray[variable] = value;
					else LuaUtils.setGroupStuff(leArray, variable, value);
					Lua.pushboolean(state, true);
				} else Lua.pushboolean(state, false);
			}

			return 1;
		});
		addCallback("removeFromGroup", true, function(state:State, lua:FunkinLua):Int {
			if (!LuaUtils.hasValidArgs(state, 2)) return 1;
			var args = Lua.gettop(state);
			var obj:String = Convert.fromLua(state, 1), index:Int = Convert.fromLua(state, 2), dontDestroy:Bool = args > 2 ? Convert.fromLua(state, 3) : false;
			var grp:Dynamic = LuaUtils.getVarInstance(obj, false);

			if (Std.isOfType(grp, FlxTypedGroup)) {
				var sex = grp.members[index];
				if (sex != null) {
					grp.remove(sex, true);
					if (!dontDestroy) {
						sex.kill();
						sex.destroy();
					}
				}
			} else grp.splice(index, 1);

			Lua.pushnil(state);
			return 1;
		});

		addCallback("getPropertyFromClass", true, function(state:State, lua:FunkinLua):Int {
			if (!LuaUtils.hasValidArgs(state, 2)) return 1;
			if (!Convert.toLua(state, LuaUtils.getVarInObject(Type.resolveClass(Convert.fromLua(state, 1)), Convert.fromLua(state, 2))))
				Lua.pushnil(state);

			return 1;
		});
		addCallback("setPropertyFromClass", true, function(state:State, lua:FunkinLua):Int {
			if (!LuaUtils.hasValidArgs(state, 2)) return 1;
			var args:Int = Lua.gettop(state);
			Lua.pushboolean(state, LuaUtils.setVarInObject(Type.resolveClass(Convert.fromLua(state, 1)), Convert.fromLua(state, 2), args > 2 ? Convert.fromLua(state, 3) : null));
			return 1;
		});

		addCallback("callFromObject", function(_, variable:String, ?arguments:Array<Dynamic>) {
			if (arguments != null) arguments = [];
			var result:Dynamic = null;
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1)
				result = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1]);
			else result = LuaUtils.getVarInArray(LuaUtils.getInstance(), variable);
			return Reflect.callMethod(null, result, arguments);
		});
		addCallback("callFromClass", function(_,  classVar:String, variable:String, ?arguments:Array<Dynamic>) {
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
		addCallback("getObjectOrder", function(_, obj:String) {
			var poop:FlxBasic = LuaUtils.getVarInstance(obj);
			if (poop != null) return LuaUtils.getInstance().members.indexOf(poop);
			return -1;
		});
		addCallback("setObjectOrder", function(_, obj:String, position:Int) {
			var poop:FlxBasic = LuaUtils.getVarInstance(obj);
			if (poop == null) return false;

			LuaUtils.getInstance().remove(poop, true);
			LuaUtils.getInstance().insert(position, poop);
			return true;
		});

		// gay ass tweens
		addCallback("startTween", function(l:FunkinLua, tag:String, vars:String, values:Any = null, duration:Float, options:Any = null) {
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
				} else l.luaTrace('startTween: No values on 2nd argument!', false, false, FlxColor.RED);
			} else l.luaTrace('startTween: Couldnt find object: ' + vars, false, false, FlxColor.RED);
		});
		addCallback("doTween", function(l:FunkinLua, tag:String, variable:String, fieldsNValues:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, variable);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, fieldsNValues, duration * PlayState.instance.playbackRate, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.modchartTweens.remove(tag);
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
					}
				}));
			} else l.luaTrace('doTween: Couldnt find object: ' + variable, false, false, FlxColor.RED);
		});
		addCallback("doTweenAdvAngle", function(l:FunkinLua, tag:String, vars:String, value:Array<Float>, duration:Float, ease:String) {
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.angle(penisExam, value[0], value[1], duration * PlayState.instance.playbackRate, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else l.luaTrace('doTweenAdvAngle: Couldnt find object: ' + vars, false, false, FlxColor.RED);
		});
		addCallback("doTweenColor", function(l:FunkinLua, tag:String, vars:String, targetColor:String, duration:Float, ease:String) {
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(penisExam != null) {
				var color:Int = CoolUtil.parseHex(targetColor);

				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;
				PlayState.instance.modchartTweens.set(tag, FlxTween.color(penisExam, duration * PlayState.instance.playbackRate, curColor, color, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.modchartTweens.remove(tag);
						PlayState.instance.callOnLuas('onTweenCompleted', [tag, vars]);
					}
				}));
			} else l.luaTrace('doTweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
		});

		// bisexual note tween
		addCallback("noteTween", function(_, tag:String, note:Int, fieldsNValues:Dynamic, duration:Float, ease:String) {
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
		addCallback("mouseClicked", function(_, button:String) {
			return switch(button.trim().toLowerCase()) {
				case 'middle': FlxG.mouse.justPressedMiddle;
				case 'right': FlxG.mouse.justPressedRight;
				default: FlxG.mouse.justPressed;
			}
		});
		addCallback("mousePressed", function(_, button:String) {
			return switch(button.trim().toLowerCase()) {
				case 'middle': FlxG.mouse.pressedMiddle;
				case 'right': FlxG.mouse.pressedRight;
				default: FlxG.mouse.pressed;
			}
		});
		addCallback("mouseReleased", function(_, button:String) {
			return switch(button.trim().toLowerCase()) {
				case 'middle': FlxG.mouse.justReleasedMiddle;
				case 'right': FlxG.mouse.justReleased;
				default: FlxG.mouse.justReleased;
			}
		});

		addCallback("cancelTween", function(_, tag:String) {
			LuaUtils.cancelTween(tag);
		});

		addCallback("runTimer", function(_, tag:String, time:Float = 1, loops:Int = 1) {
			LuaUtils.cancelTimer(tag);
			PlayState.instance.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer) {
				if(tmr.finished) {
					PlayState.instance.modchartTimers.remove(tag);
				}
				PlayState.instance.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
			}, loops));
		});
		addCallback("cancelTimer", function(_, tag:String) {
			LuaUtils.cancelTimer(tag);
		});

		//stupid bietch ass functions
		addCallback("addScore", function(_, value:Int = 0) {
			PlayState.instance.songScore += value;
			PlayState.instance.RecalculateRating();
		});
		addCallback("addMisses", function(_, value:Int = 0) {
			PlayState.instance.songMisses += value;
			PlayState.instance.RecalculateRating();
		});
		addCallback("addHits", function(_, value:Int = 0) {
			PlayState.instance.songHits += value;
			PlayState.instance.RecalculateRating();
		});
		addCallback("setScore", function(_, value:Int = 0) {
			PlayState.instance.songScore = value;
			PlayState.instance.RecalculateRating();
		});
		addCallback("setMisses", function(_, value:Int = 0) {
			PlayState.instance.songMisses = value;
			PlayState.instance.RecalculateRating();
		});
		addCallback("setHits", function(_, value:Int = 0) {
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

		addCallback("getHighscore", function(_, song:String, diff:Int) {
			return Highscore.getScore(song, diff);
		});
		addCallback("getSavedRating", function(_, song:String, diff:Int) {
			return Highscore.getRating(song, diff);
		});
		addCallback("getSavedCombo", function(_, song:String, diff:Int) {
			return Highscore.getCombo(song, diff);
		});
		addCallback("getWeekScore", function(_, week:String, diff:Int) {
			return Highscore.getWeekScore(week, diff);
		});

		addCallback("setHealth", function(_, value:Float = 0) {
			PlayState.instance.health = value;
		});
		addCallback("addHealth", function(_, value:Float = 0) {
			PlayState.instance.health += value;
		});
		addCallback("getHealth", function() {
			return PlayState.instance.health;
		});

		Lua_helper.add_callback(lua, "FlxColor", function(?color:String = '') return FlxColor.fromString(color));
		Lua_helper.add_callback(lua, "getColorFromName", function(?color:String = '') return FlxColor.fromString(color));
		Lua_helper.add_callback(lua, "getColorFromString", function(?color:String = '') return FlxColor.fromString(color));
		Lua_helper.add_callback(lua, "getColorFromHex", function(color:String) return FlxColor.fromString('#$color'));
		
		addCallback("getColorFromRgb", function(_, rgb:Array<Int>) {
			return FlxColor.fromRGB(rgb[0], rgb[1], rgb[2]);
		});
		addCallback("getDominantColor", function(_, tag:String) {
			if (tag == null) return 0;
			return CoolUtil.dominantColor(LuaUtils.getObjectDirectly(tag));
		});

		addCallback("addCharacterToList", function(_, name:String, type:String) {
			var charType:Int = 0;
			switch(type.toLowerCase()) {
				case 'dad': charType = 1;
				case 'gf' | 'girlfriend': charType = 2;
			}
			PlayState.instance.addCharacterToList(name, charType);
		});
		addCallback("precacheImage", function(_, name:String) {
			Paths.returnGraphic(name);
		});
		addCallback("precacheSound", function(_, name:String) {
			Paths.sound(name);
		});
		addCallback("precacheMusic", function(_, name:String) {
			Paths.music(name);
		});

		addCallback("triggerEvent", function(_, name:String, arg1:Dynamic, arg2:Dynamic) {
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
		addCallback("restartSong", function(_, ?skipTransition:Bool = false) {
			PlayState.instance.persistentUpdate = false;
			FlxG.camera.followLerp = 0;
			PauseSubState.restartSong(skipTransition);
			return true;
		});
		addCallback("exitSong", function(_, ?skipTransition:Bool = false) {
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
			#if desktop Discord.resetClientID(); #end

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
			PlayState.instance.transitioning = true;
			FlxG.camera.followLerp = 0;
			Mods.loadTheFirstEnabledMod();
			return true;
		});
		addCallback("getSongPosition", function() {
			return Conductor.songPosition;
		});

		addCallback("getCharacterX", function(_, type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent': return PlayState.instance.dadGroup.x;
				case 'gf' | 'girlfriend': return PlayState.instance.gfGroup.x;
				default: return PlayState.instance.boyfriendGroup.x;
			}
		});
		addCallback("setCharacterX", function(_, type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent': PlayState.instance.dadGroup.x = value;
				case 'gf' | 'girlfriend': PlayState.instance.gfGroup.x = value;
				default: PlayState.instance.boyfriendGroup.x = value;
			}
		});
		addCallback("getCharacterY", function(_, type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent': return PlayState.instance.dadGroup.y;
				case 'gf' | 'girlfriend': return PlayState.instance.gfGroup.y;
				default: return PlayState.instance.boyfriendGroup.y;
			}
		});
		addCallback("setCharacterY", function(_, type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent': PlayState.instance.dadGroup.y = value;
				case 'gf' | 'girlfriend': PlayState.instance.gfGroup.y = value;
				default: PlayState.instance.boyfriendGroup.y = value;
			}
		});

		addCallback("changeMania", function(_, newValue:Int, skipTwn:Bool = false) {
			PlayState.instance.changeMania(newValue, skipTwn);
		});
		addCallback("generateStaticArrows", function(_, player:Int) {
			PlayState.instance.generateStaticArrows(player);
		});

		addCallback("cameraSetTarget", function(_, target:String) {
			switch(target.toLowerCase()) { //we do some copy and pasteing.
				case 'dad' | 'opponent': PlayState.instance.moveCamera('dad');
				case 'gf' | 'girlfriend': PlayState.instance.moveCamera('gf');
				default: PlayState.instance.moveCamera('bf');
			}
			return target;
		});
		addCallback("cameraShake", function(_, camera:String, intensity:Float, duration:Float) {
			LuaUtils.cameraFromString(camera).shake(intensity, duration * PlayState.instance.playbackRate);
		});

		addCallback("cameraFlash", function(_, camera:String, color:String, duration:Float, forced:Bool) {
			var colorNum:Int = CoolUtil.parseHex(color);
			LuaUtils.cameraFromString(camera).flash(colorNum, duration * PlayState.instance.playbackRate, null, forced);
		});
		addCallback("cameraFade", function(_, camera:String, color:String, duration:Float, forced:Bool) {
			var colorNum:Int = CoolUtil.parseHex(color);
			LuaUtils.cameraFromString(camera).fade(colorNum, duration * PlayState.instance.playbackRate, false, null, forced);
		});
		addCallback("setRatingPercent", function(_, value:Float) {
			PlayState.instance.ratingPercent = value;
		});
		addCallback("setRatingName", function(_, value:String) {
			PlayState.instance.ratingName = value;
		});
		addCallback("setRatingFC", function(_, value:String) {
			PlayState.instance.ratingFC = value;
		});
		addCallback("getMouseX", function(_, camera:String) {
			return FlxG.mouse.getScreenPosition(LuaUtils.cameraFromString(camera)).x;
		});
		addCallback("getMouseY", function(_, camera:String) {
			return FlxG.mouse.getScreenPosition(LuaUtils.cameraFromString(camera)).y;
		});

		addCallback("getMidpointX", function(_, obj:String) {
			var obj:FlxObject = LuaUtils.getVarInstance(obj);
			if (obj != null) return obj.getMidpoint().x;
			return 0;
		});
		addCallback("getMidpointY", function(_, obj:String) {
			var obj:FlxObject = LuaUtils.getVarInstance(obj);
			if (obj != null) return obj.getMidpoint().y;
			return 0;
		});
		addCallback("getGraphicMidpointX", function(_, obj:String) {
			var spr:FlxSprite  = LuaUtils.getVarInstance(obj);
			if (spr != null) return spr.getGraphicMidpoint().x;
			return 0;
		});
		addCallback("getGraphicMidpointY", function(_, obj:String) {
			var spr:FlxSprite  = LuaUtils.getVarInstance(obj);
			if (spr != null) return spr.getGraphicMidpoint().y;
			return 0;
		});
		addCallback("getScreenPositionX", function(_, obj:String) {
			var poop:FlxObject = LuaUtils.getVarInstance(obj);
			if (poop != null) return poop.getScreenPosition().x;
			return 0;
		});
		addCallback("getScreenPositionY", function(_, obj:String) {
			var poop:FlxObject = LuaUtils.getVarInstance(obj);
			if (poop != null) return poop.getScreenPosition().y;
			return 0;
		});
		addCallback("characterDance", function(_, character:String) {
			switch(character.toLowerCase()) {
				case 'dad': PlayState.instance.dad.dance();
				case 'gf' | 'girlfriend': if(PlayState.instance.gf != null) PlayState.instance.gf.dance();
				default: PlayState.instance.boyfriend.dance();
			}
		});

		addCallback("makeLuaSprite", function(_, tag:String, image:String, x:Float, y:Float) {
			tag = tag.replace('.', '');
			LuaUtils.resetSpriteTag(tag);

			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if(image != null && image.length > 0) leSprite.loadGraphic(Paths.image(image));

			PlayState.instance.modchartSprites.set(tag, leSprite);
		});
		addCallback("makeAnimatedLuaSprite", function(_, tag:String, image:String, x:Float, y:Float, ?spriteType:String = "sparrow") {
			tag = tag.replace('.', '');
			LuaUtils.resetSpriteTag(tag);

			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			LuaUtils.loadFrames(leSprite, image, spriteType);
			
			PlayState.instance.modchartSprites.set(tag, leSprite);
		});
		addCallback("makeLuaSpriteGroup", function(_, tag:String, ?x:Float = 0, ?y:Float = 0, ?maxSize:Int = 0) {
			tag = tag.replace('.', '');
			LuaUtils.resetSpriteTag(tag);

			var leGroup:ModchartGroup = new ModchartGroup(x, y, maxSize);
			PlayState.instance.modchartGroups.set(tag, leGroup);
		});

		addCallback("makeGraphic", function(_, obj:String, width:Int, height:Int, color:String) {
			var colorNum:Int = CoolUtil.parseHex(color);
			var spr:FlxSprite = LuaUtils.getVarInstance(obj, true, false);

			if (spr == null) return false;
			spr.makeGraphic(width, height, colorNum);
			return true;
		});
		addCallback("addAnimationByPrefix", function(_, obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			var cock:FlxSprite = PlayState.instance.getLuaObject(obj,false);
			if(cock != null) {
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
				return;
			}

			var cock:FlxSprite = Reflect.getProperty(LuaUtils.getInstance(), obj);
			if(cock != null) {
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});

		addCallback("addAnimation", function(_, obj:String, name:String, frames:Array<Int>, framerate:Int = 24, loop:Bool = true) {
			if(PlayState.instance.getLuaObject(obj, false) != null) {
				var cock:FlxSprite = PlayState.instance.getLuaObject(obj,false);
				cock.animation.add(name, frames, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
				return;
			}

			var cock:FlxSprite = Reflect.getProperty(LuaUtils.getInstance(), obj);
			if(cock != null) {
				cock.animation.add(name, frames, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});

		addCallback("addAnimationByIndices", function(_, obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, loop:Bool = false) {
			return addAnimByIndices(obj, name, prefix, indices, framerate, loop);
		});

		addCallback("playAnim", function(_, obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0) {
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
					return true;
				}
				return false;
			}

			var spr:FlxSprite = Reflect.getProperty(LuaUtils.getInstance(), obj);
			if(spr != null) {
				if(spr.animation.getByName(name) != null) {
					if(Std.isOfType(spr, Character)) {
						//convert spr to Character
						var obj:Dynamic = spr;
						var spr:Character = obj;
						spr.playAnim(name, forced, reverse, startFrame);
					} else spr.animation.play(name, forced, reverse, startFrame);
					return true;
				}
			}
			return false;
		});
		addCallback("playAnimGroup", function(_, obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0) {
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
		addCallback("addOffset", function(_, obj:String, anim:String, x:Float, y:Float) {
			if(PlayState.instance.modchartSprites.exists(obj)) {
				PlayState.instance.modchartSprites.get(obj).animOffsets.set(anim, [x, y]);
				return true;
			}

			var char:Character = Reflect.getProperty(LuaUtils.getInstance(), obj);
			if(char != null) {
				char.addOffset(anim, x, y);
				return true;
			}
			return false;
		});

		addCallback("setScrollFactor", function(_, obj:String, scrollX:Float, scrollY:Float) {
			var obj:FlxObject = LuaUtils.getVarInstance(obj);
			if (obj == null) return false;

			obj.scrollFactor.set(scrollX, scrollY);
			return true;
		});
		addCallback("setGroupScrollFactor", function(_, obj:String, ?scrollX:Float = 0, ?scrollY:Float = 0) {
			var leGroup:ModchartGroup = PlayState.instance.modchartGroups.get(obj);
			if (leGroup != null) {	
				leGroup.scrollFactor.set(scrollX, scrollY);
			}
		});

		addCallback("addSpriteToGroup", function(_, tag:String, spr:String) {
			var leGroup:ModchartGroup = PlayState.instance.modchartGroups.get(tag);
			if (leGroup != null) {
				var leSprite:ModchartSprite = PlayState.instance.modchartSprites.get(spr);
				if (leSprite != null) {
					leGroup.add(leSprite);
				}
			}
		});

		addCallback("addLuaSpriteGroup", function(_, tag:String, front:Bool = false) {
			var leGroup:ModchartGroup = PlayState.instance.modchartGroups.get(tag);
			if (leGroup != null) {
				if (!leGroup.wasAdded) {
					if (front)
						LuaUtils.getInstance().add(leGroup);
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
		addCallback("addLuaSprite", function(_, tag:String, front:Bool = false) {
			var shit:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
			if (shit == null || shit.wasAdded) return false;

			if(front) LuaUtils.getInstance().add(shit);
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
		addCallback("setGraphicSize", function(_, obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true) {
			var poop:FlxSprite = LuaUtils.getVarInstance(obj);
			if (poop == null) return false;

			poop.setGraphicSize(x, y);
			if (updateHitbox) poop.updateHitbox();
			return true;
		});
		addCallback("setGroupGraphicSize", function(_, tag:String, x:Int, y:Int = 0, updateHitbox:Bool = true) {
			var leGroup:ModchartGroup = PlayState.instance.modchartGroups.get(tag);
			if (leGroup != null) {
				leGroup.setGraphicSize(x, y);
				if (updateHitbox)
					leGroup.updateHitbox();
			}
		});
		addCallback("scaleObject", function(_, obj:String, x:Float, y:Float, updateHitbox:Bool = true) {
			var poop:FlxSprite = LuaUtils.getVarInstance(obj);
			if (poop == null) return false;

			poop.scale.set(x, y);
			if (updateHitbox) poop.updateHitbox();
			return true;
		});
		addCallback("scaleGroup", function(_, tag:String, x:Float, y:Float, updateHitbox:Bool = true) {
			var leGroup:ModchartGroup = PlayState.instance.modchartGroups.get(tag);
			if (leGroup != null) {
				leGroup.scale.set(x, y);
				if (updateHitbox) leGroup.updateHitbox();
			}
		});
		addCallback("updateGroupHitbox", function(_, tag:String) {
			var leGroup:ModchartGroup = PlayState.instance.modchartGroups.get(tag);
			if (leGroup != null) {
				leGroup.updateHitbox();	
			}
		});
		addCallback("updateHitbox", function(_, obj:String) {
			if(PlayState.instance.getLuaObject(obj) != null) {
				var shit:FlxSprite = PlayState.instance.getLuaObject(obj);
				shit.updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(LuaUtils.getInstance(), obj);
			if(poop != null) {
				poop.updateHitbox();
				return;
			}
			luaTrace('updateHitbox: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		addCallback("updateHitboxFromGroup", function(_, group:String, index:Int) {
			if(Std.isOfType(Reflect.getProperty(LuaUtils.getInstance(), group), FlxTypedGroup)) {
				Reflect.getProperty(LuaUtils.getInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(LuaUtils.getInstance(), group)[index].updateHitbox();
		});

		addCallback("centerOffsets", function(_, obj:String) {
			if(PlayState.instance.getLuaObject(obj) != null) {
				var shit:FlxSprite = PlayState.instance.getLuaObject(obj);
				shit.centerOffsets();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(LuaUtils.getInstance(), obj);
			if(poop != null) {
				poop.centerOffsets();
				return;
			}
			luaTrace('centerOffsets: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		addCallback("centerOffsetsFromGroup", function(_, group:String, index:Int) {
			if(Std.isOfType(Reflect.getProperty(LuaUtils.getInstance(), group), FlxTypedGroup)) {
				Reflect.getProperty(LuaUtils.getInstance(), group).members[index].centerOffsets();
				return;
			}
			Reflect.getProperty(LuaUtils.getInstance(), group)[index].centerOffsets();
		});

		addCallback("removeSpriteFromGroup", function(_, tag:String, spr:String, destroy:Bool = true) {
			var leGroup:ModchartGroup = PlayState.instance.modchartGroups.get(tag);
			if (leGroup != null) {
				var leSprite:ModchartSprite = PlayState.instance.modchartSprites.get(spr);
				if (leSprite != null && leGroup.members.contains(leSprite)) {
					leGroup.remove(leSprite);
					if (destroy) leGroup.destroy();
				}
			}
		});
		addCallback("removeLuaSprite", function(_, tag:String, destroy:Bool = true) {
			var pee:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
			if (pee == null) return false;

			if (destroy) pee.kill();
			if (pee.wasAdded) {
				LuaUtils.getInstance().remove(pee, true);
				pee.wasAdded = false;
			}
			if (destroy) {
				pee.destroy();
				PlayState.instance.modchartSprites.remove(tag);
			}
			return true;
		});

		addCallback("setColorSwap", function(_, obj:String, hue:Float = 0, saturation:Float = 0, brightness:Float = 0) {
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

		addCallback("stampSprite", function(_, sprite:String, brush:String, x:Int, y:Int) {
			if(!PlayState.instance.modchartSprites.exists(sprite) || !PlayState.instance.modchartSprites.exists(brush)) return false;

			PlayState.instance.modchartSprites.get(sprite).stamp(PlayState.instance.modchartSprites.get(brush), x, y);
			return true;
		});

		addCallback("luaSpriteExists", function(_, tag:String) {
			return PlayState.instance.modchartSprites.exists(tag);
		});
		addCallback("luaTextExists", function(_, tag:String) {
			return PlayState.instance.modchartTexts.exists(tag);
		});
		addCallback("luaSoundExists", function(_, tag:String) {
			return PlayState.instance.modchartSounds.exists(tag);
		});

		addCallback("setHealthBarColors", function(_, leftHex:String, rightHex:String) {
			var left = CoolUtil.parseHex(leftHex);
			var right = CoolUtil.parseHex(rightHex);

			if (leftHex == null) left = PlayState.instance.dad.getColor();
			if (rightHex == null) right = PlayState.instance.boyfriend.getColor();

			PlayState.instance.healthBar.setColors(left, right);
		});
		addCallback("setTimeBarColors", function(_, leftHex:String, rightHex:String) {
			var leftHex = CoolUtil.parseHex(leftHex);
			var rightHex = CoolUtil.parseHex(rightHex);

			PlayState.instance.timeBar.createFilledBar(leftHex, rightHex);
			PlayState.instance.timeBar.updateBar();
		});
		addCallback("setTimeBarColorsWithGradient", function(_, leftHex:Array<String>, rightHex:Array<String>) {
			var left:Array<FlxColor> = [Std.parseInt(leftHex[0]), CoolUtil.parseHex(leftHex[1])];
			var right:Array<FlxColor> = [CoolUtil.parseHex(rightHex[0]), CoolUtil.parseHex(rightHex[1])];

			PlayState.instance.timeBar.createGradientBar(left, right, 1, 90);
			PlayState.instance.timeBar.updateBar();
		});

		addCallback("setObjectCamera", function(_, obj:String, camera:String = '') {
			var poop:FlxBasic = LuaUtils.getVarInstance(obj);
			if (poop == null) return false;

			poop.camera = LuaUtils.cameraFromString(camera);
			return true;
		});
		addCallback("setBlendMode", function(_, obj:String, blend:String = '') {
			var spr:FlxSprite = LuaUtils.getVarInstance(obj);
			if (spr == null) return false;

			spr.blend = LuaUtils.blendModeFromString(blend);
			return true;
		});
		addCallback("screenCenterGroup", function(_, tag:String, pos:String = 'xy') {
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
		addCallback("screenCenter", function(_, obj:String, pos:String = 'xy') {
			var spr:FlxSprite = LuaUtils.getVarInstance(obj);
			if (spr == null) return false;

			switch(pos.trim().toLowerCase()) {
				case 'x': spr.screenCenter(X);
				case 'y': spr.screenCenter(Y);
				default: spr.screenCenter(XY);
			}
			return true;
		});
		addCallback("objectsOverlap", function(_, obj1:String, obj2:String) {
			var guh1:FlxBasic = LuaUtils.getVarInstance(obj1), guh2:FlxBasic = LuaUtils.getVarInstance(obj2);
			if (guh1 == null || guh2 == null) return false;
			return FlxG.overlap(guh1, guh2);
		});
		addCallback("getPixelColor", function(_, obj:String, x:Int, y:Int) {
			var spr:FlxSprite = LuaUtils.getVarInstance(obj);
			if(spr == null) return 0;

			if(spr.framePixels != null) spr.framePixels.getPixel32(x, y);
			return spr.pixels.getPixel32(x, y);
		});

		addCallback("startDialogue", function(l:FunkinLua, dialogueFile:String, music:String = null) {
			var path:String;
			#if MODS_ALLOWED
			path = Paths.modsJson("charts/" + Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);
			if(!FileSystem.exists(path))
			#end
				path = Paths.json("charts/" + Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);
			l.luaTrace('startDialogue: Trying to load dialogue: ' + path);
			#if MODS_ALLOWED
			if(FileSystem.exists(path))
			#else
			if(Assets.exists(path))
			#end {
				var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
				if(shit.dialogue.length > 0) {
					PlayState.instance.startDialogue(shit, music);
					l.luaTrace('Successfully loaded dialogue', false, false, FlxColor.GREEN);
					return true;
				} else l.luaTrace('Your dialogue file is badly formatted!', false, false, FlxColor.RED);
			} else {
				l.luaTrace('startDialogue: Dialogue file not found', false, false, FlxColor.RED);
				if(PlayState.instance.endingSong)
					PlayState.instance.endSong();
				else PlayState.instance.startCountdown();
			}
			return false;
		});
		addCallback("startVideo", function(l:FunkinLua, videoFile:String) {
			#if VIDEOS_ALLOWED
			if(FileSystem.exists(Paths.video(videoFile))) {
				PlayState.instance.startVideo(videoFile);
				return true;
			}
			
			l.luaTrace('startVideo: Video file not found: ' + videoFile, false, false, FlxColor.RED);
			return false;

			#else
			PlayState.instance.startAndEnd();
			return true;
			#end
		});
		addCallback("startVideoSprite", function(l:FunkinLua, videoFile:String, x:Float = 0, y:Float = 0, op:Float = 1, cam:String = 'world', ?loop:Bool = false, ?pauseMusic:Bool = false) {
			#if VIDEOS_ALLOWED
			if(FileSystem.exists(Paths.video(videoFile))) {
				PlayState.instance.startVideoSprite(videoFile, x, y, op, cam, loop, pauseMusic);
				return true;
			} else l.luaTrace('startVideoSprite: Video file not found: ' + videoFile, false, false, FlxColor.RED);
			return false;
			#else
			PlayState.instance.startAndEnd();
			return true;
			#end
		});

		addCallback("playMusic", function(_, sound:String, volume:Float = 1, loop:Bool = false) {
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});
		addCallback("playSound", function(_, sound:String, volume:Float = 1, ?tag:String = null) {
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
		addCallback("stopSound", function(_, tag:String) {
			if(tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).stop();
				PlayState.instance.modchartSounds.remove(tag);
			}
		});
		addCallback("pauseSound", function(_, tag:String) {
			if(tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).pause();
			}
		});
		addCallback("resumeSound", function(_, tag:String) {
			if(tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).play();
			}
		});
		addCallback("soundFadeIn", function(_, tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			if(tag == null || tag.length < 1) {
				FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			} else if(PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).fadeIn(duration * PlayState.instance.playbackRate, fromValue, toValue);
			}
		});
		addCallback("soundFadeOut", function(_, tag:String, duration:Float, toValue:Float = 0) {
			if(tag == null || tag.length < 1) {
				FlxG.sound.music.fadeOut(duration, toValue);
			} else if(PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).fadeOut(duration * PlayState.instance.playbackRate, toValue);
			}
		});
		addCallback("soundFadeCancel", function(_, tag:String) {
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
		addCallback("getSoundVolume", function(_, tag:String) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null)
					return FlxG.sound.music.volume;
			} else if(PlayState.instance.modchartSounds.exists(tag))
				return PlayState.instance.modchartSounds.get(tag).volume;
			return 0;
		});
		addCallback("setSoundVolume", function(_, tag:String, value:Float) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null)
					FlxG.sound.music.volume = value;
			} else if(PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).volume = value;
			}
		});
		addCallback("getSoundTime", function(_, tag:String) {
			if(tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag))
				return PlayState.instance.modchartSounds.get(tag).time;
			return 0;
		});
		addCallback("setSoundTime", function(_, tag:String, value:Float) {
			if(tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag)) {
				var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);
				if(theSound != null) theSound.time = value;
			}
		});
		addCallback("getSoundPitch", function(_, tag:String) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null)
					return FlxG.sound.music.pitch;
			} else if (PlayState.instance.modchartSounds.exists(tag))
				return PlayState.instance.modchartSounds.get(tag).pitch;
			
			return 1;
		});
		addCallback("setSoundPitch", function(_, tag:String, value:Float = 1) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null)
					FlxG.sound.music.pitch = value;
			} else if (PlayState.instance.modchartSounds.exists(tag)) {
				var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);
				if(theSound != null) theSound.pitch = value;
			}
		});

		addCallback("debugPrint", true, function(lua:State, fl:FunkinLua) {
			var texts:Array<Dynamic> = Lua_helper.getarguments(lua);
			if (texts.length <= 0) return 0;
			var convtxt:Array<String> = [for (i in texts) Std.isOfType(i[0], String) ? i : Std.string(i)];

			var text:String = convtxt[0];
			for (i in 1...convtxt.length) {
				var s:String = convtxt[i];
				if (Std.isOfType(s, String)) text += ', $s';
			}
			fl.luaTrace(text, true, false);
			return 0;
		});

		addCallback("close", function(l:FunkinLua):Bool {
			return l.closed = true;
		});

		addCallback("changePresence", function(_, details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
			#if discord_rpc
			PlayState.instance.presenceChangedByLua = true;
			Discord.changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
			#end
		});

		// LUA TEXTS
		addCallback("makeLuaText", function(_, tag:String, text:String, width:Int, x:Float, y:Float) {
			tag = tag.replace('.', '');
			LuaUtils.resetTextTag(tag);
			PlayState.instance.modchartTexts.set(tag, new ModchartText(x, y, text, width));
		});

		addCallback("setTextString", function(l:FunkinLua, tag:String, text:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.text = text;
				return true;
			}
			l.luaTrace("setTextString: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		addCallback("setTextSize", function(l:FunkinLua, tag:String, size:Int) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.size = size;
				return true;
			}
			l.luaTrace("setTextSize: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		addCallback("setTextWidth", function(l:FunkinLua, tag:String, width:Float) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.fieldWidth = width;
				return true;
			}
			l.luaTrace("setTextWidth: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		addCallback("setTextBorder", function(l:FunkinLua, tag:String, size:Int, color:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.borderSize = size;
				obj.borderColor = CoolUtil.parseHex(color);
				return true;
			}
			l.luaTrace("setTextBorder: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		addCallback("setTextBorderStyle", function(_, tag:String, borderStyle:String = 'NONE') {
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
		addCallback("setTextColor", function(l:FunkinLua, tag:String, color:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.color = CoolUtil.parseHex(color);
				return true;
			}
			l.luaTrace("setTextColor: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		addCallback("setTextFont", function(l:FunkinLua, tag:String, newFont:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.font = Paths.font(newFont);
				return true;
			}
			l.luaTrace("setTextFont: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		addCallback("setTextItalic", function(l:FunkinLua, tag:String, italic:Bool) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.italic = italic;
				return true;
			}
			l.luaTrace("setTextItalic: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		addCallback("setTextAlignment", function(l:FunkinLua, tag:String, alignment:String = 'left') {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.alignment = LEFT;
				switch(alignment.trim().toLowerCase()) {
					case 'right': obj.alignment = RIGHT;
					case 'center': obj.alignment = CENTER;
				}
				return true;
			}
			l.luaTrace("setTextAlignment: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		addCallback("getTextString", function(l:FunkinLua, tag:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null && obj.text != null)
				return obj.text;
			l.luaTrace("getTextString: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		addCallback("getTextSize", function(l:FunkinLua, tag:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) return obj.size;
			l.luaTrace("getTextSize: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return -1;
		});
		addCallback("getTextFont", function(l:FunkinLua, tag:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) return obj.font;
			l.luaTrace("getTextFont: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		addCallback("getTextWidth", function(l:FunkinLua, tag:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) return obj.fieldWidth;
			l.luaTrace("getTextWidth: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return 0;
		});

		addCallback("addLuaText", function(_, tag:String) {
			if(PlayState.instance.modchartTexts.exists(tag)) {
				var shit:ModchartText = PlayState.instance.modchartTexts.get(tag);
				if(!shit.wasAdded) {
					LuaUtils.getInstance().add(shit);
					shit.wasAdded = true;
				}
			}
		});
		addCallback("removeLuaText", function(_, tag:String, destroy:Bool = true) {
			if(!PlayState.instance.modchartTexts.exists(tag)) return;

			var text:ModchartText = PlayState.instance.modchartTexts.get(tag);
			if(destroy) text.kill();

			if(text.wasAdded) {
				LuaUtils.getInstance().remove(text, true);
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
		trace('lua file loaded succesfully:' + scriptName);

		call('onCreate');
		if (closed) return stop();
		#end
	}

	#if LUA_ALLOWED
	public function initGlobals() {
		// Lua shit
		set('Function_StopLua', Function_StopLua);
		set('Function_Stop', Function_Stop);
		set('Function_Continue', Function_Continue);

		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('luaBackwardCompatibility', true);
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
		set('hasVocals', PlayState.SONG.needsVoices);

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
		set('currentModDirectory', Mods.currentModDirectory);

		#if windows
		var os = 'windows';
		#else
		var os = Sys.systemName().toLowerCase();
		#end
		set('buildTarget', os);
	}
	#end

	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function getShader(obj:String):FlxRuntimeShader {
		var leObj:FlxSprite = LuaUtils.getVarInstance(obj, true, false);
		if (leObj != null) return cast leObj.shader;
		return null;
	}

	inline public function addCallback(name:String, ?adv:Bool = false, func:Function) {
		Lua_helper.set_static_callback(name, adv, func);
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
	public function call(func:String, ?args:Array<Any>):Dynamic {
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

		var pussy:FlxSprite = Reflect.getProperty(LuaUtils.getInstance(), obj);
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

	public function set(variable:String, data:Any) {
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
		if (lua == null) return;
		Lua_helper.terminate_callbacks(lua);
		Lua.close(lua);
		lua = null;
		#end
	}

	public static function format(luaFile:String):String {
		return Path.normalize((luaFile = luaFile.toLowerCase()).endsWith('.lua') ? luaFile : '${luaFile}.lua');
	}

	public static function execute(script:String):FunkinLua {
		var lua:FunkinLua = new FunkinLua(script);
		if (PlayState.instance == null || FlxG.state != PlayState.instance) return lua;
		if (!lua.closed) PlayState.instance.luaArray.push(lua);
		return lua;
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
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));

		for(mod in Mods.getGlobalMods())
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