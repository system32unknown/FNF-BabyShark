package psychlua;

import flixel.FlxBasic;
import flixel.FlxState;
import flixel.FlxObject;
import cutscenes.DialogueBoxPsych;
import substates.GameOverSubstate;
import states.*;
import backend.Highscore;
import backend.Song;
import objects.StrumNote;
#if !MODS_ALLOWED import openfl.utils.Assets; #end
import flixel_5_3_1.ParallaxSprite; // flixel 5 render pipeline

class FunkinLua {
	#if LUA_ALLOWED public var lua:State = null; #end
	public var scriptName:String = '';
	public var modFolder:String = null;
	public var closed:Bool = false;

	public var callbacks:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static var customFunctions:Map<String, Dynamic> = new Map<String, Dynamic>();
	#if LUA_ALLOWED public var parentLua:FunkinLua; #end

	#if HSCRIPT_ALLOWED
	public var hscript:HScript = null;
	public function initHaxeModule(code:String = '', ?varsToBring:Dynamic) {
		@:privateAccess {
			if (hscript == null) {
				trace('initializing haxe interp for: $scriptName');
				hscript = new HScript(this);
			}
			try {
				if (hscript.scriptCode != code) {
					hscript.scriptCode = code;
					hscript.parse(true);
				}
			} catch (e:Dynamic) throw e;
			hscript.varsToBring = varsToBring;
		}
	}
	#end

	public function new(script:String) {
		#if LUA_ALLOWED
		lua = LuaL.newstate();
		LuaL.openlibs(lua);

		this.scriptName = script.trim();
		var game:PlayState = PlayState.instance;
		if (game != null) game.luaArray.push(this);

		var myFolder:Array<String> = this.scriptName.split('/');
		if ('${myFolder[0]}/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) //is inside mods folder
			this.modFolder = myFolder[1];

		// Lua shit
		set('Function_StopLua', LuaUtils.Function_StopLua);
		set('Function_StopHScript', LuaUtils.Function_StopHScript);
		set('Function_StopAll', LuaUtils.Function_StopAll);
		set('Function_Stop', LuaUtils.Function_Stop);
		set('Function_Continue', LuaUtils.Function_Continue);
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('version', Main.engineVer);
		set('engine', {
			app_version: lime.app.Application.current.meta.get('version'),
			commit: Main.engineVer.COMMIT_NUM,
			hash: Main.engineVer.COMMIT_HASH.trim()
		});
		set('modFolder', this.modFolder);

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
		set('difficultyPath', Difficulty.getFilePath());
		set('difficultyNameTranslation', Difficulty.getString(true));
		set('weekRaw', PlayState.storyWeek);
		set('week', data.WeekData.weeksList[PlayState.storyWeek]);
		set('seenCutscene', PlayState.seenCutscene);
		set('hasVocals', PlayState.SONG.needsVoices);

		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		if (game != null) @:privateAccess {
			var curSection:SwagSection = PlayState.SONG.notes[game.curSection];
			set('curSection', game.curSection);
			set('curBeat', game.curBeat);
			set('curStep', game.curStep);
			set('curDecBeat', game.curDecBeat);
			set('curDecStep', game.curDecStep);

			set('score', game.songScore);
			set('misses', game.songMisses);
			set('hits', game.songHits);
			set('combo', game.combo);
			set('deaths', PlayState.deathCounter);

			set('mania', PlayState.SONG.mania);

			set('rating', game.ratingPercent);
			set('ratingAccuracy', game.ratingAccuracy);
			set('ratingName', game.ratingName);
			set('ratingFC', game.ratingFC);
			set('totalPlayed', game.totalPlayed);
			set('totalNotesHit', game.totalNotesHit);

			set('inGameOver', GameOverSubstate.instance != null);
			set('mustHitSection', curSection != null ? (curSection.mustHitSection == true) : false);
			set('altAnim', curSection != null ? (curSection.altAnim == true) : false);
			set('gfSection', curSection != null ? (curSection.gfSection == true) : false);
	
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
	
			set('boyfriendName', game.boyfriend != null ? game.boyfriend.curCharacter : PlayState.SONG.player1);
			set('dadName', game.dad != null ? game.dad.curCharacter : PlayState.SONG.player2);
			set('gfName', game.gf != null ? game.gf.curCharacter : PlayState.SONG.gfVersion);
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
		set('antialiasing', ClientPrefs.data.antialiasing);
		set('shadersEnabled', ClientPrefs.data.shaders);
		set('scriptName', scriptName);
		set('currentModDirectory', Mods.currentModDirectory);

		set('noteSkin', ClientPrefs.data.noteSkin);
		set('noteSkinPostfix', objects.Note.getNoteSkinPostfix());
		set('splashSkin', ClientPrefs.data.splashSkin);
		set('splashSkinPostfix', objects.NoteSplash.getSplashSkinPostfix());
		set('splashAlpha', ClientPrefs.data.splashAlpha);

		set('buildTarget', LuaUtils.getTargetOS());

		set("getRunningScripts", () -> {
			var runningScripts:Array<String> = [];
			for (script in game.luaArray) runningScripts.push(script.scriptName);
			for (script in game.hscriptArray) runningScripts.push(script.origin);
			return runningScripts;
		});

		set("setOnScripts", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
			if (exclusions == null) exclusions = [];
			if (ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
			game.setOnScripts(varName, arg, exclusions);
		});
		set("setOnHScript", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
			if (exclusions == null) exclusions = [];
			if (ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
			game.setOnHScript(varName, arg, exclusions);
		});
		set("setOnLuas", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
			if (exclusions == null) exclusions = [];
			if (ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
			game.setOnLuas(varName, arg, exclusions);
		});

		set("callOnScripts", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null) {
			if (excludeScripts == null) excludeScripts = [];
			if (ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);
			return game.callOnScripts(funcName, args, ignoreStops, excludeScripts, excludeValues);
		});
		set("callOnLuas", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null) {
			if (excludeScripts == null) excludeScripts = [];
			if (ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);
			return game.callOnLuas(funcName, args, ignoreStops, excludeScripts, excludeValues);
		});
		set("callOnHScript", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null) {
			if (excludeScripts == null) excludeScripts = [];
			if (ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);
			return game.callOnHScript(funcName, args, ignoreStops, excludeScripts, excludeValues);
		});

		set("callScript", function(luaFile:String, funcName:String, args:Array<Dynamic>) {
			if (args == null) args = [];

			var luaPath:String = findScript(luaFile);
			if (luaPath != null)
				for (luaInstance in game.luaArray)
					if (luaInstance.scriptName == luaPath)
						return luaInstance.call(funcName, args);
			return null;
		});

		set("isRunning", (scriptFile:String) -> {
			var luaPath:String = findScript(scriptFile);
			if (luaPath != null) for (luaInstance in game.luaArray) if (luaInstance.scriptName == luaPath) return true;

			var hscriptPath:String = findScript(scriptFile, '.hx');
			if (hscriptPath != null) for (hscriptInstance in game.hscriptArray) if (hscriptInstance.origin == hscriptPath) return true;

			return false;
		});

		set("setVar", function(varName:String, value:Dynamic) {
			MusicBeatState.getVariables().set(varName, ReflectionFunctions.parseSingleInstance(value));
			return value;
		});
		set("getVar", MusicBeatState.getVariables().get);
		set("removeVar", MusicBeatState.getVariables().remove);

		set("addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false) {
			var luaPath:String = findScript(luaFile);
			if (luaPath != null) {
				if (!ignoreAlreadyRunning)
					for (luaInstance in game.luaArray)
						if (luaInstance.scriptName == luaPath) {
							luaTrace('addLuaScript: The script "' + luaPath + '" is already running!');
							return;
						}

				new FunkinLua(luaPath);
				return;
			}
			luaTrace("addLuaScript: Script doesn't exist!", false, false, FlxColor.RED);
		});
		set("addHScript", function(scriptFile:String, ?ignoreAlreadyRunning:Bool = false) {
			#if HSCRIPT_ALLOWED
			var scriptPath:String = findScript(scriptFile, '.hx');
			if (scriptPath != null) {
				if (!ignoreAlreadyRunning)
					for (script in game.hscriptArray)
						if (script.origin == scriptPath) {
							luaTrace('addHScript: The script "' + scriptPath + '" is already running!');
							return;
						}

				PlayState.instance.initHScript(scriptPath);
				return;
			}
			luaTrace("addHScript: Script doesn't exist!", false, false, FlxColor.RED);
			#else
			luaTrace("addHScript: HScript is not supported on this platform!", false, false, FlxColor.RED);
			#end
		});
		set("removeLuaScript", function(luaFile:String) {
			var luaPath:String = findScript(luaFile);
			if (luaPath != null) {
				var foundAny:Bool = false;
				for (luaInstance in game.luaArray) {
					if (luaInstance.scriptName == luaPath) {
						trace('Closing lua script $luaPath');
						luaInstance.stop();
						foundAny = true;
					}
				}
				if (foundAny) return true;
			}
			luaTrace('removeLuaScript: Script $luaFile isn\'t running!', false, false, FlxColor.RED);
			return false;
		});
		set("removeHScript", function(scriptFile:String) {
			#if HSCRIPT_ALLOWED
			var scriptPath:String = findScript(scriptFile, '.hx');
			if (scriptPath != null) {
				var foundAny:Bool = false;
				for (script in game.hscriptArray) {
					if (script.origin == scriptPath) {
						trace('Closing hscript $scriptPath');
						script.destroy();
						foundAny = true;
					}
				}
				if (foundAny) return true;
			}
			luaTrace('removeHScript: Script $scriptFile isn\'t running!', false, false, FlxColor.RED);
			return false;
			#else
			luaTrace("removeHScript: HScript is not supported on this platform!", false, false, FlxColor.RED);
			#end
		});

		set("loadSong", function(?name:String = null, ?difficultyNum:Int = -1, ?difficultyArray:Array<String> = null) {
			if (difficultyArray != null) Difficulty.list = difficultyArray;
			if (name == null || name.length <= 0) name = Song.loadedSongName;
			if (difficultyNum == -1) difficultyNum = PlayState.storyDifficulty;

			Song.loadFromJson(Highscore.formatSong(name, difficultyNum), name);
			PlayState.storyDifficulty = difficultyNum;
			FlxG.state.persistentUpdate = false;
			LoadingState.loadAndSwitchState(() -> new PlayState());

			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;
			if (game != null && game.vocals != null) {
				game.vocals.pause();
				game.vocals.volume = 0;
			}
			FlxG.camera.followLerp = 0;
		});

		set("loadGraphic", function(variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0) {
			var spr:FlxSprite = LuaUtils.getObjectLoop(variable);
			if (spr != null && image != null && image.length > 0)
				spr.loadGraphic(Paths.image(image), (gridX != 0 || gridY != 0), gridX, gridY);
		});
		set("loadFrames", function(variable:String, image:String, spriteType:String = "auto") {
			var spr:FlxSprite = LuaUtils.getObjectLoop(variable);
			if (spr != null && image != null && image.length > 0)
				LuaUtils.loadFrames(spr, image, spriteType);
		});
		set("loadMultipleFrames", function(variable:String, images:Array<String>) {
			var spr:FlxSprite = LuaUtils.getObjectLoop(variable);
			if (spr != null && images != null && images.length > 0)
				spr.frames = Paths.getMultiAtlas(images);
		});

		Lua_helper.add_callback(lua, "getObjectOrder", function(obj:String, ?group:String = null) {
			var leObj:FlxBasic = LuaUtils.getObjectDirectly(obj);
			if (leObj != null) {
				if (group != null) {
					var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
					if (groupOrArray != null) {
						switch (Type.typeof(groupOrArray)) {
							case TClass(Array): return groupOrArray.indexOf(leObj); //Is Array
							default: return Reflect.getProperty(groupOrArray, 'members').indexOf(leObj); //Has to use a Reflect here because of FlxTypedSpriteGroup
						}
					} else {
						luaTrace('getObjectOrder: Group $group doesn\'t exist!', false, false, FlxColor.RED);
						return -1;
					}
				}
				var groupOrArray:Dynamic = CustomSubstate.instance ?? LuaUtils.getTargetInstance();
				return groupOrArray.members.indexOf(leObj);
			}
			luaTrace('getObjectOrder: Object $obj doesn\'t exist!', false, false, FlxColor.RED);
			return -1;
		});
		Lua_helper.add_callback(lua, "setObjectOrder", function(obj:String, position:Int, ?group:String = null) {
			var leObj:FlxBasic = LuaUtils.getObjectDirectly(obj);
			if (leObj != null) {
				if (group != null) {
					var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
					if (groupOrArray != null) {
						switch (Type.typeof(groupOrArray)) {
							case TClass(Array): //Is Array
								groupOrArray.remove(leObj);
								groupOrArray.insert(position, leObj);
							default: //Is Group
								groupOrArray.remove(leObj, true);
								groupOrArray.insert(position, leObj);
						}
					} else luaTrace('setObjectOrder: Group $group doesn\'t exist!', false, false, FlxColor.RED);
				} else {
					var groupOrArray:Dynamic = CustomSubstate.instance ?? LuaUtils.getTargetInstance();
					groupOrArray.remove(leObj, true);
					groupOrArray.insert(position, leObj);
				}
				return;
			}
			luaTrace('setObjectOrder: Object $obj doesn\'t exist!', false, false, FlxColor.RED);
		});

		// gay ass tweens
		set("startTween", function(tag:String, vars:String, values:Any = null, duration:Float, ?options:Any = null) {
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if (penisExam != null) {
				if (values != null) {
					var myOptions:LuaUtils.LuaTweenOptions = LuaUtils.getLuaTween(options);
					if (tag != null) {
						var variables:Map<String, Dynamic> = MusicBeatState.getVariables();
						var originalTag:String = tag;
						tag = LuaUtils.formatVariable('tween_$tag');
						variables.set(tag, FlxTween.tween(penisExam, values, duration, myOptions != null ? {
							type: myOptions.type,
							ease: myOptions.ease,
							startDelay: myOptions.startDelay,
							loopDelay: myOptions.loopDelay,

							onUpdate: (twn:FlxTween) -> if (myOptions.onUpdate != null) game.callOnLuas(myOptions.onUpdate, [originalTag, vars]),
							onStart: (twn:FlxTween) -> if (myOptions.onStart != null) game.callOnLuas(myOptions.onStart, [originalTag, vars]),
							onComplete: (twn:FlxTween) -> {
								if (myOptions.onComplete != null) game.callOnLuas(myOptions.onComplete, [originalTag, vars]);
								if (twn.type == FlxTweenType.ONESHOT || twn.type == FlxTweenType.BACKWARD) variables.remove(tag);
							}
						} : null));
						return tag;
					} else FlxTween.tween(penisExam, values, duration, myOptions != null ? {
						type: myOptions.type,
						ease: myOptions.ease,
						startDelay: myOptions.startDelay,
						loopDelay: myOptions.loopDelay,

						onUpdate: (twn:FlxTween) -> if (myOptions.onUpdate != null) game.callOnLuas(myOptions.onUpdate, [null, vars]),
						onStart: (twn:FlxTween) -> if (myOptions.onStart != null) game.callOnLuas(myOptions.onStart, [null, vars]),
						onComplete: (twn:FlxTween) -> if (myOptions.onComplete != null) game.callOnLuas(myOptions.onComplete, [null, vars]),
					} : null);
				} else luaTrace('startTween: No values on 2nd argument!', false, false, FlxColor.RED);
			} else luaTrace('startTween: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			return null;
		});
		set("doTweenAdvAngle", function(tag:String, vars:String, value:Array<Float>, duration:Float, ease:String) {
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if (penisExam != null) {
				if (tag != null) {
					var originalTag:String = tag;
					tag = LuaUtils.formatVariable('tween_$tag');
					var variables:Map<String, Dynamic> = MusicBeatState.getVariables();
					variables.set(tag, FlxTween.angle(penisExam, value[0], value[1], duration * game.playbackRate, {ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: (twn:FlxTween) -> {
							game.callOnLuas('onTweenCompleted', [originalTag, tag]);
							variables.remove(tag);
						}
					}));
					return tag;
				} else FlxTween.angle(penisExam, value[0], value[1], duration * game.playbackRate, {ease: LuaUtils.getTweenEaseByString(ease)});
			} else luaTrace('doTweenAdvAngle: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			return null;
		});
		set("doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String) {
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if (penisExam != null) {
				targetColor = targetColor.trim();
				var newColor:FlxColor = CoolUtil.colorFromString(targetColor);
				if (targetColor.startsWith('0x') && targetColor.length == 8 || !FlxColor.colorLookup.exists(targetColor.toUpperCase()) && targetColor.length == 6) newColor.alphaFloat = penisExam.alpha;

				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;

				if (tag != null) {
					var originalTag:String = tag;
					tag = LuaUtils.formatVariable('tween_$tag');
					var variables:Map<String, Dynamic> = MusicBeatState.getVariables();
					variables.set(tag, FlxTween.color(penisExam, duration, curColor, newColor, {ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							variables.remove(tag);
							if (game != null) game.callOnLuas('onTweenCompleted', [originalTag, vars]);
						}
					}));
					return tag;
				} else FlxTween.color(penisExam, duration, curColor, CoolUtil.colorFromString(targetColor), {ease: LuaUtils.getTweenEaseByString(ease)});
			} else luaTrace('doTweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			return null;
		});

		// bisexual note tween
		set("noteTween", function(tag:String, note:Int, fieldsNValues:Dynamic, duration:Float, ease:String) {
			LuaUtils.cancelTween(tag);
			var strumNote:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];
			if (strumNote == null) return;

			if (tag != null) {
				var originalTag:String = tag;
				tag = LuaUtils.formatVariable('tween_$tag');
				var variables:Map<String, Dynamic> = MusicBeatState.getVariables();
				variables.set(tag, FlxTween.tween(strumNote, fieldsNValues, duration, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: (twn:FlxTween) -> {
						variables.remove(tag);
						if (PlayState.instance != null) PlayState.instance.callOnLuas('onTweenCompleted', [originalTag]);
					}
				}));
			} else FlxTween.tween(strumNote, fieldsNValues, duration, {ease: LuaUtils.getTweenEaseByString(ease)});
		});
		set("mouseClicked", function(button:String = 'left') {
			return switch (button.trim().toLowerCase()) {
				case 'middle': FlxG.mouse.justPressedMiddle;
				case 'right': FlxG.mouse.justPressedRight;
				default: FlxG.mouse.justPressed;
			}
		});
		set("mousePressed", function(button:String = 'left') {
			return switch (button.trim().toLowerCase()) {
				case 'middle': FlxG.mouse.pressedMiddle;
				case 'right': FlxG.mouse.pressedRight;
				default: FlxG.mouse.pressed;
			}
		});
		set("mouseReleased", function(button:String = 'left') {
			return switch (button.trim().toLowerCase()) {
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
				if (tmr.finished) variables.remove(tag);
				game.callOnLuas('onTimerCompleted', [originalTag, tmr.loops, tmr.loopsLeft]);
			}, loops));
			return tag;
		});
		set("cancelTimer", LuaUtils.cancelTimer);

		// stupid bietch ass functions
		set("addScore", function(value:Int = 0) {
			game.songScore += value;
			game.recalculateRating();
		});
		set("addMisses", function(value:Int = 0) {
			game.songMisses += value;
			game.recalculateRating();
		});
		set("addHits", function(value:Int = 0) {
			game.songHits += value;
			game.recalculateRating();
		});
		set("setScore", function(value:Int = 0) {
			game.songScore = value;
			game.recalculateRating();
			return value;
		});
		set("setMisses", function(value:Int = 0) {
			game.songMisses = value;
			game.recalculateRating();
			return value;
		});
		set("setHits", function(value:Int = 0) {
			game.songHits = value;
			game.recalculateRating();
			return value;
		});

		set("getHighscore", Highscore.getScore);
		set("getSavedRating", Highscore.getRating);
		set("getSavedCombo", Highscore.getCombo);
		set("getWeekScore", Highscore.getWeekScore);

		set("setHealth", (value:Float = 1) -> return game.health = value);
		set("addHealth", (value:Float = 0) -> game.health += value);
		set("getHealth", () -> return game.health);

		set("FlxColor", FlxColor.fromString);
		set("getColorFromName", FlxColor.fromString);
		set("getColorFromString", FlxColor.fromString);
		set("getColorFromHex", (color:String) -> return FlxColor.fromString('#$color'));
		set("getColorFromRgb", (rgb:Array<Int>) -> return FlxColor.fromRGB(rgb[0], rgb[1], rgb[2]));
		set("getDominantColor", function(tag:String) {
			if (tag == null) return FlxColor.BLACK;
			return SpriteUtil.dominantColor(LuaUtils.getObjectDirectly(tag));
		});

		set("addCharacterToList", function(name:String, type:String) {
			game.addCharacterToList(name, switch (type.toLowerCase()) {
				case 'dad' | 'opponent': 1;
				case 'gf' | 'girlfriend': 2;
				default: 0;
			});
		});
		set("precacheImage", (name:String, ?allowGPU:Bool = true) -> Paths.image(name, allowGPU));
		set("precacheSound", Paths.sound);
		set("precacheMusic", Paths.music);

		set("triggerEvent", (name:String, ?value1:String = '', ?value2:String = '') -> {
			game.triggerEvent(name, value1, value2);
			return true;
		});

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
			if (skipTransition) {
				MusicBeatState.skipNextTransIn = true;
				MusicBeatState.skipNextTransOut = true;
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

		set("getCharacterX", (type:String) -> return switch (type.toLowerCase()) {
			case 'dad' | 'opponent': game.dadGroup.x;
			case 'gf' | 'girlfriend': game.gfGroup.x;
			default: game.boyfriendGroup.x;
		});
		set("setCharacterX", (type:String, value:Float) -> return switch (type.toLowerCase()) {
			case 'dad' | 'opponent': game.dadGroup.x = value;
			case 'gf' | 'girlfriend': game.gfGroup.x = value;
			default: game.boyfriendGroup.x = value;
		});
		set("getCharacterY", (type:String) -> return switch (type.toLowerCase()) {
			case 'dad' | 'opponent': game.dadGroup.y;
			case 'gf' | 'girlfriend': game.gfGroup.y;
			default: game.boyfriendGroup.y;
		});
		set("setCharacterY", (type:String, value:Float) -> return switch (type.toLowerCase()) {
			case 'dad' | 'opponent': game.dadGroup.y = value;
			case 'gf' | 'girlfriend': game.gfGroup.y = value;
			default: game.boyfriendGroup.y = value;
		});

		set("cameraSetTarget", function(target:String) {
			switch (target.toLowerCase()) { //we do some copy and pasteing.
				case 'dad' | 'opponent': game.moveCamera('dad');
				case 'gf' | 'girlfriend': game.moveCamera('gf');
				default: game.moveCamera('bf');
			}
			return target;
		});

		set("setCameraScroll", function(x:Float, y:Float) FlxG.camera.scroll.set(x - FlxG.width / 2, y - FlxG.height / 2));
		set("setCameraFollowPoint", function(x:Float, y:Float) game.camFollow.setPosition(x, y));
		set("addCameraScroll", function(?x:Float = 0, ?y:Float = 0) FlxG.camera.scroll.add(x, y));
		set("addCameraFollowPoint", function(?x:Float = 0, ?y:Float = 0) {
			game.camFollow.x += x;
			game.camFollow.y += y;
		});
		set("getCameraScrollX", () -> FlxG.camera.scroll.x + FlxG.width / 2);
		set("getCameraScrollY", () -> FlxG.camera.scroll.y + FlxG.height / 2);
		set("getCameraFollowX", () -> game.camFollow.x);
		set("getCameraFollowY", () -> game.camFollow.y);
		set("cameraShake", (camera:String, intensity:Float, duration:Float, axes:String = 'xy') -> LuaUtils.cameraFromString(camera).shake(intensity, duration * game.playbackRate, true, LuaUtils.axesFromString(axes)));
		set("cameraFlash", (camera:String, color:String, duration:Float, forced:Bool) -> LuaUtils.cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration * game.playbackRate, null, forced));
		set("cameraFade", (camera:String, color:String, duration:Float, forced:Bool, ?fadeOut:Bool = false) -> LuaUtils.cameraFromString(camera).fade(CoolUtil.colorFromString(color), duration * game.playbackRate, fadeOut, null, forced));

		set("setRatingPercent", function(value:Float) {
			game.ratingPercent = value;
			game.setOnScripts('rating', game.ratingPercent);
			return game.ratingPercent;
		});
		set("setRatingAccuracy", function(value:Float) {
			game.ratingAccuracy = value;
			game.setOnScripts('ratingAccuracy', game.ratingAccuracy);
			return game.ratingAccuracy;
		});
		set("setRatingName", function(value:String) {
			game.ratingName = value;
			game.setOnScripts('ratingName', game.ratingName);
			return game.ratingName;
		});
		set("setRatingFC", function(value:String) {
			game.ratingFC = value;
			game.setOnScripts('ratingFC', game.ratingFC);
			return game.ratingFC;
		});
		set("updateScoreText", game.updateScoreText);

		set("getMouseX", (?camera:String = 'game') -> return LuaUtils.getMousePoint(camera, 'x'));
		set("getMouseY", (?camera:String = 'game') -> return LuaUtils.getMousePoint(camera, 'y'));
		set("getMidpointX", (variable:String) -> return LuaUtils.getPoint(variable, 'midpoint', 'x'));
		set("getMidpointY", (variable:String) -> return LuaUtils.getPoint(variable, 'midpoint', 'y'));
		set("getGraphicMidpointX", (variable:String) -> return LuaUtils.getPoint(variable, 'graphic', 'x'));
		set("getGraphicMidpointY", (variable:String) -> return LuaUtils.getPoint(variable, 'graphic', 'y'));
		set("getScreenPositionX", (variable:String, ?camera:String = 'game') -> return LuaUtils.getPoint(variable, 'screen', 'x', camera));
		set("getScreenPositionY", (variable:String, ?camera:String = 'game') -> return LuaUtils.getPoint(variable, 'screen', 'y', camera));

		set("characterDance", function(character:String, force:Bool = false) {
			switch (character.toLowerCase()) {
				case 'dad' | 'opponent': game.dad.dance(force);
				case 'gf' | 'girlfriend': if (game.gf != null) game.gf.dance(force);
				default: game.boyfriend.dance(force);
			}
		});

		set("makeLuaSprite", function(tag:String, image:String = null, x:Float = 0, y:Float = 0) {
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);

			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if (image != null && image.length > 0) leSprite.loadGraphic(Paths.image(image));
			leSprite.antialiasing = ClientPrefs.data.antialiasing;
			MusicBeatState.getVariables().set(tag, leSprite);
		});
		set("makeAnimatedLuaSprite", function(tag:String, image:String = null, x:Float = 0, y:Float = 0, ?spriteType:String = "auto") {
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);

			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			leSprite.antialiasing = ClientPrefs.data.antialiasing;
			if (image != null && image.length > 0) LuaUtils.loadFrames(leSprite, image, spriteType);
			MusicBeatState.getVariables().set(tag, leSprite);
		});

		set("makeParallaxSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0) {
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);
			var leSprite:ParallaxSprite = new ParallaxSprite(x, y, Paths.image(image));
			MusicBeatState.getVariables().set(tag, leSprite);
			leSprite.active = true;
		});
		set("fixateParallaxSprite", function(obj:String, anchorX:Int = 0, anchorY:Int = 0, scrollOneX:Float = 1, scrollOneY:Float = 1, scrollTwoX:Float = 1.1, scrollTwoY:Float = 1.1, direct:String = 'horizontal') {
			var spr:ParallaxSprite = LuaUtils.getObjectDirectly(obj, false);
			if (spr != null) spr.fixate(anchorX, anchorY, scrollOneX, scrollOneY, scrollTwoX, scrollTwoY, direct);
		});

		set("makeGraphic", function(obj:String, width:Int = 256, height:Int = 256, color:String = 'FFFFFF') {
			var spr:FlxSprite = LuaUtils.getObjectLoop(obj);
			if (spr != null) spr.makeGraphic(width, height, CoolUtil.colorFromString(color));
		});
		set("makeSolid", function(obj:String, width:Int = 256, height:Int = 256, color:String = 'FFFFFF') {
			var spr:FlxSprite = LuaUtils.getObjectLoop(obj);
			if (spr != null) spr.makeSolid(width, height, CoolUtil.colorFromString(color));
		});
		set("addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Float = 24, loop:Bool = true) {
			var obj:FlxSprite = cast LuaUtils.getObjectDirectly(obj, false);
			if (obj != null && obj.animation != null) {
				obj.animation.addByPrefix(name, prefix, framerate, loop);
				if (obj.animation.curAnim == null) {
					var dyn:Dynamic = cast obj;
					if (dyn.playAnim != null) dyn.playAnim(name, true);
					else dyn.animation.play(name, true);
				}
				return true;
			}
			return false;
		});

		set("addAnimation", (obj:String, name:String, frames:Any, framerate:Float = 24, loop:Bool = true) -> return LuaUtils.addAnimByIndices(obj, name, null, frames, framerate, loop));
		set("addAnimationByIndices", (obj:String, name:String, prefix:String, indices:Any, framerate:Float = 24, loop:Bool = false) -> return LuaUtils.addAnimByIndices(obj, name, prefix, indices, framerate, loop));

		set("playAnim", function(obj:String, name:String, ?forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0) {
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if (obj.playAnim != null) {
				obj.playAnim(name, forced, reverse, startFrame);
				return true;
			} else {
				if (obj.anim != null) obj.anim.play(name, forced, reverse, startFrame); //FlxAnimate
				else obj.animation.play(name, forced, reverse, startFrame);
				return true;
			}
			return false;
		});

		set("addOffset", function(obj:String, anim:String, x:Float, y:Float) {
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if (obj != null && obj.addOffset != null) {
				obj.addOffset(anim, x, y);
				return true;
			}
			return false;
		});

		set("setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float) {
			var object:FlxObject = LuaUtils.getObjectLoop(obj);
			if (object != null) object.scrollFactor.set(scrollX, scrollY);
		});

		set("addLuaSprite", function(tag:String, ?inFront:Bool = false) {
			var mySprite:FlxSprite = MusicBeatState.getVariables().get(tag);
			if (mySprite == null) return;

			var instance:FlxState = LuaUtils.getTargetInstance();
			if (inFront) instance.add(mySprite);
			else {
				if (PlayState.instance == null || !PlayState.instance.isDead)
					instance.insert(instance.members.indexOf(LuaUtils.getLowestCharacterGroup()), mySprite);
				else GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), mySprite);
			}
		});
		set("addParallaxSprite", function(tag:String, front:Bool = false) {
			var spr:ParallaxSprite = MusicBeatState.getVariables().get(tag);
			var instance:FlxState = LuaUtils.getTargetInstance();
			if (front) instance.add(spr);
			else {
				if (PlayState.instance == null || !PlayState.instance.isDead)
					instance.insert(instance.members.indexOf(LuaUtils.getLowestCharacterGroup()), spr);
				else GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), spr);
			}
		});
		set("setGraphicSize", function(obj:String, x:Float, y:Float = 0, updateHitbox:Bool = true) {
			var poop:FlxSprite = LuaUtils.getObjectLoop(obj);
			if (poop != null) {
				poop.setGraphicSize(x, y);
				if (updateHitbox) poop.updateHitbox();
				return;
			}
			luaTrace('setGraphicSize: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		set("scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true) {
			var poop:FlxSprite = LuaUtils.getObjectLoop(obj);
			if (poop != null) {
				poop.scale.set(x, y);
				if (updateHitbox) poop.updateHitbox();
				return;
			}
			luaTrace('scaleObject: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		set("updateHitbox", function(obj:String) {
			var poop:FlxSprite = LuaUtils.getObjectLoop(obj);
			if (poop != null) {
				poop.updateHitbox();
				return;
			}
			luaTrace('updateHitbox: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});

		set("centerOffsets", function(obj:String) {
			if (game.getLuaObject(obj) != null) {
				game.getLuaObject(obj).centerOffsets();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if (poop != null) {
				poop.centerOffsets();
				return;
			}
			luaTrace('centerOffsets: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});

		set("removeLuaSprite", function(tag:String, destroy:Bool = true, ?group:String = null) {
			var obj:FlxSprite = LuaUtils.getObjectDirectly(tag);
			if (obj == null || obj.destroy == null) return false;

			var groupObj:Dynamic = null;
			if (group == null) groupObj = LuaUtils.getTargetInstance();
			else groupObj = LuaUtils.getObjectDirectly(group);

			groupObj.remove(obj, true);
			if (destroy) {
				MusicBeatState.getVariables().remove(tag);
				obj.destroy();
			}
			return true;
		});

		set("stampSprite", function(sprite:String, brush:String, x:Int, y:Int) {
			var variables:Map<String, Dynamic> = MusicBeatState.getVariables();
			if (!variables.exists(sprite) || !variables.exists(brush)) return false;
			variables.get(sprite).stamp(variables.get(brush), x, y);
			return true;
		});

		set("luaSpriteExists", function(tag:String) {
			var obj:FlxSprite = MusicBeatState.getVariables().get(tag);
			return (obj != null && (Std.isOfType(obj, ModchartSprite) || Std.isOfType(obj, ModchartAnimateSprite)));
		});
		set("luaTextExists", function(tag:String) {
			var obj:FlxText = MusicBeatState.getVariables().get(tag);
			return (obj != null && Std.isOfType(obj, FlxText));
		});
		set("luaSoundExists", function(tag:String) {
			tag = LuaUtils.formatVariable('sound_$tag');
			var obj:FlxSound = MusicBeatState.getVariables().get(tag);
			return (obj != null && Std.isOfType(obj, FlxSound));
		});

		set("setHealthBarColors", (left:String, right:String) -> LuaUtils.setBarColors(game.healthBar, left, right));
		set("setTimeBarColors", (left:String, right:String) -> LuaUtils.setBarColors(game.timeBar, left, right));

		set("setPosition", (obj:String, ?x:Float = null, ?y:Float = null) -> {
			var object:FlxSprite = LuaUtils.getObjectLoop(obj);
			if (object != null) {
				if (x != null) object.x = x;
				if (y != null) object.y = y;
				return true;
			}
			luaTrace("setPosition: Couldnt find object " + obj, false, false, FlxColor.RED);
			return false;
		});
		set("setObjectCamera", function(obj:String, camera:String = 'game') {
			var object:FlxBasic = LuaUtils.getObjectLoop(obj);
			if (object != null) {
				object.camera = LuaUtils.cameraFromString(camera);
				return true;
			} 
			luaTrace('setObjectCamera: Object $obj doesn\'t exist!', false, false, FlxColor.RED);
			return false;
		});
		set("setBlendMode", function(obj:String, blend:String = '') {
			var spr:FlxSprite = LuaUtils.getObjectLoop(obj);
			if (spr != null) {
				spr.blend = LuaUtils.blendModeFromString(blend);
				return;
			}
			luaTrace("setBlendMode: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});
		set("screenCenter", function(obj:String, pos:String = 'xy') {
			var spr:FlxObject = LuaUtils.getObjectLoop(obj);
			if (spr != null) {
				spr.gameCenter(LuaUtils.axesFromString(pos));
				return;
			}
			luaTrace("screenCenter: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});
		set("objectsOverlap", function(obj1:String, obj2:String) {
			var namesArray:Array<String> = [obj1, obj2];
			var objectsArray:Array<FlxSprite> = [];
			for (i in 0...namesArray.length) {
				var real:FlxSprite = game.getLuaObject(namesArray[i]);
				if (real != null) objectsArray.push(real);
				else objectsArray.push(Reflect.getProperty(LuaUtils.getTargetInstance(), namesArray[i]));
			}

			return (!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]));
		});
		set("getPixelColor", function(obj:String, x:Int, y:Int) {
			var spr:FlxSprite = LuaUtils.getObjectLoop(obj);
			if (spr != null) return spr.pixels.getPixel32(x, y);
			return FlxColor.BLACK;
		});

		set("startDialogue", function(dialogueFile:String, ?music:String = null) {
			var path:String;
			var songPath:String = Paths.formatToSongPath(Song.loadedSongName);
			#if TRANSLATIONS_ALLOWED
			path = Paths.getPath('data/${Paths.CHART_PATH}/$songPath/${dialogueFile}_${ClientPrefs.data.language}.json');
			if (!#if MODS_ALLOWED FileSystem.exists(path) #else Assets.exists(path, TEXT) #end)
			#end
				path = Paths.getPath('data/${Paths.CHART_PATH}/$songPath/$dialogueFile.json');

			luaTrace('startDialogue: Trying to load dialogue: $path');
			
			if (#if MODS_ALLOWED FileSystem.exists(path) #else Assets.exists(path, TEXT) #end) {
				var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
				if (shit.dialogue.length > 0) {
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
		set("startVideo", (videoFile:String, ?canSkip:Bool = true, ?forMidSong:Bool = false, ?shouldLoop:Bool = false, ?playOnLoad:Bool = true) -> {
			#if VIDEOS_ALLOWED
			if (FileSystem.exists(Paths.video(videoFile))) {
				if (game.videoCutscene != null) {
					game.remove(game.videoCutscene);
					game.videoCutscene.destroy();
				}
				game.videoCutscene = game.startVideo(videoFile, forMidSong, canSkip, shouldLoop, true, playOnLoad);
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
			#if MODS_ALLOWED
			if (modName == null) {
				if (this.modFolder == null) {
					luaTrace('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', false, false, FlxColor.RED);
					return null;
				}
				modName = this.modFolder;
			}
			return LuaUtils.getModSetting(saveTag, modName);
			#else
			luaTrace("getModSetting: Mods are disabled in this build!", false, false, FlxColor.RED);
			#end
		});
		set("close", () -> {
			trace('Closing script: $scriptName');
			return closed = true;
		});

		#if DISCORD_ALLOWED DiscordClient.addLuaCallbacks(this); #end
		#if ACHIEVEMENTS_ALLOWED Achievements.addLuaCallbacks(this); #end
		#if TRANSLATIONS_ALLOWED Language.addLuaCallbacks(this); #end
		#if VIDEOS_ALLOWED VideoFunctions.implement(this); #end
		HScript.implement(this);
		#if flxanimate FlxAnimateFunctions.implement(this); #end
		ReflectionFunctions.implement(this);
		TextFunctions.implement(this);
		ExtraFunctions.implement(this);
		CustomSubstate.implement(this);
		ShaderFunctions.implement(this);
		DeprecatedFunctions.implement(this);
		SoundFunctions.implement(this);

		for (name => func in customFunctions) if (func != null) set(name, func);

		try {
			final isString:Bool = !FileSystem.exists(scriptName);
			final result:Dynamic = (!isString ? LuaL.dofile(lua, scriptName) : LuaL.dostring(lua, scriptName));

			final resultStr:String = Lua.tostring(lua, result);
			if (resultStr != null && result != 0) {
				luaTrace('ERROR ON LOADING ($scriptName): $resultStr', true, false, 0xffb30000);
				lua = null;
				return;
			}
			if (isString) scriptName = 'unknown';
		} catch (e:Dynamic) {
			Logs.trace(e, ERROR);
			return;
		}
		trace('lua file loaded succesfully: $scriptName');
		call('onCreate');
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
		if (ignoreCheck || getBool('luaDebugMode')) {
			if (deprecated && !getBool('luaDeprecatedWarnings')) return;
			PlayState.instance.addTextToDebug(text, color);
		}
		#end
	}

	#if LUA_ALLOWED
	public static function getBool(variable:String):Bool {
		if (lastCalledScript == null) return false;

		var lua:State = lastCalledScript.lua;
		if (lua == null) return false;

		Lua.getglobal(lua, variable);
		final result:String = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if (result == null) return false;
		return (result == 'true');
	}
	#end

	function findScript(scriptFile:String, ext:String = '.lua'):String {
		if (!scriptFile.endsWith(ext)) scriptFile += ext;
		var path:String = Paths.getPath(scriptFile);
		
		if (#if MODS_ALLOWED FileSystem.exists(path) #else Assets.exists(path, TEXT) #end) return path;
		if (#if MODS_ALLOWED FileSystem.exists(scriptFile) #else Assets.exists(scriptFile, TEXT) #end) return scriptFile;
		return null;
	}

	function getErrorMessage(status:Int = 0):String {
		#if LUA_ALLOWED
		var v:String = Lua.tostring(lua, -1);
		Lua.pop(lua, 1);

		if (v != null) v = v.trim();
		if (v == null || v == "") {
			return switch (status) {
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
			if (lua == null) return LuaUtils.Function_Continue;

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
				else luaTrace('WARNING ($func): attempt to insert ${Type.typeof(arg)} (unsupported value type) as a argument', false, false, FlxColor.ORANGE);
			}
			var status:Int = Lua.pcall(lua, nargs, 1, 0);

			if (status != Lua.LUA_OK) {
				luaTrace('ERROR ($func): ${getErrorMessage(status)}', false, false, FlxColor.RED);
				return LuaUtils.Function_Continue;
			}

			var result:Dynamic = cast Convert.fromLua(lua, -1);
			if (result == null) result = LuaUtils.Function_Continue;

			Lua.pop(lua, 1);
			if (closed) stop();
			return result;
		} catch (e:Dynamic) Logs.trace(e, ERROR);
		#end
		return LuaUtils.Function_Continue;
	}

	public function set(variable:String, data:Any) {
		#if LUA_ALLOWED
		if (lua == null) return;

		if (Reflect.isFunction(data)) {
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
		if (hscript != null) {
			hscript.destroy();
			hscript = null;
		}
		#end
	}

	public function oldTweenFunction(tag:String, vars:String, tweenValue:Any, duration:Float, ease:String, funcName:String):String {
		var target:Dynamic = LuaUtils.tweenPrepare(tag, vars);
		var variables:Map<String, Dynamic> = MusicBeatState.getVariables();
		if (target != null) {
			if (tag != null) {
				var originalTag:String = tag;
				tag = LuaUtils.formatVariable('tween_$tag');
				variables.set(tag, FlxTween.tween(target, tweenValue, duration, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: (twn:FlxTween) -> {
						variables.remove(tag);
						if (PlayState.instance != null) PlayState.instance.callOnLuas('onTweenCompleted', [originalTag, vars]);
					}
				}));
				return tag;
			} else FlxTween.tween(target, tweenValue, duration, {ease: LuaUtils.getTweenEaseByString(ease)});
		} else luaTrace('$funcName: Couldnt find object: $vars', false, false, FlxColor.RED);
		return null;
	}

	public function noteTweenFunction(tag:String, note:Int, data:Dynamic, duration:Float, ease:String):String {
		if (PlayState.instance == null) return null;

		var strumNote:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];
		if (strumNote == null) return null;

		if (tag != null) {
			var originalTag:String = tag;
			tag = LuaUtils.formatVariable('tween_$tag');
			LuaUtils.cancelTween(tag);

			var variables:Map<String, Dynamic> = MusicBeatState.getVariables();
			variables.set(tag, FlxTween.tween(strumNote, data, duration, {ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: (twn:FlxTween) -> {
					variables.remove(tag);
					if (PlayState.instance != null) PlayState.instance.callOnLuas('onTweenCompleted', [originalTag]);
				}
			}));
			return tag;
		} else FlxTween.tween(strumNote, data, duration, {ease: LuaUtils.getTweenEaseByString(ease)});
		return null;
	}

	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function initLuaShader(name:String):Bool {
		if (!ClientPrefs.data.shaders) return false;

		#if (MODS_ALLOWED && !flash && sys)
		if (runtimeShaders.exists(name)) {
			var shaderData:Array<String> = runtimeShaders.get(name);
			if (shaderData != null && (shaderData[0] != null || shaderData[1] != null)) {
				luaTrace('Shader $name was already initialized!');
				return true;
			}
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));

		for (mod in Mods.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods('$mod/shaders/'));
		
		for (folder in foldersToCheck) {
			if (FileSystem.exists(folder)) {
				var frag:String = '$folder$name.frag';
				var vert:String = '$folder$name.vert';
				var found:Bool = false;
				if (FileSystem.exists(frag)) {
					frag = File.getContent(frag);
					found = true;
				} else frag = null;

				if (FileSystem.exists(vert)) {
					vert = File.getContent(vert);
					found = true;
				} else vert = null;

				if (found) {
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