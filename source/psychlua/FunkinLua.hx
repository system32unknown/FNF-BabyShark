package psychlua;

import flixel.FlxBasic;
import cutscenes.DialogueBoxPsych;
import substates.GameOverSubstate;
import states.*;
import backend.Highscore;
import backend.Song;
import objects.StrumNote;

class FunkinLua {
	#if LUA_ALLOWED public var lua:State = null; #end
	public var scriptName:String = '';
	public var modFolder:String = null;
	public var closed:Bool = false;

	public var hscript:HScript = null;

	public var callbacks:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static var customFunctions:Map<String, Dynamic> = new Map<String, Dynamic>();
	public function new(script:String) {
		#if LUA_ALLOWED
		var times:Float = Date.now().getTime();
		lua = LuaL.newstate();
		LuaL.openlibs(lua);

		this.scriptName = script.trim();
		var game:PlayState = PlayState.instance;
		if(game != null) game.luaArray.push(this);

		var myFolder:Array<String> = this.scriptName.split('/');
		if('${myFolder[0]}/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) //is inside mods folder
			this.modFolder = myFolder[1];

		// Lua shit
		set('Function_StopLua', LuaUtils.Function_StopLua);
		set('Function_StopHScript', LuaUtils.Function_StopHScript);
		set('Function_StopAll', LuaUtils.Function_StopAll);
		set('Function_Stop', LuaUtils.Function_Stop);
		set('Function_Continue', LuaUtils.Function_Continue);
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('engine', {
			version: Main.engineVer.version.trim(),
			app_version: lime.app.Application.current.meta.get('version'),
			commit: Main.engineVer.COMMIT_NUM,
			hash: Main.engineVer.COMMIT_HASH.trim(),
			buildTarget: LuaUtils.getBuildTarget()
		});

		// Song/Week shit
		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.bpm);
		set('scrollSpeed', PlayState.SONG.speed);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', FlxG.sound.music.length);
		set('songName', PlayState.SONG.song);
		set('songPath', Paths.formatToSongPath(PlayState.SONG.song));
		set('loadedSongName', Song.loadedSongName);
		set('loadedSongPath', Paths.formatToSongPath(Song.loadedSongName));
		set('chartPath', Song.chartPath);
		set('startedCountdown', false);
		set('curStage', PlayState.SONG.stage);

		set('isStoryMode', PlayState.isStoryMode);
		set('difficulty', PlayState.storyDifficulty);

		set('difficultyName', Difficulty.getString(false));
		set('difficultyPath', Paths.formatToSongPath(Difficulty.getString(false)));
		set('difficultyNameTranslation', Difficulty.getString(true));
		set('weekRaw', PlayState.storyWeek);
		set('week', data.WeekData.weeksList[PlayState.storyWeek]);
		set('seenCutscene', PlayState.seenCutscene);
		set('hasVocals', PlayState.SONG.needsVoices);

		// Camera pos
		set('cameraX', 0);
		set('cameraY', 0);

		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		if(game != null) {
			set('curSection', 0);
			set('curBeat', 0);
			set('curStep', 0);
			set('curDecBeat', 0);
			set('curDecStep', 0);
	
			set('score', 0);
			set('misses', 0);
			set('hits', 0);
			set('combo', 0);
	
			set('mania', PlayState.SONG.mania);
	
			set('rating', 0);
			set('ratingAccuracy', 0);
			set('ratingName', '');
			set('ratingFC', '');
	
			set('inGameOver', false);
			set('mustHitSection', false);
			set('altAnim', false);
			set('gfSection', false);
	
			set('healthGainMult', game.healthGain);
			set('healthLossMult', game.healthLoss);
			set('playbackRate', #if FLX_PITCH game.playbackRate #else 1 #end);
			set('instakillOnMiss', game.instakillOnMiss);
			set('botPlay', game.cpuControlled);
			set('practice', game.practiceMode);
	
			for (i in 0...EK.keys(PlayState.mania)) {
				set('defaultPlayerStrumX' + i, 0);
				set('defaultPlayerStrumY' + i, 0);
				set('defaultOpponentStrumX' + i, 0);
				set('defaultOpponentStrumY' + i, 0);
			}
	
			// Default character data
			set('defaultBoyfriendX', game.BF_X);
			set('defaultBoyfriendY', game.BF_Y);
			set('defaultOpponentX', game.DAD_X);
			set('defaultOpponentY', game.DAD_Y);
			set('defaultGirlfriendX', game.GF_X);
			set('defaultGirlfriendY', game.GF_Y);
	
			set('boyfriendName', PlayState.SONG.player1);
			set('dadName', PlayState.SONG.player2);
			set('gfName', PlayState.SONG.gfVersion);
		}

		// Other settings
		set('downscroll', ClientPrefs.data.downScroll);
		set('middlescroll', ClientPrefs.data.middleScroll);
		set('framerate', ClientPrefs.data.framerate);
		set('ghostTapping', ClientPrefs.data.ghostTapping);
		set('hideHud', ClientPrefs.data.hideHud);
		set('timeBarType', ClientPrefs.data.timeBarType);
		set('cameraZoomOnBeat', ClientPrefs.data.camZooms);
		set('flashingLights', ClientPrefs.data.flashing);
		set('noteOffset', ClientPrefs.data.noteOffset);
		set('healthBarAlpha', ClientPrefs.data.healthBarAlpha);
		set('noResetButton', ClientPrefs.data.noReset);
		set('lowQuality', ClientPrefs.data.lowQuality);
		set('shadersEnabled', ClientPrefs.data.shaders);
		set('scriptName', scriptName);
		set('currentModDirectory', Mods.currentModDirectory);

		set('noteSkin', ClientPrefs.data.noteSkin);
		set('noteSkinPostfix', objects.Note.getNoteSkinPostfix());
		set('splashSkin', ClientPrefs.data.splashSkin);
		set('splashSkinPostfix', objects.NoteSplash.getSplashSkinPostfix());
		set('splashAlpha', ClientPrefs.data.splashAlpha);

		set("getRunningScripts", () -> return [for (script in game.luaArray) script.scriptName]);

		set("setOnScripts", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
			if(exclusions == null) exclusions = [];
			if(ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
			game.setOnScripts(varName, arg, exclusions);
		});
		set("setOnHScript", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
			if(exclusions == null) exclusions = [];
			if(ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
			game.setOnHScript(varName, arg, exclusions);
		});
		set("setOnLuas", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
			if(exclusions == null) exclusions = [];
			if(ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
			game.setOnLuas(varName, arg, exclusions);
		});

		set("callOnScripts", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops=false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null) {
			if(excludeScripts == null) excludeScripts = [];
			if(ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);
			game.callOnScripts(funcName, args, ignoreStops, excludeScripts, excludeValues);
			return true;
		});
		set("callOnLuas", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops=false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null) {
			if(excludeScripts == null) excludeScripts = [];
			if(ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);
			game.callOnLuas(funcName, args, ignoreStops, excludeScripts, excludeValues);
			return true;
		});
		set("callOnHScript", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops=false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null) {
			if(excludeScripts == null) excludeScripts = [];
			if(ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);
			game.callOnHScript(funcName, args, ignoreStops, excludeScripts, excludeValues);
			return true;
		});

		set("callScript", function(luaFile:String, funcName:String, args:Array<Dynamic>) {
			if(args == null) args = [];

			var foundScript:String = findScript(luaFile);
			if(foundScript != null)
				for (luaInstance in game.luaArray)
					if(luaInstance.scriptName == foundScript) {
						luaInstance.call(funcName, args);
						return;
					}
		});

		set("setGlobalFromScript", function(luaFile:String, global:String, val:Dynamic) { // sets the global from a script
			var foundScript:String = findScript(luaFile);
			if(foundScript != null)
				for (luaInstance in game.luaArray)
					if(luaInstance.scriptName == foundScript)
						luaInstance.set(global, val);
		});

		set("getGlobalFromScript", function(luaFile:String, global:String) { // returns the global from a script
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

		set("isRunning", function(luaFile:String) {
			var foundScript:String = findScript(luaFile);
			if(foundScript != null)
				for (luaInstance in game.luaArray)
					if(luaInstance.scriptName == foundScript) return true;
			return false;
		});

		set("setVar", function(varName:String, value:Dynamic) {
			MusicBeatState.getVariables().set(varName, value);
			return value;
		});
		set("getVar", MusicBeatState.getVariables().get);

		set("addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false) { //would be dope asf.
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
		set("addHScript", function(hscriptFile:String, ?ignoreAlreadyRunning:Bool = false) {
			#if HSCRIPT_ALLOWED
			var foundScript:String = findScript(hscriptFile, '.hx');
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
		set("removeLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false):Bool {
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
		set("removeHScript", function(hscriptFile:String, ?ignoreAlreadyRunning:Bool = false) {
			#if HSCRIPT_ALLOWED
			var foundScript:String = findScript(hscriptFile, '.hx');
			if (foundScript != null) {
				if (!ignoreAlreadyRunning)
					for (script in game.hscriptArray)
						if (script.origin == foundScript) {
							trace('Closing script: ' + script.origin);
							game.hscriptArray.remove(script);
							script.destroy();
							return true;
						}
			}
	
			luaTrace('removeHScript: Script $hscriptFile isn\'t running!', false, false, FlxColor.RED);
			#else
			luaTrace('removeHScript: HScript is not supported on this platform!', false, false, FlxColor.RED);
			#end
	
			return false;
		});

		set("loadSong", function(?name:String = null, ?difficultyNum:Int = -1, ?difficultyArray:Array<String> = null) {
			if (difficultyArray != null) Difficulty.list = difficultyArray;
			if(name == null || name.length <= 0) name = Song.loadedSongName;
			if (difficultyNum == -1) difficultyNum = PlayState.storyDifficulty;

			Song.loadFromJson(Highscore.formatSong(name, difficultyNum), name);
			PlayState.storyDifficulty = difficultyNum;
			FlxG.state.persistentUpdate = false;
			LoadingState.loadAndSwitchState(() -> new PlayState());

			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;
			if(game != null && game.vocals != null) {
				game.vocals.pause();
				game.vocals.volume = 0;
			}
			FlxG.camera.followLerp = 0;
		});

		set("loadGraphic", function(variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0) {
			var spr:FlxSprite = LuaUtils.getVarInstance(variable);
			if (spr == null || image == null || image.length <= 0) return false;

			spr.loadGraphic(Paths.image(image), (gridX != 0 || gridY != 0), gridX, gridY);
			return true;
		});
		set("loadFrames", function(variable:String, image:String, spriteType:String = "sparrow") {
			var spr:FlxSprite = LuaUtils.getVarInstance(variable);
			if (spr == null || image == null || image.length <= 0) return false;

			LuaUtils.loadFrames(spr, image, spriteType);
			return true;
		});

		//shitass stuff for epic coders like me B) *image of obama giving himself a medal*
		set("getObjectOrder", function(obj:String) {
			var obj:FlxBasic = LuaUtils.getVarInstance(obj);
			if (obj != null) return LuaUtils.getInstance().members.indexOf(obj);
			luaTrace('getObjectOrder: Object $obj doesn\'t exist!', false, false, FlxColor.RED);
			return -1;
		});
		set("setObjectOrder", function(obj:String, position:Int) {
			var obj:FlxBasic = LuaUtils.getVarInstance(obj);

			if (obj != null) {
				LuaUtils.getInstance().remove(obj, true);
				LuaUtils.getInstance().insert(position, obj);
				return true;
			}
			luaTrace('setObjectOrder: Object $obj doesn\'t exist!', false, false, FlxColor.RED);
			return false;
		});

		// gay ass tweens
		set("startTween", function(tag:String, vars:String, values:Any = null, duration:Float, options:Any = null) {
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(penisExam != null) {
				if(values != null) {
					var myOptions:LuaUtils.LuaTweenOptions = LuaUtils.getLuaTween(options);
					if(tag != null) {
						var variables:Map<String, Dynamic> = MusicBeatState.getVariables();
						tag = 'tween_${LuaUtils.formatVariable(tag)}';
						variables.set(tag, FlxTween.tween(penisExam, values, duration, {
							type: myOptions.type,
							ease: myOptions.ease,
							startDelay: myOptions.startDelay,
							loopDelay: myOptions.loopDelay,

							onUpdate: (twn:FlxTween) -> if(myOptions.onUpdate != null) game.callOnLuas(myOptions.onUpdate, [tag, vars]),
							onStart: (twn:FlxTween) -> if(myOptions.onStart != null) game.callOnLuas(myOptions.onStart, [tag, vars]),
							onComplete: (twn:FlxTween) -> {
								if(myOptions.onComplete != null) game.callOnLuas(myOptions.onComplete, [tag, vars]);
								if(twn.type == FlxTweenType.ONESHOT || twn.type == FlxTweenType.BACKWARD) variables.remove(tag);
							}
						}));
					} else FlxTween.tween(penisExam, values, duration, {type: myOptions.type, ease: myOptions.ease, startDelay: myOptions.startDelay, loopDelay: myOptions.loopDelay});
				} else luaTrace('startTween: No values on 2nd argument!', false, false, FlxColor.RED);
			} else luaTrace('startTween: Couldnt find object: ' + vars, false, false, FlxColor.RED);
		});
		set("doTweenAdvAngle", function(tag:String, vars:String, value:Array<Float>, duration:Float, ease:String) {
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(penisExam != null) {
				if(tag != null) {
					var originalTag:String = tag;
					tag = LuaUtils.formatVariable('tween_$tag');
					var variables:Map<String, Dynamic> = MusicBeatState.getVariables();
					variables.set(tag, FlxTween.angle(penisExam, value[0], value[1], duration * game.playbackRate, {ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: (twn:FlxTween) -> {
							game.callOnLuas('onTweenCompleted', [tag]);
							variables.remove(tag);
						}
					}));
				} else FlxTween.angle(penisExam, value[0], value[1], duration * game.playbackRate, {ease: LuaUtils.getTweenEaseByString(ease)});
			} else luaTrace('doTweenAdvAngle: Couldnt find object: ' + vars, false, false, FlxColor.RED);
		});
		set("doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String) {
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(penisExam != null) {
				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;

				if(tag != null) {
					var originalTag:String = tag;
					tag = LuaUtils.formatVariable('tween_$tag');
					var variables:Map<String, Dynamic> = MusicBeatState.getVariables();
					variables.set(tag, FlxTween.color(penisExam, duration, curColor, CoolUtil.colorFromString(targetColor), {ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							variables.remove(tag);
							if (game != null) game.callOnLuas('onTweenCompleted', [originalTag, vars]);
						}
					}));
				} else FlxTween.color(penisExam, duration, curColor, CoolUtil.colorFromString(targetColor), {ease: LuaUtils.getTweenEaseByString(ease)});
			} else luaTrace('doTweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
		});

		// bisexual note tween
		set("noteTween", function(tag:String, note:Int, fieldsNValues:Dynamic, duration:Float, ease:String) {
			LuaUtils.cancelTween(tag);
			var strumNote:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];
			if(strumNote == null) return;

			if(tag != null) {
				var originalTag:String = tag;
				tag = LuaUtils.formatVariable('tween_$tag');
				var variables:Map<String, Dynamic> = MusicBeatState.getVariables();
				variables.set(tag, FlxTween.tween(strumNote, fieldsNValues, duration, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: (twn:FlxTween) -> {
						variables.remove(tag);
						if(PlayState.instance != null) PlayState.instance.callOnLuas('onTweenCompleted', [originalTag]);
					}
				}));
			} else FlxTween.tween(strumNote, fieldsNValues, duration, {ease: LuaUtils.getTweenEaseByString(ease)});
		});
		set("mouseClicked", function(button:String) {
			return switch(button.trim().toLowerCase()) {
				case 'middle': FlxG.mouse.justPressedMiddle;
				case 'right': FlxG.mouse.justPressedRight;
				default: FlxG.mouse.justPressed;
			}
		});
		set("mousePressed", function(button:String) {
			return switch(button.trim().toLowerCase()) {
				case 'middle': FlxG.mouse.pressedMiddle;
				case 'right': FlxG.mouse.pressedRight;
				default: FlxG.mouse.pressed;
			}
		});
		set("mouseReleased", function(button:String) {
			return switch(button.trim().toLowerCase()) {
				case 'middle': FlxG.mouse.justReleasedMiddle;
				case 'right': FlxG.mouse.justReleased;
				default: FlxG.mouse.justReleased;
			}
		});

		set("cancelTween", LuaUtils.cancelTween);

		set("runTimer", function(tag:String, time:Float = 1, loops:Int = 1) {
			LuaUtils.cancelTimer(tag);
			var variables:Map<String, Dynamic> = MusicBeatState.getVariables();

			var originalTag:String = tag;
			tag = LuaUtils.formatVariable('timer_$tag');
			variables.set(tag, new FlxTimer().start(time, (tmr:FlxTimer) -> {
				if(tmr.finished) variables.remove(tag);
				game.callOnLuas('onTimerCompleted', [originalTag, tmr.loops, tmr.loopsLeft]);
			}, loops));
		});
		set("cancelTimer", LuaUtils.cancelTimer);

		//stupid bietch ass functions
		set("addScore", function(value:Int = 0) {
			game.songScore += value;
			game.RecalculateRating();
		});
		set("addMisses", function(value:Int = 0) {
			game.songMisses += value;
			game.RecalculateRating();
		});
		set("addHits", function(value:Int = 0) {
			game.songHits += value;
			game.RecalculateRating();
		});
		set("setScore", function(value:Int = 0) {
			game.songScore = value;
			game.RecalculateRating();
		});
		set("setMisses", function(value:Int = 0) {
			game.songMisses = value;
			game.RecalculateRating();
		});
		set("setHits", function(value:Int = 0) {
			game.songHits = value;
			game.RecalculateRating();
		});
		set("getScore", () -> return game.songScore);
		set("getMisses", () -> return game.songMisses);
		set("getAccuracy", () -> return game.ratingAccuracy);
		set("getHits", () -> return game.songHits);

		set("getHighscore", Highscore.getScore);
		set("getSavedRating", Highscore.getRating);
		set("getSavedCombo", Highscore.getCombo);
		set("getWeekScore", Highscore.getWeekScore);

		set("setHealth", (value:Float = 0) -> game.health = value);
		set("addHealth", (value:Float = 0) -> game.health += value);
		set("getHealth", () -> return game.health);

		set("FlxColor", FlxColor.fromString);
		set("getColorFromName", FlxColor.fromString);
		set("getColorFromString", FlxColor.fromString);
		set("getColorFromHex", (color:String) -> return FlxColor.fromString('#$color'));
		set("getColorFromRgb", (rgb:Array<Int>) -> return FlxColor.fromRGB(rgb[0], rgb[1], rgb[2]));
		set("getDominantColor", function(tag:String) {
			if (tag == null) return 0;
			return SpriteUtil.dominantColor(LuaUtils.getObjectDirectly(tag));
		});

		set("addCharacterToList", function(name:String, type:String) {
			game.addCharacterToList(name, switch(type.toLowerCase()) {
				case 'dad' | 'opponent': 1;
				case 'gf' | 'girlfriend': 2;
				default: 0;
			});
		});
		set("precacheImage", (name:String, ?allowGPU:Bool = true) -> Paths.image(name, allowGPU));
		set("precacheSound", Paths.sound);
		set("precacheMusic", Paths.music);

		set("triggerEvent", (name:String, arg1:Any, arg2:Any) -> game.triggerEvent(name, arg1, arg2));

		set("startCountdown", game.startCountdown);
		set("endSong", () -> {
			game.KillNotes();
			return game.endSong();
		});
		set("restartSong", function(?skipTransition:Bool = false) {
			game.persistentUpdate = false;
			FlxG.camera.followLerp = 0;
			substates.PauseSubState.restartSong(skipTransition);
			return true;
		});
		set("exitSong", function(?skipTransition:Bool = false) {
			if(skipTransition) {
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
			}

			FlxG.switchState(() -> PlayState.isStoryMode ? new StoryMenuState() : new FreeplayState());
			#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
			game.transitioning = true;
			FlxG.camera.followLerp = 0;
			Mods.loadTopMod();
			return true;
		});
		set("getSongPosition", () -> return Conductor.songPosition);

		set("getCharacterX", (type:String) -> return switch(type.toLowerCase()) {
			case 'dad' | 'opponent': game.dadGroup.x;
			case 'gf' | 'girlfriend': game.gfGroup.x;
			default: game.boyfriendGroup.x;
		});
		set("setCharacterX", (type:String, value:Float) -> return switch(type.toLowerCase()) {
			case 'dad' | 'opponent': game.dadGroup.x = value;
			case 'gf' | 'girlfriend': game.gfGroup.x = value;
			default: game.boyfriendGroup.x = value;
		});
		set("getCharacterY", (type:String) -> return switch(type.toLowerCase()) {
			case 'dad' | 'opponent': game.dadGroup.y;
			case 'gf' | 'girlfriend': game.gfGroup.y;
			default: game.boyfriendGroup.y;
		});
		set("setCharacterY", (type:String, value:Float) -> return switch(type.toLowerCase()) {
			case 'dad' | 'opponent': game.dadGroup.y = value;
			case 'gf' | 'girlfriend': game.gfGroup.y = value;
			default: game.boyfriendGroup.y = value;
		});

		set("cameraSetTarget", function(target:String) {
			switch(target.toLowerCase()) { //we do some copy and pasteing.
				case 'dad' | 'opponent': game.moveCamera('dad');
				case 'gf' | 'girlfriend': game.moveCamera('gf');
				default: game.moveCamera('bf');
			}
			return target;
		});
		set("cameraShake", (camera:String, intensity:Float, duration:Float, axes:String = 'xy') -> LuaUtils.cameraFromString(camera).shake(intensity, duration * game.playbackRate, true, LuaUtils.axesFromString(axes)));
		set("cameraFlash", (camera:String, color:String, duration:Float, forced:Bool) -> LuaUtils.cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration * game.playbackRate, null, forced));
		set("cameraFade", (camera:String, color:String, duration:Float, forced:Bool) -> LuaUtils.cameraFromString(camera).fade(CoolUtil.colorFromString(color), duration * game.playbackRate, false, null, forced));

		set("setRatingPercent", (value:Float) -> return game.ratingPercent = value);
		set("setRatingName", (value:String) -> return game.ratingName = value);
		set("setRatingFC", (value:String) -> return game.ratingFC = value);

		set("getMouseX", (camera:String) -> return LuaUtils.getMousePoint(camera, 'x'));
		set("getMouseY", (camera:String) -> return LuaUtils.getMousePoint(camera, 'y'));
		set("getMidpointX", (variable:String) -> return LuaUtils.getPoint(variable, 'midpoint', 'x'));
		set("getMidpointY", (variable:String) -> return LuaUtils.getPoint(variable, 'midpoint', 'y'));
		set("getGraphicMidpointX", (variable:String) -> return LuaUtils.getPoint(variable, 'graphic', 'x'));
		set("getGraphicMidpointY", (variable:String) -> return LuaUtils.getPoint(variable, 'graphic', 'y'));
		set("getScreenPositionX", (variable:String, ?camera:String) -> return LuaUtils.getPoint(variable, 'screen', 'x', camera));
		set("getScreenPositionY", (variable:String, ?camera:String) -> return LuaUtils.getPoint(variable, 'screen', 'y', camera));

		set("characterDance", function(character:String, force:Bool = false) {
			switch(character.toLowerCase()) {
				case 'dad' | 'opponent': game.dad.dance(force);
				case 'gf' | 'girlfriend': if(game.gf != null) game.gf.dance(force);
				default: game.boyfriend.dance(force);
			}
		});

		set("makeLuaSprite", function(tag:String, image:String = null, x:Float = 0, y:Float = 0) {
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);

			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if(image != null && image.length > 0) leSprite.loadGraphic(Paths.image(image));
			leSprite.antialiasing = ClientPrefs.data.antialiasing;
			MusicBeatState.getVariables().set(tag, leSprite);
		});
		set("makeAnimatedLuaSprite", function(tag:String, image:String = null, x:Float = 0, y:Float = 0, ?spriteType:String = "sparrow") {
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);

			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			leSprite.antialiasing = ClientPrefs.data.antialiasing;
			if(image != null && image.length > 0) LuaUtils.loadFrames(leSprite, image, spriteType);
			MusicBeatState.getVariables().set(tag, leSprite);
		});

		set("makeGraphic", function(obj:String, width:Int = 256, height:Int = 256, color:String = 'FFFFFF') {
			var spr:FlxSprite = LuaUtils.getVarInstance(obj, true);

			if (spr == null) return false;
			spr.makeGraphic(width, height, CoolUtil.colorFromString(color));
			return true;
		});
		set("addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			var obj:FlxSprite = cast LuaUtils.getObjectDirectly(obj, false);
			if(obj != null && obj.animation != null) {
				obj.animation.addByPrefix(name, prefix, framerate, loop);
				if(obj.animation.curAnim == null) {
					var dyn:Dynamic = cast obj;
					if(dyn.playAnim != null) dyn.playAnim(name, true);
					else dyn.animation.play(name, true);
				}
				return true;
			}
			return false;
		});

		set("addAnimation", function(obj:String, name:String, frames:Array<Int>, framerate:Int = 24, loop:Bool = true) {
			var obj:FlxSprite = LuaUtils.getObjectDirectly(obj, false);
			if(obj != null && obj.animation != null) {
				obj.animation.add(name, frames, framerate, loop);
				if(obj.animation.curAnim == null) {
					var dyn:Dynamic = cast obj;
					if(dyn.playAnim != null) dyn.playAnim(name, true);
					else dyn.animation.play(name, true);
				}
				return true;
			}
			return false;
		});

		set("addAnimationByIndices", (obj:String, name:String, prefix:String, indices:Any, framerate:Int = 24, loop:Bool = false) -> return LuaUtils.addAnimByIndices(obj, name, prefix, indices, framerate, loop));

		set("playAnim", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0) {
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if(obj.playAnim != null) {
				obj.playAnim(name, forced, reverse, startFrame);
				return true;
			} else {
				if(obj.anim != null) obj.anim.play(name, forced, reverse, startFrame); //FlxAnimate
				else obj.animation.play(name, forced, reverse, startFrame);
				return true;
			}
			return false;
		});

		set("addOffset", function(obj:String, anim:String, x:Float, y:Float) {
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if(obj != null && obj.addOffset != null) {
				obj.addOffset(anim, x, y);
				return true;
			}
			return false;
		});

		set("setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float) {
			var obj:flixel.FlxObject = LuaUtils.getVarInstance(obj);
			if (obj == null) return false;

			obj.scrollFactor.set(scrollX, scrollY);
			return true;
		});

		set("addLuaSprite", function(tag:String, front:Bool = false) {
			var mySprite:FlxSprite = MusicBeatState.getVariables().get(tag);
			if(mySprite == null) return false;

			var instance = LuaUtils.getInstance();
			if(front) instance.add(mySprite);
			else {
				if(PlayState.instance == null || !PlayState.instance.isDead)
					instance.insert(instance.members.indexOf(LuaUtils.getLowestCharacterGroup()), mySprite);
				else GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), mySprite);
			}
			return true;
		});
		set("setGraphicSize", function(obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true) {
			var poop:FlxSprite = LuaUtils.getVarInstance(obj);
			if (poop == null) return false;

			poop.setGraphicSize(x, y);
			if (updateHitbox) poop.updateHitbox();
			return true;
		});
		set("scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true) {
			var poop:FlxSprite = LuaUtils.getVarInstance(obj);
			if (poop == null) return false;

			poop.scale.set(x, y);
			if (updateHitbox) poop.updateHitbox();
			return true;
		});
		set("updateHitbox", function(obj:String) {
			if(game.getLuaObject(obj) != null) {
				game.getLuaObject(obj).updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(LuaUtils.getInstance(), obj);
			if(poop != null) {
				poop.updateHitbox();
				return;
			}
			luaTrace('updateHitbox: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		set("updateHitboxFromGroup", function(group:String, index:Int) {
			if(Std.isOfType(Reflect.getProperty(LuaUtils.getInstance(), group), FlxTypedGroup)) {
				Reflect.getProperty(LuaUtils.getInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(LuaUtils.getInstance(), group)[index].updateHitbox();
		});

		set("centerOffsets", function(obj:String) {
			if(game.getLuaObject(obj) != null) {
				game.getLuaObject(obj).centerOffsets();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(LuaUtils.getInstance(), obj);
			if(poop != null) {
				poop.centerOffsets();
				return;
			}
			luaTrace('centerOffsets: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		set("centerOffsetsFromGroup", function(group:String, index:Int) {
			if(Std.isOfType(Reflect.getProperty(LuaUtils.getInstance(), group), FlxTypedGroup)) {
				Reflect.getProperty(LuaUtils.getInstance(), group).members[index].centerOffsets();
				return;
			}
			Reflect.getProperty(LuaUtils.getInstance(), group)[index].centerOffsets();
		});

		set("removeLuaSprite", function(tag:String, destroy:Bool = true, ?group:String = null) {
			var obj:FlxSprite = LuaUtils.getObjectDirectly(tag);
			if(obj == null || obj.destroy == null) return false;

			var groupObj:Dynamic = null;
			if(group == null) groupObj = LuaUtils.getInstance();
			else groupObj = LuaUtils.getObjectDirectly(group);

			groupObj.remove(obj, true);
			if(destroy) {
				MusicBeatState.getVariables().remove(tag);
				obj.destroy();
			}
			return true;
		});

		set("stampSprite", function(sprite:String, brush:String, x:Int, y:Int) {
			var variables:Map<String, Dynamic> = MusicBeatState.getVariables();
			if(!variables.exists(sprite) || !variables.exists(brush)) return false;
			variables.get(sprite).stamp(variables.get(brush), x, y);
			return true;
		});

		Lua_helper.add_callback(lua, "luaSpriteExists", function(tag:String) {
			var obj:FlxSprite = MusicBeatState.getVariables().get(tag);
			return (obj != null && Std.isOfType(obj, FlxSprite));
		});
		Lua_helper.add_callback(lua, "luaTextExists", function(tag:String) {
			var obj:FlxSprite = MusicBeatState.getVariables().get(tag);
			return (obj != null && Std.isOfType(obj, FlxText));
		});
		Lua_helper.add_callback(lua, "luaSoundExists", function(tag:String) {
			var obj:FlxSprite = MusicBeatState.getVariables().get(tag);
			return (obj != null && Std.isOfType(obj, FlxSound));
		});

		set("setHealthBarColors", (left:String, right:String) -> LuaUtils.setBarColors(game.healthBar, left, right));
		set("setTimeBarColors", (left:String, right:String) -> LuaUtils.setBarColors(game.timeBar, left, right));

		set("setObjectCamera", function(obj:String, camera:String = '') {
			var spr:FlxBasic = LuaUtils.getVarInstance(obj);
			if (spr != null) {
				spr.camera = LuaUtils.cameraFromString(camera);
				return true;
			} 
			luaTrace('setObjectCamera: Object $obj doesn\'t exist!', false, false, FlxColor.RED);
			return false;
		});
		set("setBlendMode", function(obj:String, blend:String = '') {
			var spr:FlxSprite = LuaUtils.getVarInstance(obj);
			if (spr == null) return false;
			spr.blend = LuaUtils.blendModeFromString(blend);
			return true;
		});
		set("screenCenter", function(obj:String, pos:String = 'xy') {
			var spr:FlxSprite = LuaUtils.getVarInstance(obj);
			if (spr == null) return false;
			spr.screenCenter(LuaUtils.axesFromString(pos));
			return true;
		});
		set("objectsOverlap", function(obj1:String, obj2:String) {
			var obj1:FlxBasic = LuaUtils.getVarInstance(obj1), obj2:FlxBasic = LuaUtils.getVarInstance(obj2);
			if (obj1 == null || obj2 == null) return false;
			return FlxG.overlap(obj1, obj2);
		});
		set("getPixelColor", function(obj:String, x:Int, y:Int) {
			var spr:FlxSprite = LuaUtils.getVarInstance(obj);
			if(spr != null) return spr.pixels.getPixel32(x, y);
			return FlxColor.BLACK;
		});

		set("startDialogue", function(dialogueFile:String, music:String = null) {
			var path:String;
			var songPath:String = Paths.formatToSongPath(Song.loadedSongName);
			#if TRANSLATIONS_ALLOWED
			path = Paths.getPath('data/${Paths.CHART_PATH}/$songPath/${dialogueFile}_${ClientPrefs.data.language}.json');
			if(!#if MODS_ALLOWED FileSystem.exists(path) #else Assets.exists(path, TEXT) #end)
			#end
				path = Paths.getPath('data/${Paths.CHART_PATH}/$songPath/$dialogueFile.json');

			luaTrace('startDialogue: Trying to load dialogue: $path');
			
			if(#if MODS_ALLOWED FileSystem.exists(path) #else Assets.exists(path, TEXT) #end) {
				var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
				if(shit.dialogue.length > 0) {
					game.startDialogue(shit, music);
					luaTrace('startDialogue: Successfully loaded dialogue', false, false, FlxColor.GREEN);
					return true;
				} else luaTrace('startDialogue: Your dialogue file is badly formatted!', false, false, FlxColor.RED);
			} else {
				luaTrace('startDialogue: Dialogue file not found', false, false, FlxColor.RED);
				game.startAndEnd();
			}
			return false;
		});
		set("startVideo", (videoFile:String, ?canSkip:Bool = true) -> {
			#if VIDEOS_ALLOWED
			if(FileSystem.exists(Paths.video(videoFile))) {
				if(game.videoCutscene != null) {
					game.remove(game.videoCutscene);
					game.videoCutscene.destroy();
				}
				game.videoCutscene = game.startVideo(videoFile, false, canSkip);
				return true;
			} else luaTrace('startVideo: Video file not found: ' + videoFile, false, false, FlxColor.RED);
			return false;
			#else
			PlayState.instance.inCutscene = true;
			FlxTimer.wait(.1, () -> {
				PlayState.instance.inCutscene = false;
				game.startAndEnd();
			});
			return true;
			#end
		});
		set("debugPrint", (text:Dynamic = '', color:String = 'WHITE') -> PlayState.instance.addTextToDebug(text, CoolUtil.colorFromString(color)));
		// mod settings
		addLocalCallback("getModSetting", function(saveTag:String, ?modName:String = null) {
			if(modName == null) {
				if(this.modFolder == null) {
					luaTrace('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', false, false, FlxColor.RED);
					return null;
				} 
				modName = this.modFolder;
			}
			return LuaUtils.getModSetting(saveTag, modName);
		});
		set("close", () -> {
			trace('Closing script: $scriptName');
			return closed = true;
		});

		#if DISCORD_ALLOWED DiscordClient.addLuaCallbacks(this); #end
		#if HSCRIPT_ALLOWED HScript.implement(this); #end
		#if TRANSLATIONS_ALLOWED Language.addLuaCallbacks(this); #end
		#if flxanimate FlxAnimateFunctions.implement(this); #end
		ReflectionFunctions.implement(this);
		TextFunctions.implement(this);
		ExtraFunctions.implement(this);
		CustomSubstate.implement(this);
		ShaderFunctions.implement(this);
		DeprecatedFunctions.implement(this);
		SoundFunctions.implement(this);

		for (name => func in customFunctions) if(func != null) set(name, func);

		try {
			final isString:Bool = !FileSystem.exists(scriptName);
			final result:Dynamic = (!isString ? LuaL.dofile(lua, scriptName) : LuaL.dostring(lua, scriptName));

			final resultStr:String = Lua.tostring(lua, result);
			if(resultStr != null && result != 0) {
				Logs.trace(resultStr, ERROR);
				#if windows
				utils.system.NativeUtil.showMessageBox('Error on lua script!', resultStr);
				#else
				luaTrace('$scriptName\n$resultStr', true, false, FlxColor.RED);
				#end
				lua = null;
				return;
			}
			if(isString) scriptName = 'unknown';
		} catch(e:Dynamic) {
			Logs.trace(e, ERROR);
			return;
		}
		call('onCreate');
		trace('lua file loaded succesfully: $scriptName (${Std.int(Date.now().getTime() - times)}ms)');
		#end
	}

	public function addLocalCallback(name:String, myFunction:Dynamic) {
		#if LUA_ALLOWED
		callbacks.set(name, myFunction);
		Lua_helper.add_callback(lua, name, null); //just so that it gets called
		#end
	}

	public static function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, color:FlxColor = FlxColor.WHITE) {
		#if LUA_ALLOWED
		if(ignoreCheck || getBool('luaDebugMode')) {
			if(deprecated && !getBool('luaDeprecatedWarnings')) return;
			PlayState.instance.addTextToDebug(text, color);
		}
		#end
	}

	#if LUA_ALLOWED
	public static function getBool(variable:String) {
		if(lastCalledScript == null) return false;

		var lua:State = lastCalledScript.lua;
		if(lua == null) return false;

		Lua.getglobal(lua, variable);
		final result:String = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if(result == null) return false;
		return (result == 'true');
	}
	#end

	function findScript(scriptFile:String, ext:String = '.lua') {
		if(!scriptFile.endsWith(ext)) scriptFile += ext;
		var preloadPath:String = Paths.getSharedPath(scriptFile);
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(scriptFile);
		if(FileSystem.exists(scriptFile)) return scriptFile;
		else if(FileSystem.exists(path)) return path;
	
		if(FileSystem.exists(preloadPath))
		#else
		if(Assets.exists(preloadPath))
		#end
			return preloadPath;
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
				case Lua.LUA_ERRRUN: "Runtime Error";
				case Lua.LUA_ERRMEM: "Memory Allocation Error";
				case Lua.LUA_ERRERR: "Crtical Error";
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
		if (closed) return LuaUtils.Function_Continue;

		lastCalledFunction = func;
		lastCalledScript = this;
		try {
			if(lua == null) return LuaUtils.Function_Continue;

			Lua.getglobal(lua, func);
			var type:Int = Lua.type(lua, -1);

			if (type != Lua.LUA_TFUNCTION) {
				if (type > Lua.LUA_TNIL) luaTrace('ERROR ($func) - attempt to call a ' + LuaUtils.typeToString(type) + " value", false, false, FlxColor.RED);

				Lua.pop(lua, 1);
				return LuaUtils.Function_Continue;
			}

			var nargs:Int = 0;
			if (args != null) for (arg in args) {
				if (Convert.toLua(lua, arg)) nargs++;
				else luaTrace('WARNING ($func)): attempt to insert ${Type.typeof(arg)} (unsupported value type) as a argument', false, false, FlxColor.ORANGE);
			}
			var status:Int = Lua.pcall(lua, nargs, 1, 0);

			if (status != Lua.LUA_OK) {
				luaTrace('ERROR ($func): ${getErrorMessage(status)}', false, false, FlxColor.RED);
				return LuaUtils.Function_Continue;
			}

			var result:Dynamic = cast Convert.fromLua(lua, -1);
			if (result == null) result = LuaUtils.Function_Continue;

			Lua.pop(lua, 1);
			if(closed) stop();
			return result;
		} catch (e:Dynamic) Logs.trace(e, ERROR);
		#end
		return LuaUtils.Function_Continue;
	}

	public function set(variable:String, data:Any) {
		#if LUA_ALLOWED
		if (lua == null) return;

		if (Type.typeof(data) == TFunction) {
			Lua_helper.add_callback(lua, variable, data);
			return;
		}

		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
		#end
	}

	public function stop() {
		#if LUA_ALLOWED
		closed = true;

		if (lua == null) return;
		Lua.close(lua);
		lua = null;
		if(hscript != null) {
			hscript.active = false;
			hscript.destroy();
			hscript = null;
		}
		#end
	}

	public function oldTweenFunction(tag:String, vars:String, tweenValue:Any, duration:Float, ease:String, funcName:String) {
		var target:Dynamic = LuaUtils.tweenPrepare(tag, vars);
		var variables:Map<String, Dynamic> = MusicBeatState.getVariables();
		if(target != null) {
			if(tag != null) {
				var originalTag:String = tag;
				tag = LuaUtils.formatVariable('tween_$tag');
				variables.set(tag, FlxTween.tween(target, tweenValue, duration, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: (twn:FlxTween) -> {
						variables.remove(tag);
						if(PlayState.instance != null) PlayState.instance.callOnLuas('onTweenCompleted', [originalTag, vars]);
					}
				}));
			} else FlxTween.tween(target, tweenValue, duration, {ease: LuaUtils.getTweenEaseByString(ease)});
		} else luaTrace('$funcName: Couldnt find object: $vars', false, false, FlxColor.RED);
	}

	public function noteTweenFunction(tag:String, note:Int, data:Dynamic, duration:Float, ease:String) {
		if(PlayState.instance == null) return;

		var strumNote:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];
		if(strumNote == null) return;

		if(tag != null) {
			var originalTag:String = tag;
			tag = LuaUtils.formatVariable('tween_$tag');
			LuaUtils.cancelTween(tag);

			var variables:Map<String, Dynamic> = MusicBeatState.getVariables();
			variables.set(tag, FlxTween.tween(strumNote, data, duration, {ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: (twn:FlxTween) -> {
					variables.remove(tag);
					if(PlayState.instance != null) PlayState.instance.callOnLuas('onTweenCompleted', [originalTag]);
				}
			}));
		} else FlxTween.tween(strumNote, data, duration, {ease: LuaUtils.getTweenEaseByString(ease)});
	}

	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function initLuaShader(name:String, ?glslVersion:Int = 120) {
		if(!ClientPrefs.data.shaders) return false;

		#if (MODS_ALLOWED && !flash && sys)
		if(runtimeShaders.exists(name)) {
			var shaderData:Array<String> = runtimeShaders.get(name);
			if(shaderData != null && (shaderData[0] != null || shaderData[1] != null)) {
				luaTrace('Shader $name was already initialized!');
				return true;
			}
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));

		for(mod in Mods.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods('$mod/shaders/'));
		
		for (folder in foldersToCheck) {
			if(FileSystem.exists(folder)) {
				var frag:String = '$folder$name.frag';
				var vert:String = '$folder$name.vert';
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
					runtimeShaders.set(name, [frag, vert, Std.string(glslVersion)]);
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