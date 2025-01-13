package psychlua;

import flixel.FlxBasic;
import lime.app.Application;
#if HSCRIPT_ALLOWED
import alterhscript.AlterHscript;
import haxe.PosInfos;
class HScript extends AlterHscript {
	public var filePath:String;
	public var modFolder:String;
	public var executed:Bool = false;

	#if LUA_ALLOWED
	public var parentLua:FunkinLua;
	public static function initHaxeModule(parent:FunkinLua) {
		if(parent.hscript == null) {
			trace('initializing haxe interp for: ${parent.scriptName}');
			parent.hscript = new HScript(parent);
		}
	}

	public static function initHaxeModuleCode(parent:FunkinLua, code:String, ?varsToBring:Any = null) {
		var hs:HScript = try parent.hscript catch (e) null;
		if(hs == null) {
			trace('initializing haxe interp for: ${parent.scriptName}');
			parent.hscript = new HScript(parent, code, varsToBring);
		} else {
			try {
				hs.scriptCode = code;
				hs.varsToBring = varsToBring;
				hs.parse(true);
				hs.execute();
			} catch(e:Dynamic) FunkinLua.luaTrace('ERROR (${hs.origin}) - $e', false, false, FlxColor.RED);
		}
	}
	#end

	public var origin:String;
	public override function new(?parent:Dynamic, file:String = '', ?varsToBring:Any = null, ?manualRun:Bool = false) {
		filePath = file;
		if (filePath != null && filePath.length > 0 && parent == null) {
			this.origin = filePath;
			#if MODS_ALLOWED
			var myFolder:Array<String> = filePath.split('/');
			if ('${myFolder[0]}/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) //is inside mods folder
				this.modFolder = myFolder[1];
			#end
		}
		var scriptThing:String = file;
		var scriptName:String = null;
		if (parent == null && file != null) {
			var f:String = file.replace('\\', '/');
			if (f.contains('/') && !f.contains('\n')) {
				scriptThing = File.getContent(f);
				scriptName = f;
			}
		}
		#if LUA_ALLOWED
		if (scriptName == null && parent != null) scriptName = parent.scriptName;
		#end
		this.varsToBring = varsToBring;
		super(scriptThing, new alterhscript.AlterConfig(scriptName, false, false));
		#if LUA_ALLOWED
		parentLua = parent;
		if (parent != null) {
			this.origin = parent.scriptName;
			this.modFolder = parent.modFolder;
		}
		#end
		if (!manualRun && !tryRunning()) return;

		AlterHscript.warn = (x:String, ?pos:PosInfos) -> {
			if (PlayState.instance != null) PlayState.instance.addTextToDebug('[$origin]: $x', FlxColor.YELLOW);
			AlterHscript.logLevel(WARN, x, pos);
		}
		AlterHscript.error = (x:String, ?pos:PosInfos) -> {
			if (PlayState.instance != null) PlayState.instance.addTextToDebug('[$origin]: $x', FlxColor.ORANGE);
			AlterHscript.logLevel(ERROR, x, pos);
		}
		AlterHscript.fatal = (x:String, ?pos:PosInfos) -> {
			if (PlayState.instance != null) PlayState.instance.addTextToDebug('[$origin]: $x', FlxColor.RED);
			AlterHscript.logLevel(FATAL, x, pos);
		}
	}

	function tryRunning():Bool {
		try {
			preset();
			execute();
			return true;
		} catch(e:haxe.Exception) {
			this.destroy();
			throw e;
			return false;
		}
		return false;
	}

	var varsToBring(default, set):Any = null;
    function getDefaultVariables():Map<String, Dynamic> {
        return [
			"Type"				=> Type,
			"Sys"				=> Sys,
			"Date"				=> Date,
			"DateTools"			=> DateTools,
			"Reflect"			=> Reflect,
			"HScript"			=> HScript,
            "Xml"               => Xml,
			"EReg"				=> EReg,
			"Lambda"			=> Lambda,

			#if flxanimate
			"FlxAnimate"		=> FlxAnimate,
			#end

			// Sys related stuff
			#if sys
			"File"				=> File,
			"FileSystem"		=> FileSystem,
			#end
			"Assets"			=> openfl.Assets,

            // OpenFL & Lime related stuff
            "Application"       => Application,
            "window"            => Application.current.window,

            // Flixel related stuff
            "FlxG"              => FlxG,
            "FlxSprite"         => FlxSprite,
            "FlxBasic"          => FlxBasic,
            "FlxCamera"         => FlxCamera,
			"PsychCamera"		=> backend.PsychCamera,
            "FlxTween"          => FlxTween,
            "FlxEase"           => FlxEase,
            "FlxPoint"          => getClassHSC('flixel.math.FlxPoint'),
            "FlxAxes"           => getClassHSC('flixel.util.FlxAxes'),
            "FlxColor"          => getClassHSC('flixel.util.FlxColor'),
            "FlxKey"            => getClassHSC('flixel.input.keyboard.FlxKey'),
            "FlxSound"          => FlxSound,
            "FlxAssets"         => flixel.system.FlxAssets,
            "FlxMath"           => FlxMath,
            "FlxGroup"          => flixel.group.FlxGroup,
            "FlxTypedGroup"     => FlxTypedGroup,
            "FlxSpriteGroup"    => FlxSpriteGroup,
            "FlxTypeText"       => flixel.addons.text.FlxTypeText,
            "FlxText"           => FlxText,
            "FlxTimer"          => FlxTimer,

            // Engine related stuff
			"Countdown"			=> backend.BaseStage.Countdown,
            "PlayState"         => PlayState,
            "Note"              => objects.Note,
			"CustomSubstate"	=> CustomSubstate,
            "NoteSplash"        => objects.NoteSplash,
            "HealthIcon"        => objects.HealthIcon,
            "StrumLine"         => objects.StrumNote,
            "Character"         => objects.Character,
            "Paths"             => Paths,
            "Conductor"         => Conductor,
            "Alphabet"          => Alphabet,
			"DeltaTrail" 		=> objects.DeltaTrail,
			#if ACHIEVEMENTS_ALLOWED
			'Achievements' 		=> Achievements,
			#end

            "CoolUtil"          => CoolUtil,
            "ClientPrefs"       => ClientPrefs,

			#if (!flash && sys)
			"FlxRuntimeShader"  => flixel.addons.display.FlxRuntimeShader,
			#end
			'ShaderFilter'		=> openfl.filters.ShaderFilter,

			"version" 			=> Main.engineVer.version.trim(),
            "engine" => {
				app_version: Application.current.meta.get('version'),
                commit: macros.GitCommitMacro.commitNumber,
                hash: macros.GitCommitMacro.commitHash.trim(),
                name: "Alter Engine"
            }
        ];
    }

	override function preset() {
		super.preset();
		parser.preprocessorValues = getDefaultPreprocessors();
        for (key => type in getDefaultVariables()) set(key, type);

		// Functions & Variables
		set('setVar', (name:String, value:Dynamic) -> {
			MusicBeatState.getVariables().set(name, value);
			return value;
		});
		set('getVar', (name:String) -> {
			if (MusicBeatState.getVariables().exists(name)) return MusicBeatState.getVariables().get(name);
			return null;
		});
		set('removeVar', (name:String) -> {
			if (MusicBeatState.getVariables().exists(name)) {
				MusicBeatState.getVariables().remove(name);
				return true;
			}
			return false;
		});
		set('debugPrint', (text:String, ?color:FlxColor = FlxColor.WHITE) -> PlayState.instance.addTextToDebug(text, color));

		set('getModSetting', function(saveTag:String, ?modName:String = null) {
			if (modName == null) {
				if (this.modFolder == null) {
					PlayState.instance.addTextToDebug('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', FlxColor.RED);
					return null;
				}
				modName = this.modFolder;
			}
			return LuaUtils.getModSetting(saveTag, modName);
		});

		// Keyboard & Gamepads
		set('keyboardJustPressed', (name:String) -> return Reflect.getProperty(FlxG.keys.justPressed, name));
		set('keyboardPressed', (name:String) -> return Reflect.getProperty(FlxG.keys.pressed, name));
		set('keyboardReleased', (name:String) -> return Reflect.getProperty(FlxG.keys.justReleased, name));

		set('keyJustPressed', function(name:String = '') {
			name = name.toLowerCase();
			return switch(name) {
				case 'left': Controls.justPressed('note_left');
				case 'down': Controls.justPressed('note_down');
				case 'up': Controls.justPressed('note_up');
				case 'right': Controls.justPressed('note_right');
				default: Controls.justPressed(name);
			}
		});
		set('keyPressed', function(name:String = '') {
			name = name.toLowerCase();
			return switch(name) {
				case 'left': Controls.pressed('note_left');
				case 'down': Controls.pressed('note_down');
				case 'up': Controls.pressed('note_up');
				case 'right': Controls.pressed('note_right');
				default: Controls.pressed(name);
			}
		});
		set('keyReleased', function(name:String = '') {
			name = name.toLowerCase();
			return switch(name) {
				case 'left': Controls.released('note_left');
				case 'down': Controls.released('note_down');
				case 'up': Controls.released('note_up');
				case 'right': Controls.released('note_right');
				default: Controls.released(name);
			}
		});

		// For adding your own callbacks
		#if LUA_ALLOWED
		set('createGlobalCallback', function(name:String, func:haxe.Constraints.Function) {
			for (script in PlayState.instance.luaArray)
				if (script != null && script.lua != null && !script.closed)
					script.set(name, func);
			FunkinLua.customFunctions.set(name, func);
		});

		set('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null) {
			if (funk == null) funk = parentLua;
			if (funk != null) funk.addLocalCallback(name, func);
			else FunkinLua.luaTrace('createCallback ($name): 3rd argument is null', false, false, FlxColor.RED);
		});
		#end

		set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
			try {
				var str:String = '';
				if (libPackage.length > 0) str = '$libPackage.';
				set(libName, Type.resolveClass(str + libName));
			} catch (e:Dynamic) {
				var msg:String = e.message.substr(0, e.message.indexOf('\n'));
				#if LUA_ALLOWED
				if (parentLua != null) {
					FunkinLua.lastCalledScript = parentLua;
					FunkinLua.luaTrace('$origin: ${parentLua.lastCalledFunction} - $msg', false, false, FlxColor.RED);
					return;
				}
				#end
				if (PlayState.instance != null) PlayState.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
				else Logs.trace('$origin - $msg', ERROR);
			}
		});
		set('parentLua', #if LUA_ALLOWED parentLua #else null #end);
		set("openState", (name:String) -> {
			FlxG.sound.music?.stop();
			var hxFile:String = Paths.getPath('scripts/states/$name.hx');
            if (FileSystem.exists(hxFile)) FlxG.switchState(() -> new states.HscriptState(hxFile));
            else {
                try {
                    final rawClass:Class<Dynamic> = Type.resolveClass(name);
                    if (rawClass == null) return; 
                    FlxG.switchState(cast(Type.createInstance(rawClass, []), flixel.FlxState));
                } catch(e:Dynamic) {
                    Logs.trace('$e: Unspecified result for switching state "$name", could not switch states!', ERROR);
                    return;
                }
            }
        });
        set("openSubState", (name:String, args:Array<Dynamic>) -> {
			var hxFile:String = Paths.getPath('scripts/substates/$name.hx');
            if (FileSystem.exists(hxFile)) FlxG.state.openSubState(new substates.HscriptSubstate(hxFile, args));
            else {
                try {
                    final rawClass:Class<Dynamic> = Type.resolveClass(name);
					if (rawClass == null) return;
                    FlxG.state.openSubState(cast(Type.createInstance(rawClass, args), FlxSubState));
                } catch(e:Dynamic) {
                    Logs.trace('$e: Unspecified result for opening substate "$name", could not be opened!', ERROR);
                    return;
                }
            }
        });

		set('close', destroy);
		set('this', this);
		set('game', FlxG.state);
		set('controls', Controls);

		set('buildTarget', LuaUtils.getTargetOS());
		set('customSubstate', CustomSubstate.instance);
		set('customSubstateName', CustomSubstate.name);

		set('Function_Stop', LuaUtils.Function_Stop);
		set('Function_Continue', LuaUtils.Function_Continue);
		set('Function_StopLua', LuaUtils.Function_StopLua); //doesnt do much cuz HScript has a lower priority than Lua
		set('Function_StopHScript', LuaUtils.Function_StopHScript);
		set('Function_StopAll', LuaUtils.Function_StopAll);

		setParent(FlxG.state);
		if (PlayState.instance == FlxG.state) {
			var psInstance:PlayState = PlayState.instance;
			set('addBehindGF', (obj:FlxBasic, ?order:Int = 0) -> psInstance.insert(psInstance.members.indexOf(psInstance.gfGroup) - order, obj));
			set('addBehindDad', (obj:FlxBasic, ?order:Int = 0) -> psInstance.insert(psInstance.members.indexOf(psInstance.dadGroup) - order, obj));
			set('addBehindBF', (obj:FlxBasic, ?order:Int = 0) -> psInstance.insert(psInstance.members.indexOf(psInstance.boyfriendGroup) - order, obj));
		}
	}

	function getDefaultPreprocessors():Map<String, Dynamic> {
		var defines:Map<String, Dynamic> = macros.DefinesMacro.defines;
		defines.set("ALTER_ENGINE", true);
		defines.set("ALTER_VER", Main.engineVer.version.trim());
		defines.set("ALTER_APP_VER", Application.current.meta.get('version'));
		defines.set("ALTER_COMMIT", macros.GitCommitMacro.commitNumber);
		defines.set("ALTER_HASH", macros.GitCommitMacro.commitHash);
		return defines;
	}

	function resolveClassOrEnum(name:String):Dynamic {
		var c:Dynamic = Type.resolveClass(name);
		if (c == null) c = Type.resolveEnum(name);
		return c;
	}

	public override function execute():Dynamic {
		#if LUA_ALLOWED
		var prevLua:FunkinLua = FunkinLua.lastCalledScript;
		FunkinLua.lastCalledScript = parentLua;
		#end
		var result:Dynamic = super.execute();
		executed = true;
		#if LUA_ALLOWED FunkinLua.lastCalledScript = prevLua; #end
		return result;
	}
	public override function parse(force:Bool = false) {
		executed = false;
		return super.parse(force);
	}
	#if LUA_ALLOWED
	public override function call(fun:String, ?args:Array<Dynamic>):AlterCall {
		var prevLua:FunkinLua = FunkinLua.lastCalledScript;
		FunkinLua.lastCalledScript = parentLua;
		final call:AlterCall = super.call(fun, args);
		FunkinLua.lastCalledScript = prevLua;
		return call;
	}
	#end

	public function executeCode(?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):AlterCall {
		if (funcToRun == null) return null;

		if(!exists(funcToRun)) {
			#if LUA_ALLOWED
			FunkinLua.luaTrace(origin + ' - No function named: $funcToRun', false, false, FlxColor.RED);
			#else
			PlayState.instance.addTextToDebug(origin + ' - No function named: $funcToRun', FlxColor.RED);
			#end
			return null;
		}

		try {
			return (call(funcToRun, funcArgs):AlterCall).returnValue;
		} catch(e:Dynamic) Logs.trace('ERROR $funcToRun: $e', ERROR);
		return null;
	}

	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua) {
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
			try {
				initHaxeModuleCode(funk, codeToRun, varsToBring);
				final result:AlterCall = funk.hscript.executeCode(funcToRun, funcArgs);
				if (LuaUtils.typeSupported(result)) return result;
			} catch (e:Dynamic) FunkinLua.luaTrace('ERROR (${funk.hscript.origin}: $funcToRun) - $e', false, false, FlxColor.RED);
			return null;
		});

		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			if (funk.hscript != null) {
				var result:Dynamic = funk.hscript.executeCode(funcToRun, funcArgs);
				if (LuaUtils.typeSupported(result)) return result;
			}
			return null;
		});
		// This function is unnecessary because import already exists in HScript as a native feature
		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			if (funk.hscript == null) funk.initHaxeModule();

			libName = libName ?? '';
			var str:String = libPackage.length > 0 ? '$libPackage.$libName' : libName;
			var cls:Dynamic = funk.hscript.resolveClassOrEnum(str);
			if (cls == null) {
				FunkinLua.luaTrace('addHaxeLibrary: Class "$str" wasn\'t found!', false, false, FlxColor.RED);
				return false;
			} else {
				funk.hscript.set(libName, cls);
				return true;
			}
		});
	}
	#end

	inline function getClassHSC(className:String):Class<Dynamic> {
		return Type.resolveClass('${className}_HSC');
	}

	public override function destroy() {
		origin = null;
		#if LUA_ALLOWED parentLua = null; #end
		super.destroy();
	}

	function set_varsToBring(values:Any):Any {
		if (varsToBring != null)
			for (key in Reflect.fields(varsToBring))
				if (exists(key.trim()))
					interp.variables.remove(key.trim());
		if (values != null) {
			for (key in Reflect.fields(values)) {
				key = key.trim();
				set(key, Reflect.field(values, key));
			}
		}
		return varsToBring = values;
	}
}

#elseif LUA_ALLOWED
class HScript {
	public static function implement(funk:FunkinLua) {
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
			FunkinLua.luaTrace("runHaxeCode: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			return null;
		});
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			FunkinLua.luaTrace("runHaxeFunction: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			return null;
		});
		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			FunkinLua.luaTrace("addHaxeLibrary: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			return false;
		});
	}
}
#end