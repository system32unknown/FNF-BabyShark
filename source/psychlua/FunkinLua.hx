package psychlua;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import substates.GameOverSubstate;
import substates.PauseSubState;
import states.*;
import cutscenes.DialogueBoxPsych;
import backend.Highscore;
import backend.Song;
import objects.StrumNote;
import objects.Note;
import utils.system.PlatformUtil;
import data.WeekData;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class FunkinLua {
	public static var Function_Stop:Dynamic = "##PSYCHLUA_FUNCTIONSTOP";
	public static var Function_Continue:Dynamic = "##PSYCHLUA_FUNCTIONCONTINUE";
	public static var Function_StopLua:Dynamic = "##PSYCHLUA_FUNCTIONSTOPLUA";
	public static var Function_StopHScript:Dynamic = "##PSYCHLUA_FUNCTIONSTOPHSCRIPT";
	public static var Function_StopAll:Dynamic = "##PSYCHLUA_FUNCTIONSTOPALL";
	
	#if LUA_ALLOWED
	public var lua:State = null;
	public final addCallback:(String, Dynamic)->Bool;
	#end
	public var scriptName:String = '';
	public var closed:Bool = false;

	#if (SScript >= "3.0.0")
	public var hscript:HScript = null;
	#end

	public var callbacks:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static var customFunctions:Map<String, Dynamic> = new Map<String, Dynamic>();
	public function new(script:String) {
		#if LUA_ALLOWED
		lua = LuaL.newstate();
		LuaL.openlibs(lua);

		this.scriptName = script;
		var game:PlayState = PlayState.instance;
		game.luaArray.push(this);
		initGlobals(game);

		addCallback = Lua_helper.add_callback.bind(lua);

		addCallback("getRunningScripts", () -> return [for (script in game.luaArray) script.scriptName]);

		addCallback("setOnScripts", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
			if(exclusions == null) exclusions = [];
			if(ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
			game.setOnScripts(varName, arg, exclusions);
		});
		addCallback("setOnHScript", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
			if(exclusions == null) exclusions = [];
			if(ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
			game.setOnHScript(varName, arg, exclusions);
		});
		addCallback("setOnLuas", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
			if(exclusions == null) exclusions = [];
			if(ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
			game.setOnLuas(varName, arg, exclusions);
		});

		addCallback("callOnScripts", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops=false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null) {
			if(excludeScripts == null) excludeScripts = [];
			if(ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);
			game.callOnScripts(funcName, args, ignoreStops, excludeScripts, excludeValues);
			return true;
		});
		addCallback("callOnLuas", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops=false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null) {
			if(excludeScripts == null) excludeScripts = [];
			if(ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);
			game.callOnLuas(funcName, args, ignoreStops, excludeScripts, excludeValues);
			return true;
		});
		addCallback("callOnHScript", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops=false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null) {
			if(excludeScripts == null) excludeScripts = [];
			if(ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);
			game.callOnHScript(funcName, args, ignoreStops, excludeScripts, excludeValues);
			return true;
		});

		addCallback("callScript", function(luaFile:String, funcName:String, args:Array<Dynamic>) {
			if(args == null) args = [];

			var foundScript:String = findScript(luaFile);
			if(foundScript != null)
				for (luaInstance in game.luaArray)
					if(luaInstance.scriptName == foundScript) {
						luaInstance.call(funcName, args);
						return;
					}
		});

		addCallback("callCppUtil", function(platformType:String, ?args:Array<Dynamic>) {
			final trimmedpft = platformType.trim();
			if (args == null) args = [];
			if (["setDPIAware", "getCurrentWalllpaper", "updateWallpaper", "disableClose"].contains(trimmedpft)) return null;

			return Reflect.callMethod(null, Reflect.field(PlatformUtil, trimmedpft), args);
		});

		addCallback("setGlobalFromScript", function(luaFile:String, global:String, val:Dynamic) { // returns the global from a script
			var foundScript:String = findScript(luaFile);
			if(foundScript != null)
				for (luaInstance in game.luaArray)
					if(luaInstance.scriptName == foundScript)
						luaInstance.set(global, val);
		});

		addCallback("getGlobalFromScript", function(luaFile:String, global:String) { // returns the global from a script
			var foundScript:String = findScript(luaFile);
			if(foundScript != null)
				for (luaInstance in game.luaArray)
					if(luaInstance.scriptName == foundScript) {
						Lua.getglobal(luaInstance.lua, global);
						if(Lua.isnumber(luaInstance.lua, -1))
							Lua.pushnumber(lua, Lua.tonumber(luaInstance.lua, -1));
						else if(Lua.isstring(luaInstance.lua, -1))
							Lua.pushstring(lua, Lua.tostring(luaInstance.lua, -1));
						else if(Lua.isboolean(luaInstance.lua, -1))
							Lua.pushboolean(lua, Lua.toboolean(luaInstance.lua, -1));
						else Lua.pushnil(lua);

						Lua.pop(luaInstance.lua, 1); // remove the global
						return;
					}
		});

		addCallback("isRunning", function(luaFile:String) {
			var foundScript:String = findScript(luaFile);
			if(foundScript != null)
				for (luaInstance in game.luaArray)
					if(luaInstance.scriptName == foundScript)
						return true;
			return false;
		});

		addCallback("setVar", function(varName:String, value:Dynamic) {
			PlayState.instance.variables.set(varName, value);
			return value;
		});
		addCallback("getVar", (varName:String) -> return PlayState.instance.variables.get(varName));

		addCallback("addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false) { //would be dope asf.
			var foundScript:String = findScript(luaFile);
			if(foundScript != null) {
				if(!ignoreAlreadyRunning)
					for (luaInstance in game.luaArray)
						if(luaInstance.scriptName == foundScript) {
							luaTrace('addLuaScript: The script "$foundScript" is already running!');
							return;
						}

				new FunkinLua(foundScript);
				return;
			}
			luaTrace("addLuaScript: Script doesn't exist!", false, false, FlxColor.RED);
		});
		addCallback("addHScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false) {
			#if HSCRIPT_ALLOWED
			var foundScript:String = findScript(luaFile, '.hx');
			if(foundScript != null) {
				if(!ignoreAlreadyRunning)
					for (script in game.hscriptArray)
						if(script.origin == foundScript) {
							luaTrace('addHScript: The script "$foundScript" is already running!');
							return;
						}
				PlayState.instance.initHScript(foundScript);
				return;
			}
			luaTrace("addHScript: Script doesn't exist!", false, false, FlxColor.RED);
			#else
			luaTrace("addHScript: HScript is not supported on this platform!", false, false, FlxColor.RED);
			#end
		});
		addCallback("removeLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false):Bool {
			var foundScript:String = findScript(luaFile);
			if(foundScript != null) {
				if(!ignoreAlreadyRunning)
					for (luaInstance in game.luaArray)
						if(luaInstance.scriptName == foundScript) {
							luaInstance.stop();
							trace('Closing script: ' + luaInstance.scriptName);
							return true;
						}
			}
			luaTrace('removeLuaScript: Script $luaFile isn\'t running!', false, false, FlxColor.RED);
			return false;
		});

		addCallback("loadSong", function(?name:String = null, ?difficultyNum:Int = -1, ?difficultyArray:Array<String> = null) {
			if (difficultyArray != null) Difficulty.list = difficultyArray;
			if(name == null || name.length <= 0) name = PlayState.SONG.song;
			if (difficultyNum == -1) difficultyNum = PlayState.storyDifficulty;

			var formattedsong = Highscore.formatSong(name, difficultyNum);
			PlayState.SONG = Song.loadFromJson(formattedsong, name);
			PlayState.storyDifficulty = difficultyNum;
			game.persistentUpdate = false;
			LoadingState.loadAndSwitchState(new PlayState());

			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;
			if(game.vocals != null) {
				game.vocals.pause();
				game.vocals.volume = 0;
			}
			FlxG.camera.followLerp = 0;
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

		addCallback("getPref", (pref:String) -> return ClientPrefs.getPref(pref));
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

						onUpdate: (twn:FlxTween) -> {
							if(myOptions.onUpdate != null) game.callOnLuas(myOptions.onUpdate, [tag, vars]);
						}, onStart: (twn:FlxTween) -> {
							if(myOptions.onStart != null) game.callOnLuas(myOptions.onStart, [tag, vars]);
						}, onComplete: (twn:FlxTween) -> {
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
					onComplete: (twn:FlxTween) -> {
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
					onComplete: (twn:FlxTween) -> {
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
					onComplete: (twn:FlxTween) -> {
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
					onComplete: (twn:FlxTween) -> {
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

		addCallback("cancelTween", (tag:String) -> LuaUtils.cancelTween(tag));

		addCallback("runTimer", function(tag:String, time:Float = 1, loops:Int = 1) {
			LuaUtils.cancelTimer(tag);
			game.modchartTimers.set(tag, new FlxTimer().start(time, (tmr:FlxTimer) -> {
				if(tmr.finished) game.modchartTimers.remove(tag);
				game.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
			}, loops));
		});
		addCallback("cancelTimer", (tag:String) -> {LuaUtils.cancelTimer(tag);});

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
		addCallback("getScore", () -> return game.songScore);
		addCallback("getMisses", () -> return game.songMisses);
		addCallback("getAccuracy", () -> return game.accuracy);
		addCallback("getHits", () -> return game.songHits);

		addCallback("getHighscore", (song:String, diff:Int) -> return Highscore.getScore(song, diff));
		addCallback("getSavedRating", (song:String, diff:Int) -> return Highscore.getRating(song, diff));
		addCallback("getSavedCombo", (song:String, diff:Int) -> return Highscore.getCombo(song, diff));
		addCallback("getWeekScore", (week:String, diff:Int) -> return Highscore.getWeekScore(week, diff));

		addCallback("setHealth", (value:Float = 0) -> game.health = value);
		addCallback("addHealth", (value:Float = 0) -> game.health += value);
		addCallback("getHealth", () -> return game.health);

		addCallback("FlxColor", (?color:String = '') -> return FlxColor.fromString(color));
		addCallback("getColorFromName", (?color:String = '') -> return FlxColor.fromString(color));
		addCallback("getColorFromString", (?color:String = '') -> return FlxColor.fromString(color));
		addCallback("getColorFromHex", (color:String) -> return FlxColor.fromString('#$color'));
		
		addCallback("getColorFromRgb", (rgb:Array<Int>) ->return FlxColor.fromRGB(rgb[0], rgb[1], rgb[2]));
		addCallback("getDominantColor", function(tag:String) {
			if (tag == null) return 0;
			return SpriteUtil.dominantColor(LuaUtils.getObjectDirectly(tag));
		});

		addCallback("addCharacterToList", function(name:String, type:String) {
			var charType:Int = switch(type.toLowerCase()) {
				case 'dad': 1;
				case 'gf' | 'girlfriend': 2;
				default: 0;
			}
			game.addCharacterToList(name, charType);
		});
		addCallback("precacheImage", (name:String) -> Paths.returnGraphic(name));
		addCallback("precacheSound", (name:String) -> Paths.sound(name));
		addCallback("precacheMusic", (name:String) -> Paths.music(name));

		addCallback("triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic) {
			var value1:String = arg1;
			var value2:String = arg2;
			game.triggerEvent(name, value1, value2, Conductor.songPosition);
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
		addCallback("getSongPosition", () -> Conductor.songPosition);

		addCallback("getCharacterX", function(type:String) {
			return switch(type.toLowerCase()) {
				case 'dad' | 'opponent': game.dadGroup.x;
				case 'gf' | 'girlfriend': game.gfGroup.x;
				default: game.boyfriendGroup.x;
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
			return switch(type.toLowerCase()) {
				case 'dad' | 'opponent': game.dadGroup.y;
				case 'gf' | 'girlfriend': game.gfGroup.y;
				default: game.boyfriendGroup.y;
			}
		});
		addCallback("setCharacterY", function(type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent': game.dadGroup.y = value;
				case 'gf' | 'girlfriend': game.gfGroup.y = value;
				default: game.boyfriendGroup.y = value;
			}
		});

		addCallback("changeMania", (newValue:Int, skipTwn:Bool = false) -> game.changeMania(newValue, skipTwn));

		addCallback("cameraSetTarget", function(target:String) {
			switch(target.toLowerCase()) { //we do some copy and pasteing.
				case 'dad' | 'opponent': game.moveCamera('dad');
				case 'gf' | 'girlfriend': game.moveCamera('gf');
				default: game.moveCamera('bf');
			}
			return target;
		});
		addCallback("cameraShake", (camera:String, intensity:Float, duration:Float, axes:String) -> LuaUtils.cameraFromString(camera).shake(intensity, duration * game.playbackRate, true, LuaUtils.axesFromString(axes)));
		addCallback("cameraFlash", (camera:String, color:String, duration:Float, forced:Bool) -> LuaUtils.cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration * game.playbackRate, null, forced));
		addCallback("cameraFade", (camera:String, color:String, duration:Float, forced:Bool) -> LuaUtils.cameraFromString(camera).fade(CoolUtil.colorFromString(color), duration * game.playbackRate, false, null, forced));

		addCallback("setRatingPercent", (value:Float) -> game.ratingPercent = value);
		addCallback("setRatingName", (value:String) -> game.ratingName = value);
		addCallback("setRatingFC", (value:String) -> game.ratingFC = value);

		addCallback("getMouseX", (camera:String) -> return FlxG.mouse.getScreenPosition(LuaUtils.cameraFromString(camera)).x);
		addCallback("getMouseY", (camera:String) -> return FlxG.mouse.getScreenPosition(LuaUtils.cameraFromString(camera)).y);

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
			leSprite.antialiasing = ClientPrefs.getPref('Antialiasing');
			game.modchartSprites.set(tag, leSprite);
		});
		addCallback("makeAnimatedLuaSprite", function(tag:String, image:String = null, x:Float = 0, y:Float = 0, ?spriteType:String = "sparrow") {
			tag = tag.replace('.', '');
			LuaUtils.resetSpriteTag(tag);

			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			leSprite.antialiasing = ClientPrefs.getPref('Antialiasing');
			LuaUtils.loadFrames(leSprite, image, spriteType);
			game.modchartSprites.set(tag, leSprite);
		});
		addCallback("makeLuaSpriteGroup", function(tag:String, ?x:Float = 0, ?y:Float = 0, ?maxSize:Int = 0) {
			tag = tag.replace('.', '');
			LuaUtils.resetSpriteTag(tag);
			game.modchartGroups.set(tag, new ModchartGroup(x, y, maxSize));
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
				if(obj.animation.curAnim == null) {
					if(obj.playAnim != null) obj.playAnim(name, true);
					else obj.animation.play(name, true);
				}
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
			if (leGroup != null) leGroup.scrollFactor.set(scrollX, scrollY);
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
				else {
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

		addCallback("luaSpriteExists", (tag:String) -> return game.modchartSprites.exists(tag));
		addCallback("luaTextExists", (tag:String) -> return game.modchartTexts.exists(tag));
		addCallback("luaSoundExists", (tag:String) -> return game.modchartSounds.exists(tag));

		addCallback("setHealthBarColors", function(left:String, right:String) {
			var left_color:Null<FlxColor> = null;
			var right_color:Null<FlxColor> = null;
			if (left != null && left != '') left_color = CoolUtil.colorFromString(left);
			if (right != null && right != '') right_color = CoolUtil.colorFromString(right);
			game.healthBar.setColors(left_color, right_color);
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
			if (leGroup != null) leGroup.screenCenter(LuaUtils.axesFromString(pos));
		});
		addCallback("screenCenter", function(obj:String, pos:String = 'xy') {
			var spr:FlxSprite = LuaUtils.getVarInstance(obj);
			if (spr == null) return false;
			spr.screenCenter(LuaUtils.axesFromString(pos));
			return true;
		});
		addCallback("objectsOverlap", function(obj1:String, obj2:String) {
			var guh1:FlxBasic = LuaUtils.getVarInstance(obj1), guh2:FlxBasic = LuaUtils.getVarInstance(obj2);
			if (guh1 == null || guh2 == null) return false;
			return FlxG.overlap(guh1, guh2);
		});
		addCallback("getPixelColor", function(obj:String, x:Int, y:Int) {
			var spr:FlxSprite = LuaUtils.getVarInstance(obj);
			if(spr != null) return spr.pixels.getPixel32(x, y);
			return FlxColor.BLACK;
		});

		addCallback("startDialogue", function(dialogueFile:String, music:String = null) {
			var path:String;
			#if MODS_ALLOWED
			path = Paths.modsJson('${Paths.CHART_PATH}/${Paths.formatToSongPath(PlayState.SONG.song)}/$dialogueFile');
			if(!FileSystem.exists(path))
			#end
				path = Paths.json('${Paths.CHART_PATH}/${Paths.formatToSongPath(PlayState.SONG.song)}/$dialogueFile');
			luaTrace('startDialogue: Trying to load dialogue: ' + path);
			
			if(#if MODS_ALLOWED FileSystem #else Assets #end.exists(path)) {
				var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
				if(shit.dialogue.length > 0) {
					game.startDialogue(shit, music);
					luaTrace('Successfully loaded dialogue', false, false, FlxColor.GREEN);
					return true;
				} else luaTrace('Your dialogue file is badly formatted!', false, false, FlxColor.RED);
			} else {
				luaTrace('startDialogue: Dialogue file not found', false, false, FlxColor.RED);
				game.startAndEnd();
			}
			return false;
		});
		addCallback("startVideo", function(videoFile:String) {
			#if VIDEOS_ALLOWED
			if(FileSystem.exists(Paths.video(videoFile))) {
				game.startVideo(videoFile);
				return true;
			} else luaTrace('startVideo: Video file not found: ' + videoFile, false, false, FlxColor.RED);
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
				if(FlxG.sound.music.fadeTween != null)
					FlxG.sound.music.fadeTween.cancel();
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
			if(tag != null && tag.length > 0 && game.modchartSounds.exists(tag))
				return game.modchartSounds.get(tag).pitch;
			return 0;
		});
		addCallback("setSoundPitch", function(tag:String, value:Float, doPause:Bool = false) {
			if(tag != null && tag.length > 0 && game.modchartSounds.exists(tag)) {
				var theSound:FlxSound = game.modchartSounds.get(tag);
				if(theSound != null) {
					var wasResumed:Bool = theSound.playing;
					if (doPause) theSound.pause();
					theSound.pitch = value;
					if (doPause && wasResumed) theSound.play();
				}
			}
		});
		addCallback("debugPrint", (text:Dynamic = '', color:String = 'WHITE') -> PlayState.instance.addTextToDebug(text, CoolUtil.colorFromString(color)));

		addCallback("close", function():Bool {
			trace('Closing script: $scriptName');
			return closed = true;
		});

		#if desktop Discord.addLuaCallbacks(this); #end
		#if HSCRIPT_ALLOWED HScript.implement(this); #end
		TextFunctions.implement(this);
		ReflectionFunctions.implement(this);
		ExtraFunctions.implement(this);
		CustomSubstate.implement(this);
		ShaderFunctions.implement(this);
		DeprecatedFunctions.implement(this);

		try {
			var result:Dynamic = LuaL.dofile(lua, scriptName);
			var resultStr:String = Lua.tostring(lua, result);
			if(resultStr != null && result != 0) {
				trace(resultStr);
				#if windows
				utils.system.NativeUtil.showMessageBox('Error on lua script!', resultStr, utils.system.PlatformUtil.MessageBoxIcon.MSG_WARNING);
				#else
				luaTrace('$scriptName\n$resultStr', true, false, FlxColor.RED);
				#end
				lua = null;
				return;
			}
		} catch(e:Dynamic) {
			trace(e);
			return;
		}
		trace('lua file loaded successfully: $scriptName');

		call('onCreate');
		#end
	}

	#if LUA_ALLOWED
	public function initGlobals(game:PlayState) {
		// Lua shit
		set('Function_StopLua', Function_StopLua);
		set('Function_StopHScript', Function_StopHScript);
		set('Function_StopAll', Function_StopAll);
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
		set('hasVocals', PlayState.SONG.needsVoices);

		// Camera poo
		set('cameraX', 0);
		set('cameraY', 0);

		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		// PlayState cringe ass nae nae bullcrap
		set('curSection', 0);
		set('curBeat', 0);
		set('curStep', 0);
		set('curDecBeat', 0);
		set('curDecStep', 0);

		set('score', 0);
		set('misses', 0);
		set('accuracy', 0);
		set('hits', 0);
		set('combo', 0);

		set('defaultMania', PlayState.SONG.mania);

		set('rating', 0);
		set('ratingName', '');
		set('ratingRank', '');
		set('ratingFC', '');
		set('engine', {
			version: Main.engineVer.version.trim(),
			app_version: lime.app.Application.current.meta.get('version'),
			commit: Main.engineVer.COMMIT_NUM,
			hash: Main.engineVer.COMMIT_HASH.trim(),
			build_target: getBuildTarget()
		});

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
		set('shadersEnabled', ClientPrefs.getPref('shaders'));
		set('scriptName', scriptName);

		for (name => func in customFunctions)
			if(func != null) addCallback(name, func);
	}
	#end

	public function addLocalCallback(name:String, myFunction:Dynamic) {
		#if LUA_ALLOWED
		callbacks.set(name, myFunction);
		addCallback(name, null); //just so that it gets called
		#end
	}

	public static function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, color:FlxColor = FlxColor.WHITE) {
		#if LUA_ALLOWED
		if(ignoreCheck || getBool('luaDebugMode')) {
			if(deprecated && !getBool('luaDeprecatedWarnings')) return;
			PlayState.instance.addTextToDebug(text, color);
		}
		trace(text);
		#end
	}

	#if LUA_ALLOWED
	public static function getBool(variable:String) {
		if(lastCalledScript == null) return false;

		var lua:State = lastCalledScript.lua;
		if(lua == null) return false;

		var result:String = null;
		Lua.getglobal(lua, variable);
		result = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if(result == null) return false;
		return (result == 'true');
	}
	#end

	function findScript(scriptFile:String, ext:String = '.lua') {
		if(!scriptFile.endsWith(ext)) scriptFile += ext;
		var preloadPath:String = Paths.getPreloadPath(scriptFile);
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(scriptFile);
		if(FileSystem.exists(scriptFile)) return scriptFile;
		else if(FileSystem.exists(path)) return path;
	
		if(FileSystem.exists(preloadPath))
		#else
		if(Assets.exists(preloadPath))
		#end
		{
			return preloadPath;
		}
		return null;
	}

	function getErrorMessage(status:Int = 0):String {
		#if LUA_ALLOWED
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
	public static var lastCalledScript:FunkinLua = null;
	public function call(func:String, ?args:Array<Dynamic>):Dynamic {
		#if LUA_ALLOWED
		if (closed) return Function_Continue;

		lastCalledFunction = func;
		lastCalledScript = this;
		try {
			if(lua == null) return Function_Continue;

			Lua.getglobal(lua, func);
			var type:Int = Lua.type(lua, -1);

			if (type != Lua.LUA_TFUNCTION) {
				if (type > Lua.LUA_TNIL) luaTrace('ERROR ($func) - attempt to call a ' + LuaUtils.typeToString(type) + " value", false, false, FlxColor.RED);

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
				luaTrace('ERROR ($func): ${getErrorMessage(status)}', false, false, FlxColor.RED);
				return Function_Continue;
			}

			var result:Dynamic = cast Convert.fromLua(lua, -1);
			if (result == null) result = Function_Continue;

			Lua.pop(lua, 1);
			if(closed) stop();
			return result;
		} catch (e:Dynamic) trace(e);
		#end
		return Function_Continue;
	}

	public function set(variable:String, data:Any) {
		#if LUA_ALLOWED
		if (lua == null) return;
		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
		#end
	}

	public function stop() {
		#if LUA_ALLOWED
		PlayState.instance.luaArray.remove(this);
		closed = true;

		if (lua == null) return;
		Lua.close(lua);
		lua = null;
		#if (SScript >= "3.0.0")
		if(hscript != null) {
			hscript.active = false;
			#if (SScript >= "3.0.3")
			hscript.destroy();
			#end
			hscript = null;
		}
		#end
		#end
	}

	//clone functions
	public static function getBuildTarget():String {
		return Sys.systemName().toLowerCase();
	}

	public function oldTweenFunction(tag:String, vars:String, tweenValue:Any, duration:Float, ease:String, funcName:String) {
		var target:Dynamic = LuaUtils.tweenPrepare(tag, vars);
		if(target != null) {
			PlayState.instance.modchartTweens.set(tag, FlxTween.tween(target, tweenValue, duration, {ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: (twn:FlxTween) -> {
					PlayState.instance.callOnLuas('onTweenCompleted', [tag, vars]);
					PlayState.instance.modchartTweens.remove(tag);
				}
			}));
		} else luaTrace('$funcName: Couldnt find object: $vars', false, false, FlxColor.RED);
	}

	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function initLuaShader(name:String, ?glslVersion:Int = 120) {
		if(!ClientPrefs.getPref('shaders')) return false;

		#if (MODS_ALLOWED && !flash && sys)
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