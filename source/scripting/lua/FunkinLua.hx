package scripting.lua;

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

	public var callbacks:Map<String, Dynamic> = new Map<String, Dynamic>();
	public final addCallback:(String, Dynamic)->Bool;
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

			Lua.getglobal(lua, "package");
			Lua.pushstring(lua, Paths.getLuaPackagePath());
			Lua.setfield(lua, -2, "path");
			Lua.pop(lua, 1);

			result = Lua.pcall(lua, 0, 0, 0);
		} else {
			var error:String = getErrorMessage();
			#if windows
			lime.app.Application.current.window.alert(error, 'Error on lua script! "$scriptName"');
			#else
			luaTrace('$scriptName\n$error', true, false, FlxColor.RED);
			#end
		}
		addCallback = Lua_helper.add_callback.bind(lua);
		#if hscript HScript.initHaxeModule(this); #end

		trace('lua file loaded succesfully: $scriptName');
		var game:PlayState = PlayState.instance;

		initGlobals(game);

		addCallback("openCustomSubstate", function(name:String, pauseGame:Bool = false) {
			if(pauseGame) {
				game.persistentUpdate = false;
				game.persistentDraw = true;
				game.paused = true;
				if(FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					game.vocals.pause();
				}
			}
			game.openSubState(new CustomSubstate(name));
		});
		addCallback("closeCustomSubstate", function(_) {
			if(CustomSubstate.instance == null) return false;
			game.closeSubState();
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

		addCallback("getRunningScripts", function(_) {
			return [for (script in game.luaArray) script];
		});

		addLocalCallback("setOnLuas", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
			if(exclusions == null) exclusions = [];
			if(ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
			game.setOnLuas(varName, arg, exclusions);
		});

		addLocalCallback("callOnLuas", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops=false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null) {
			if(excludeScripts == null) excludeScripts = [];
			if(ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);
			game.callOnLuas(funcName, args, ignoreStops, excludeScripts, excludeValues);
			return true;
		});

		addCallback("callScript", function(luaFile:String, funcName:String, args:Array<Dynamic>):Dynamic {
			luaFile = format(luaFile);

			for (luaInstance in game.luaArray) {
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

		addCallback("setGlobalFromScript", function(luaFile:String, global:String, val:Dynamic):Bool {
			luaFile = format(luaFile);

			var got:Bool = false;
			for (luaInstance in game.luaArray) {
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
		addCallback("getGlobalFromScript", function(luaFile:String, global:String):Dynamic {
			luaFile = format(luaFile);

			for (luaInstance in game.luaArray) {
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

		addCallback("isRunning", function(luaFile:String) {
			return LuaUtils.isLuaRunning(luaFile);
		});

		addCallback("addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false):Bool { //would be dope asf.
			luaFile = format(luaFile);

			if (!ignoreAlreadyRunning && LuaUtils.isLuaRunning(luaFile)) {
				luaTrace('addLuaScript: The script "${luaFile}" is already running!');
				return false;
			}

			var res:FunkinLua = game.executeLua(luaFile);
			if (res == null) {
				luaTrace('addLuaScript: The script "${luaFile}" doesn\'t exist!', false, false, FlxColor.RED);
				return false;
			}
			return true;
		});
		addCallback("removeLuaScript", function(luaFile:String):Bool {
			luaFile = format(luaFile);

			var got:Bool = false;
			for (luaInstance in game.luaArray) {
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

		addCallback("loadSong", function( ?name:String = null, ?difficultyNum:Int = -1) {
			if(name == null || name.length <= 0) name = PlayState.SONG.song;
			if (difficultyNum == -1) difficultyNum = PlayState.storyDifficulty;

			var poop = Highscore.formatSong(name, difficultyNum);
			PlayState.SONG = Song.loadFromJson(poop, name);
			PlayState.storyDifficulty = difficultyNum;
			game.persistentUpdate = false;
			LoadingState.loadAndSwitchState(new PlayState());

			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;
			if(game.vocals != null) {
				game.vocals.pause();
				game.vocals.volume = 0;
			}
		});

		addCallback("loadGraphic", function( variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0) {
			var spr:FlxSprite = LuaUtils.getVarInstance(variable);

			if (spr == null || image == null || image.length <= 0) return false;
			var animated = gridX != 0 || gridY != 0;

			spr.loadGraphic(Paths.image(image), animated, gridX, gridY);
			return true;
		});
		addCallback("loadFrames", function( variable:String, image:String, spriteType:String = "sparrow") {
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

		//shitass stuff for epic coders like me B)  *image of obama giving himself a medal*
		addCallback("getObjectOrder", function(obj:String) {
			var poop:FlxBasic = LuaUtils.getVarInstance(obj);
			if (poop != null) return LuaUtils.getInstance().members.indexOf(poop);
			return -1;
		});
		addCallback("setObjectOrder", function(obj:String, position:Int) {
			var poop:FlxBasic = LuaUtils.getVarInstance(obj);
			if (poop == null) return false;

			LuaUtils.getInstance().remove(poop, true);
			LuaUtils.getInstance().insert(position, poop);
			return true;
		});

		// gay ass tweens
		addCallback("startTween", function(tag:String, vars:String, values:Any = null, duration:Float, options:Any = null) {
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(penisExam != null) {
				if(values != null) {
					var myOptions:LuaUtils.LuaTweenOptions = LuaUtils.getLuaTween(options);
					game.modchartTweens.set(tag, FlxTween.tween(penisExam, values, duration, {
						type: myOptions.type,
						ease: myOptions.ease,
						startDelay: myOptions.startDelay,
						loopDelay: myOptions.loopDelay,

						onUpdate: function(twn:FlxTween) {
							if(myOptions.onUpdate != null) game.callOnLuas(myOptions.onUpdate, [tag, vars]);
						}, onStart: function(twn:FlxTween) {
							if(myOptions.onStart != null) game.callOnLuas(myOptions.onStart, [tag, vars]);
						}, onComplete: function(twn:FlxTween) {
							if(myOptions.onComplete != null) game.callOnLuas(myOptions.onComplete, [tag, vars]);
							if(twn.type == FlxTweenType.ONESHOT || twn.type == FlxTweenType.BACKWARD) game.modchartTweens.remove(tag);
						}
					}));
				} else luaTrace('startTween: No values on 2nd argument!', false, false, FlxColor.RED);
			} else luaTrace('startTween: Couldnt find object: ' + vars, false, false, FlxColor.RED);
		});
		addCallback("doTween", function(tag:String, variable:String, fieldsNValues:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, variable);
			if(penisExam != null) {
				game.modchartTweens.set(tag, FlxTween.tween(penisExam, fieldsNValues, duration * game.playbackRate, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						game.modchartTweens.remove(tag);
						game.callOnLuas('onTweenCompleted', [tag]);
					}
				}));
			} else luaTrace('doTween: Couldnt find object: ' + variable, false, false, FlxColor.RED);
		});
		addCallback("doTweenAdvAngle", function(tag:String, vars:String, value:Array<Float>, duration:Float, ease:String) {
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(penisExam != null) {
				game.modchartTweens.set(tag, FlxTween.angle(penisExam, value[0], value[1], duration * game.playbackRate, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						game.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			} else luaTrace('doTweenAdvAngle: Couldnt find object: ' + vars, false, false, FlxColor.RED);
		});
		addCallback("doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String) {
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(penisExam != null) {
				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;
				game.modchartTweens.set(tag, FlxTween.color(penisExam, duration * game.playbackRate, curColor, CoolUtil.colorFromString(targetColor), {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						game.modchartTweens.remove(tag);
						game.callOnLuas('onTweenCompleted', [tag, vars]);
					}
				}));
			} else luaTrace('doTweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
		});

		// bisexual note tween
		addCallback("noteTween", function(tag:String, note:Int, fieldsNValues:Dynamic, duration:Float, ease:String) {
			LuaUtils.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if(testicle != null) {
				game.modchartTweens.set(tag, FlxTween.tween(testicle, fieldsNValues, duration * game.playbackRate, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						game.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
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
			game.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer) {
				if(tmr.finished) {
					game.modchartTimers.remove(tag);
				}
				game.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
			}, loops));
		});
		addCallback("cancelTimer", function(tag:String) {
			LuaUtils.cancelTimer(tag);
		});

		//stupid bietch ass functions
		addCallback("addScore", function(value:Int = 0) {
			game.songScore += value;
			game.RecalculateRating();
		});
		addCallback("addMisses", function(value:Int = 0) {
			game.songMisses += value;
			game.RecalculateRating();
		});
		addCallback("addHits", function(value:Int = 0) {
			game.songHits += value;
			game.RecalculateRating();
		});
		addCallback("setScore", function(value:Int = 0) {
			game.songScore = value;
			game.RecalculateRating();
		});
		addCallback("setMisses", function(value:Int = 0) {
			game.songMisses = value;
			game.RecalculateRating();
		});
		addCallback("setHits", function(value:Int = 0) {
			game.songHits = value;
			game.RecalculateRating();
		});
		addCallback("getScore", function() {
			return game.songScore;
		});
		addCallback("getMisses", function() {
			return game.songMisses;
		});
		addCallback("getAccuracy", function() {
			return game.accuracy;
		});
		addCallback("getHits", function() {
			return game.songHits;
		});

		addCallback("getHighscore", function(song:String, diff:Int) {
			return Highscore.getScore(song, diff);
		});
		addCallback("getSavedRating", function(song:String, diff:Int) {
			return Highscore.getRating(song, diff);
		});
		addCallback("getSavedCombo", function(song:String, diff:Int) {
			return Highscore.getCombo(song, diff);
		});
		addCallback("getWeekScore", function(week:String, diff:Int) {
			return Highscore.getWeekScore(week, diff);
		});

		addCallback("setHealth", function(value:Float = 0) {
			game.health = value;
		});
		addCallback("addHealth", function(value:Float = 0) {
			game.health += value;
		});
		addCallback("getHealth", function(_) {
			return game.health;
		});

		addCallback("FlxColor", function(?color:String = '') return FlxColor.fromString(color));
		addCallback("getColorFromName", function(?color:String = '') return FlxColor.fromString(color));
		addCallback("getColorFromString", function(?color:String = '') return FlxColor.fromString(color));
		addCallback("getColorFromHex", function(color:String) return FlxColor.fromString('#$color'));
		
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
			game.addCharacterToList(name, charType);
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
			game.triggerEventNote(name, value1, value2, Conductor.songPosition);
			return true;
		});

		addCallback("startCountdown", function() {
			game.startCountdown();
			return true;
		});
		addCallback("endSong", function() {
			game.KillNotes();
			game.endSong();
			return true;
		});
		addCallback("restartSong", function(?skipTransition:Bool = false) {
			game.persistentUpdate = false;
			FlxG.camera.followLerp = 0;
			PauseSubState.restartSong(skipTransition);
			return true;
		});
		addCallback("exitSong", function(?skipTransition:Bool = false) {
			if(skipTransition) {
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
			}

			PlayState.cancelMusicFadeTween();
			CustomFadeTransition.nextCamera = game.camOther;
			if(FlxTransitionableState.skipNextTransIn)
				CustomFadeTransition.nextCamera = null;

			if(PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else MusicBeatState.switchState(new FreeplayState());
			#if desktop Discord.resetClientID(); #end

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
			game.transitioning = true;
			FlxG.camera.followLerp = 0;
			Mods.loadTopMod();
			return true;
		});
		addCallback("getSongPosition", function() {
			return Conductor.songPosition;
		});

		addCallback("getCharacterX", function(type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent': return game.dadGroup.x;
				case 'gf' | 'girlfriend': return game.gfGroup.x;
				default: return game.boyfriendGroup.x;
			}
		});
		addCallback("setCharacterX", function(type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent': game.dadGroup.x = value;
				case 'gf' | 'girlfriend': game.gfGroup.x = value;
				default: game.boyfriendGroup.x = value;
			}
		});
		addCallback("getCharacterY", function(type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent': return game.dadGroup.y;
				case 'gf' | 'girlfriend': return game.gfGroup.y;
				default: return game.boyfriendGroup.y;
			}
		});
		addCallback("setCharacterY", function(type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent': game.dadGroup.y = value;
				case 'gf' | 'girlfriend': game.gfGroup.y = value;
				default: game.boyfriendGroup.y = value;
			}
		});

		addCallback("changeMania", function(newValue:Int, skipTwn:Bool = false) {
			game.changeMania(newValue, skipTwn);
		});
		addCallback("generateStaticArrows", function(player:Int) {
			game.generateStaticArrows(player);
		});

		addCallback("cameraSetTarget", function(target:String) {
			switch(target.toLowerCase()) { //we do some copy and pasteing.
				case 'dad' | 'opponent': game.moveCamera('dad');
				case 'gf' | 'girlfriend': game.moveCamera('gf');
				default: game.moveCamera('bf');
			}
			return target;
		});
		addCallback("cameraShake", function(camera:String, intensity:Float, duration:Float) {
			LuaUtils.cameraFromString(camera).shake(intensity, duration * game.playbackRate);
		});

		addCallback("cameraFlash", function(camera:String, color:String, duration:Float, forced:Bool) {
			LuaUtils.cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration * game.playbackRate, null, forced);
		});
		addCallback("cameraFade", function(camera:String, color:String, duration:Float, forced:Bool) {
			LuaUtils.cameraFromString(camera).fade(CoolUtil.colorFromString(color), duration * game.playbackRate, false, null, forced);
		});
		addCallback("setRatingPercent", function(value:Float) {
			game.ratingPercent = value;
		});
		addCallback("setRatingName", function(value:String) {
			game.ratingName = value;
		});
		addCallback("setRatingFC", function(value:String) {
			game.ratingFC = value;
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
				case 'dad': game.dad.dance();
				case 'gf' | 'girlfriend': if(game.gf != null) game.gf.dance();
				default: game.boyfriend.dance();
			}
		});

		addCallback("makeLuaSprite", function(tag:String, image:String = null, x:Float = 0, y:Float = 0) {
			tag = tag.replace('.', '');
			LuaUtils.resetSpriteTag(tag);

			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if(image != null && image.length > 0) leSprite.loadGraphic(Paths.image(image));

			game.modchartSprites.set(tag, leSprite);
		});
		addCallback("makeAnimatedLuaSprite", function(tag:String, image:String = null, x:Float = 0, y:Float = 0, ?spriteType:String = "sparrow") {
			tag = tag.replace('.', '');
			LuaUtils.resetSpriteTag(tag);

			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			LuaUtils.loadFrames(leSprite, image, spriteType);
			
			game.modchartSprites.set(tag, leSprite);
		});
		addCallback("makeLuaSpriteGroup", function(tag:String, ?x:Float = 0, ?y:Float = 0, ?maxSize:Int = 0) {
			tag = tag.replace('.', '');
			LuaUtils.resetSpriteTag(tag);

			var leGroup:ModchartGroup = new ModchartGroup(x, y, maxSize);
			game.modchartGroups.set(tag, leGroup);
		});

		addCallback("makeGraphic", function(obj:String, width:Int = 256, height:Int = 256, color:String = 'FFFFFF') {
			var spr:FlxSprite = LuaUtils.getVarInstance(obj, true, false);

			if (spr == null) return false;
			spr.makeGraphic(width, height, CoolUtil.colorFromString(color));
			return true;
		});
		addCallback("addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if(obj != null && obj.animation != null) {
				obj.animation.addByPrefix(name, prefix, framerate, loop);
				if(obj.animation.curAnim == null)
					obj.animation.play(name, true);
				return true;
			}
			return false;
		});

		addCallback("addAnimation", function(obj:String, name:String, frames:Array<Int>, framerate:Int = 24, loop:Bool = true) {
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if(obj != null && obj.animation != null) {
				obj.animation.add(name, frames, framerate, loop);
				if(obj.animation.curAnim == null) obj.animation.play(name, true);
				return true;
			}
			return false;
		});

		addCallback("addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, loop:Bool = false) {
			return LuaUtils.addAnimByIndices(obj, name, prefix, indices, framerate, loop);
		});

		addCallback("playAnim", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0) {
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if(obj.playAnim != null) {
				obj.playAnim(name, forced, reverse, startFrame);
				return true;
			} else {
				obj.animation.play(name, forced, reverse, startFrame);
				return true;
			}
			return false;
		});
		addCallback("playAnimGroup", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0) {
			var leGroup:ModchartGroup = game.modchartGroups.get(obj);
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
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if(obj != null && obj.addOffset != null) {
				obj.addOffset(anim, x, y);
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
			var leGroup:ModchartGroup = game.modchartGroups.get(obj);
			if (leGroup != null)  leGroup.scrollFactor.set(scrollX, scrollY);
		});

		addCallback("addSpriteToGroup", function(tag:String, spr:String) {
			var leGroup:ModchartGroup = game.modchartGroups.get(tag);
			if (leGroup != null) {
				var leSprite:ModchartSprite = game.modchartSprites.get(spr);
				if (leSprite != null) leGroup.add(leSprite);
			}
		});

		addCallback("addLuaSpriteGroup", function(tag:String, front:Bool = false) {
			var leGroup:ModchartGroup = game.modchartGroups.get(tag);
			var playMembers:Array<FlxBasic> = game.members;
			if (leGroup != null) {
				if (!leGroup.wasAdded) {
					if (front) LuaUtils.getInstance().add(leGroup);
					else {
						if(game.isDead)
							GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), leGroup);
						else {
							var position:Int = playMembers.indexOf(game.gfGroup);
							if(playMembers.indexOf(game.boyfriendGroup) < position) position = playMembers.indexOf(game.boyfriendGroup);
							else if(playMembers.indexOf(game.dadGroup) < position) position = playMembers.indexOf(game.dadGroup);
							game.insert(position, leGroup);
						}
					}
					leGroup.wasAdded = true;
				}
			}
		});
		addCallback("addLuaSprite", function(tag:String, front:Bool = false) {
			var shit:ModchartSprite = game.modchartSprites.get(tag);
			if (shit == null) return false;

			if(front) LuaUtils.getInstance().add(shit);
			else {
				if(game.isDead)
					GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), shit);
				else{
					var position:Int = game.members.indexOf(game.gfGroup);
					if(game.members.indexOf(game.boyfriendGroup) < position)
						position = game.members.indexOf(game.boyfriendGroup);
					else if(game.members.indexOf(game.dadGroup) < position)
						position = game.members.indexOf(game.dadGroup);
					game.insert(position, shit);
				}
			}
			return true;
		});
		addCallback("setGraphicSize", function(obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true) {
			var poop:FlxSprite = LuaUtils.getVarInstance(obj);
			if (poop == null) return false;

			poop.setGraphicSize(x, y);
			if (updateHitbox) poop.updateHitbox();
			return true;
		});
		addCallback("setGroupGraphicSize", function(tag:String, x:Int, y:Int = 0, updateHitbox:Bool = true) {
			var leGroup:ModchartGroup = game.modchartGroups.get(tag);
			if (leGroup != null) {
				leGroup.setGraphicSize(x, y);
				if (updateHitbox) leGroup.updateHitbox();
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
			var leGroup:ModchartGroup = game.modchartGroups.get(tag);
			if (leGroup != null) {
				leGroup.scale.set(x, y);
				if (updateHitbox) leGroup.updateHitbox();
			}
		});
		addCallback("updateGroupHitbox", function(tag:String) {
			var leGroup:ModchartGroup = game.modchartGroups.get(tag);
			if (leGroup != null) leGroup.updateHitbox();	
		});
		addCallback("updateHitbox", function(obj:String) {
			if(game.getLuaObject(obj) != null) {
				var shit:FlxSprite = game.getLuaObject(obj);
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
		addCallback("updateHitboxFromGroup", function(group:String, index:Int) {
			if(Std.isOfType(Reflect.getProperty(LuaUtils.getInstance(), group), FlxTypedGroup)) {
				Reflect.getProperty(LuaUtils.getInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(LuaUtils.getInstance(), group)[index].updateHitbox();
		});

		addCallback("centerOffsets", function(obj:String) {
			if(game.getLuaObject(obj) != null) {
				var shit:FlxSprite = game.getLuaObject(obj);
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
		addCallback("centerOffsetsFromGroup", function(group:String, index:Int) {
			if(Std.isOfType(Reflect.getProperty(LuaUtils.getInstance(), group), FlxTypedGroup)) {
				Reflect.getProperty(LuaUtils.getInstance(), group).members[index].centerOffsets();
				return;
			}
			Reflect.getProperty(LuaUtils.getInstance(), group)[index].centerOffsets();
		});

		addCallback("removeSpriteFromGroup", function(tag:String, spr:String, destroy:Bool = true) {
			var leGroup:ModchartGroup = game.modchartGroups.get(tag);
			if (leGroup != null) {
				var leSprite:ModchartSprite = game.modchartSprites.get(spr);
				if (leSprite != null && leGroup.members.contains(leSprite)) {
					leGroup.remove(leSprite);
					if (destroy) leGroup.destroy();
				}
			}
		});
		addCallback("removeLuaSprite", function(tag:String, destroy:Bool = true) {
			var pee:ModchartSprite = game.modchartSprites.get(tag);
			if (pee == null) return false;

			if (destroy) pee.kill();
			LuaUtils.getInstance().remove(pee, true);
			if (destroy) {
				pee.destroy();
				game.modchartSprites.remove(tag);
			}
			return true;
		});

		addCallback("stampSprite", function(sprite:String, brush:String, x:Int, y:Int) {
			if(!game.modchartSprites.exists(sprite) || !game.modchartSprites.exists(brush)) return false;

			game.modchartSprites.get(sprite).stamp(game.modchartSprites.get(brush), x, y);
			return true;
		});

		addCallback("luaSpriteExists", function(tag:String) {
			return game.modchartSprites.exists(tag);
		});
		addCallback("luaTextExists", function(tag:String) {
			return game.modchartTexts.exists(tag);
		});
		addCallback("luaSoundExists", function(tag:String) {
			return game.modchartSounds.exists(tag);
		});

		addCallback("setHealthBarColors", function(leftHex:String, rightHex:String) {
			var left = CoolUtil.colorFromString(leftHex);
			var right = CoolUtil.colorFromString(rightHex);

			if (leftHex == null) left = game.dad.getColor();
			if (rightHex == null) right = game.boyfriend.getColor();

			game.healthBar.setColors(left, right);
		});
		addCallback("setTimeBarColors", function(left:String, right:String) {
			game.timeBar.createFilledBar(CoolUtil.colorFromString(left), CoolUtil.colorFromString(right));
			game.timeBar.updateBar();
		});
		addCallback("setTimeBarColorsWithGradient", function(leftHex:Array<String>, rightHex:Array<String>) {
			var left:Array<FlxColor> = [CoolUtil.colorFromString(leftHex[0]), CoolUtil.colorFromString(leftHex[1])];
			var right:Array<FlxColor> = [CoolUtil.colorFromString(rightHex[0]), CoolUtil.colorFromString(rightHex[1])];

			game.timeBar.createGradientBar(left, right, 1, 90);
			game.timeBar.updateBar();
		});

		addCallback("setObjectCamera", function(obj:String, camera:String = '') {
			var poop:FlxBasic = LuaUtils.getVarInstance(obj);
			if (poop == null) return false;

			poop.camera = LuaUtils.cameraFromString(camera);
			return true;
		});
		addCallback("setBlendMode", function(obj:String, blend:String = '') {
			var spr:FlxSprite = LuaUtils.getVarInstance(obj);
			if (spr == null) return false;

			spr.blend = LuaUtils.blendModeFromString(blend);
			return true;
		});
		addCallback("screenCenterGroup", function(tag:String, pos:String = 'xy') {
			var leGroup:ModchartGroup = game.modchartGroups.get(tag);
			if (leGroup != null) {
				switch (pos.toLowerCase().trim()) {
					case 'x': leGroup.screenCenter(X);
					case 'y': leGroup.screenCenter(Y);
					default: leGroup.screenCenter();
				}
			}
		});
		addCallback("screenCenter", function(obj:String, pos:String = 'xy') {
			var spr:FlxSprite = LuaUtils.getVarInstance(obj);
			if (spr == null) return false;

			switch(pos.trim().toLowerCase()) {
				case 'x': spr.screenCenter(X);
				case 'y': spr.screenCenter(Y);
				default: spr.screenCenter();
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
			path = Paths.modsJson('charts/${Paths.formatToSongPath(PlayState.SONG.song)}/$dialogueFile');
			if(!FileSystem.exists(path))
			#end
				path = Paths.json('charts/${Paths.formatToSongPath(PlayState.SONG.song)}/$dialogueFile');
			luaTrace('startDialogue: Trying to load dialogue: ' + path);
			#if MODS_ALLOWED
			if(FileSystem.exists(path))
			#else
			if(Assets.exists(path))
			#end {
				var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
				if(shit.dialogue.length > 0) {
					game.startDialogue(shit, music);
					luaTrace('Successfully loaded dialogue', false, false, FlxColor.GREEN);
					return true;
				} else luaTrace('Your dialogue file is badly formatted!', false, false, FlxColor.RED);
			} else {
				luaTrace('startDialogue: Dialogue file not found', false, false, FlxColor.RED);
				if(game.endingSong)
					game.endSong();
				else game.startCountdown();
			}
			return false;
		});
		addCallback("startVideo", function(videoFile:String) {
			#if VIDEOS_ALLOWED
			if(FileSystem.exists(Paths.video(videoFile))) {
				game.startVideo(videoFile);
				return true;
			}
			
			luaTrace('startVideo: Video file not found: ' + videoFile, false, false, FlxColor.RED);
			return false;

			#else
			game.startAndEnd();
			return true;
			#end
		});
		addCallback("startVideoSprite", function(videoFile:String, x:Float = 0, y:Float = 0, op:Float = 1, cam:String = 'world', ?loop:Bool = false, ?pauseMusic:Bool = false) {
			#if VIDEOS_ALLOWED
			if(FileSystem.exists(Paths.video(videoFile))) {
				game.startVideoSprite(videoFile, x, y, op, cam, loop, pauseMusic);
				return true;
			} else luaTrace('startVideoSprite: Video file not found: ' + videoFile, false, false, FlxColor.RED);
			return false;
			#else
			game.startAndEnd();
			return true;
			#end
		});

		addCallback("playMusic", function(sound:String, volume:Float = 1, loop:Bool = false) {
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});
		addCallback("playSound", function(sound:String, volume:Float = 1, ?tag:String = null) {
			if(tag != null && tag.length > 0) {
				tag = tag.replace('.', '');
				if(game.modchartSounds.exists(tag)) {
					game.modchartSounds.get(tag).stop();
				}
				game.modchartSounds.set(tag, FlxG.sound.play(Paths.sound(sound), volume, false, function() {
					game.modchartSounds.remove(tag);
					game.callOnLuas('onSoundFinished', [tag]);
				}));
				return;
			}
			FlxG.sound.play(Paths.sound(sound), volume);
		});
		addCallback("stopSound", function(tag:String) {
			if(tag != null && tag.length > 1 && game.modchartSounds.exists(tag)) {
				game.modchartSounds.get(tag).stop();
				game.modchartSounds.remove(tag);
			}
		});
		addCallback("pauseSound", function(tag:String) {
			if(tag != null && tag.length > 1 && game.modchartSounds.exists(tag)) {
				game.modchartSounds.get(tag).pause();
			}
		});
		addCallback("resumeSound", function(tag:String) {
			if(tag != null && tag.length > 1 && game.modchartSounds.exists(tag)) {
				game.modchartSounds.get(tag).play();
			}
		});
		addCallback("soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			if(tag == null || tag.length < 1) {
				FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			} else if(game.modchartSounds.exists(tag)) {
				game.modchartSounds.get(tag).fadeIn(duration * game.playbackRate, fromValue, toValue);
			}
		});
		addCallback("soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0) {
			if(tag == null || tag.length < 1) {
				FlxG.sound.music.fadeOut(duration, toValue);
			} else if(game.modchartSounds.exists(tag)) {
				game.modchartSounds.get(tag).fadeOut(duration * game.playbackRate, toValue);
			}
		});
		addCallback("soundFadeCancel", function(tag:String) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music.fadeTween != null) {
					FlxG.sound.music.fadeTween.cancel();
				}
			} else if(game.modchartSounds.exists(tag)) {
				var theSound:FlxSound = game.modchartSounds.get(tag);
				if(theSound.fadeTween != null) {
					theSound.fadeTween.cancel();
					game.modchartSounds.remove(tag);
				}
			}
		});
		addCallback("getSoundVolume", function(tag:String) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null)
					return FlxG.sound.music.volume;
			} else if(game.modchartSounds.exists(tag))
				return game.modchartSounds.get(tag).volume;
			return 0;
		});
		addCallback("setSoundVolume", function(tag:String, value:Float) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null)
					FlxG.sound.music.volume = value;
			} else if(game.modchartSounds.exists(tag)) {
				game.modchartSounds.get(tag).volume = value;
			}
		});
		addCallback("getSoundTime", function(tag:String) {
			if(tag != null && tag.length > 0 && game.modchartSounds.exists(tag))
				return game.modchartSounds.get(tag).time;
			return 0;
		});
		addCallback("setSoundTime", function(tag:String, value:Float) {
			if(tag != null && tag.length > 0 && game.modchartSounds.exists(tag)) {
				var theSound:FlxSound = game.modchartSounds.get(tag);
				if(theSound != null) theSound.time = value;
			}
		});
		addCallback("getSoundPitch", function(tag:String) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null)
					return FlxG.sound.music.pitch;
			} else if (game.modchartSounds.exists(tag))
				return game.modchartSounds.get(tag).pitch;
			
			return 1;
		});
		addCallback("setSoundPitch", function(tag:String, value:Float = 1) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null)
					FlxG.sound.music.pitch = value;
			} else if (game.modchartSounds.exists(tag)) {
				var theSound:FlxSound = game.modchartSounds.get(tag);
				if(theSound != null) theSound.pitch = value;
			}
		});

		addCallback("debugPrint", Reflect.makeVarArgs(function(toPrint:Array<Dynamic>) {
			luaTrace(toPrint.join(", "), true, false);
		}));

		addLocalCallback("close", function(l:FunkinLua):Bool {
			PlayState.instance.luaArray.remove(this);
			trace('Closing script $scriptName');
			return l.closed = true;
		});

		addCallback("changePresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
			#if discord_rpc
			game.presenceChangedByLua = true;
			Discord.changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
			#end
		});

		// LUA TEXTS
		addCallback("makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float) {
			tag = tag.replace('.', '');
			LuaUtils.resetTextTag(tag);
			var leText:FlxText = new FlxText(x, y, width, text, 16);
			leText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
			leText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2);
			leText.cameras = [game.camHUD];
			leText.scrollFactor.set();
			game.modchartTexts.set(tag, leText);
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
		addCallback("setTextBorder", function(tag:String, size:Int, color:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.borderSize = size;
				obj.borderColor = CoolUtil.colorFromString(color);
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
		addCallback("setTextColor", function(tag:String, color:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.color = CoolUtil.colorFromString(color);
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
			if(obj != null && obj.text != null)
				return obj.text;
			luaTrace("getTextString: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		addCallback("getTextSize", function(tag:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) return obj.size;
			luaTrace("getTextSize: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return -1;
		});
		addCallback("getTextFont", function(tag:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) return obj.font;
			luaTrace("getTextFont: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		addCallback("getTextWidth", function(tag:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) return obj.fieldWidth;
			luaTrace("getTextWidth: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return 0;
		});

		addCallback("addLuaText", function(tag:String) {
			if(game.modchartTexts.exists(tag)) {
				LuaUtils.getInstance().add(game.modchartTexts.get(tag));
			}
		});
		addCallback("removeLuaText", function(tag:String, destroy:Bool = true) {
			if(!game.modchartTexts.exists(tag)) return;

			var text:FlxText = game.modchartTexts.get(tag);
			if(destroy) text.kill();

			LuaUtils.getInstance().remove(text, true);

			if(destroy) {
				text.destroy();
				game.modchartTexts.remove(tag);
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
	public function initGlobals(game:PlayState) {
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
		set('healthGainMult', game.healthGain);
		set('healthLossMult', game.healthLoss);
		set('playbackRate', game.playbackRate);
		set('instakillOnMiss', game.instakillOnMiss);
		set('botPlay', game.cpuControlled);
		set('practice', game.practiceMode);

		for (i in 0...Note.ammo[PlayState.mania]) {
			set('defaultPlayerStrumX' + i, 0);
			set('defaultPlayerStrumY' + i, 0);
			set('defaultOpponentStrumX' + i, 0);
			set('defaultOpponentStrumY' + i, 0);
		}

		// Default character positions woooo
		set('defaultBoyfriendX', game.BF_X);
		set('defaultBoyfriendY', game.BF_Y);
		set('defaultOpponentX', game.DAD_X);
		set('defaultOpponentY', game.DAD_Y);
		set('defaultGirlfriendX', game.GF_X);
		set('defaultGirlfriendY', game.GF_Y);

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
		#if LUA_ALLOWED
		if (lua == null) return;
		Lua.close(lua);
		lua = null;

		#if (HSCRIPT_ALLOWED)
		if(hscript != null) hscript.interp = null;
		hscript = null;
		#end
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
	
	public function addLocalCallback(name:String, myFunction:Dynamic) {
		#if LUA_ALLOWED
		callbacks.set(name, myFunction);
		Lua_helper.add_callback(lua, name, null); //just so that it gets called
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120) {
		if(!ClientPrefs.getPref('shaders')) return false;

		#if (!flash && sys)
		if(runtimeShaders.exists(name)) {
			luaTrace('Shader $name was already initialized!');
			return true;
		}

		#if MODS_ALLOWED
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
		#end
		luaTrace('Missing shader $name .frag AND .vert files!', false, false, FlxColor.RED);
		#else
		luaTrace('This platform doesn\'t support Runtime Shaders!', false, false, FlxColor.RED);
		#end
		return false;
	}
}