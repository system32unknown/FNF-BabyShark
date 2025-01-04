package psychlua;

import flixel.FlxBasic;
import lime.app.Application;
#if HSCRIPT_ALLOWED
import alterhscript.AlterHscript;
import alterhscript.ErrorSeverity;
import hscript.Expr.Error as ImprError;

class HScript extends AlterHscript {
	public var filePath:String;
	public var modFolder:String;
	public var executed:Bool = false;

	#if LUA_ALLOWED
	public var parentLua:FunkinLua;
	#end

	public function errorCaught(e:ImprError, ?funcName:String) {
		var message:String = errorToString(e, funcName, this);
		var color:FlxColor = (executed ? FlxColor.RED : 0xffb30000);
		#if LUA_ALLOWED
		if (parentLua == null) PlayState.instance.addTextToDebug(message, color);
		else FunkinLua.luaTrace(message, false, false, color);
		#else
		PlayState.instance.addTextToDebug(message, color);
		#end
	}
	public static function hscriptLog(severity:ErrorSeverity, x:Dynamic, ?pos:haxe.PosInfos) {
		var message:String = Std.string(x);
		var origin:String = pos?.fileName ?? 'hscript';
		#if hscriptPos
		if (pos.lineNumber != -1) origin += ':' + pos.lineNumber;
		#end
		var fullTrace:String = '($origin) - $message';
		var color:FlxColor;
		switch (severity) {
			case FATAL:
				color = 0xffb30000;
				fullTrace = 'FATAL ' + fullTrace;
			case ERROR:
				color = FlxColor.RED;
				fullTrace = 'ERROR ' + fullTrace;
			case WARN:
				color = FlxColor.YELLOW;
				fullTrace = 'WARNING ' + fullTrace;
			default: color = FlxColor.CYAN;
		}
		#if LUA_ALLOWED
		if (FunkinLua.lastCalledScript == null || severity == FATAL)
			PlayState.instance.addTextToDebug(fullTrace, color);
		else FunkinLua.luaTrace(fullTrace, false, false, color);
		#else
		PlayState.instance.addTextToDebug(fullTrace, color);
		#end
	}
	public static function errorToString(e:ImprError, ?funcName:String, ?instance:HScript):String {
		var message:String = switch (#if hscriptPos e.e #else e #end) {
			case EInvalidChar(c): "Invalid character: '" + (StringTools.isEof(c) ? "EOF" : String.fromCharCode(c)) + "' (" + c + ")";
			case EUnexpected(s): "Unexpected token: \"" + s + "\"";
			case EUnterminatedString: "Unterminated string";
			case EUnterminatedComment: "Unterminated comment";
			case EEmptyExpression: "Expression cannot be empty";
			case EInvalidPreprocessor(str): "Invalid preprocessor (" + str + ")";
			case EUnknownVariable(v): "Unknown variable: " + v;
			case EInvalidIterator(v): "Invalid iterator: " + v;
			case EInvalidOp(op): "Invalid operator: " + op;
			case EInvalidAccess(f): "Invalid access to field " + f;
			case EInvalidClass(cla): "Invalid class: " + cla + " was not found.";
			case EAlreadyExistingClass(cla): 'Custom Class named $cla already exists.';
			case ECustom(msg): msg;
			default: "Unknown Error";
		};
		var errorHeader:String = 'ERROR';
		if (instance != null && !instance.executed) errorHeader = 'ERROR ON LOADING';

		var scriptHeader:String = (instance != null ? instance.origin : 'HScript');
		if (funcName != null) scriptHeader += ':$funcName';

		var lineHeader:String = #if hscriptPos ':${e.line}' #else '' #end;
		if (instance == null #if LUA_ALLOWED || instance.parentLua == null #end)
			return '$errorHeader ($scriptHeader$lineHeader) - $message';
		else return '$errorHeader ($scriptHeader) - HScript$lineHeader: $message';
	}

	public var origin:String;
	public override function new(?parent:Dynamic, file:String = '', ?varsToBring:Any = null) {
		#if LUA_ALLOWED
		parentLua = parent;
		if (parent != null) {
			this.origin = parent.scriptName;
			this.modFolder = parent.modFolder;
		}
		#end

		filePath = file;
		if (filePath != null && filePath.length > 0 && parent == null) {
			this.origin = filePath;
			#if MODS_ALLOWED
			var myFolder:Array<String> = filePath.split('/');
			if ('${myFolder[0]}/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) //is inside mods folder
				this.modFolder = myFolder[1];
			#end
		}
		super(null, {name: origin, autoRun: false, autoPreset: false});

		var scriptThing:String = file;
		if (parent == null && file != null) {
			var f:String = file.replace('\\', '/');
			if (f.contains('/') && !f.contains('\n')) scriptThing = File.getContent(f);
		}
		preset();
		AlterHscript.logLevel = hscriptLog;
		this.scriptCode = scriptThing;
		this.varsToBring = varsToBring;
	}

	var varsToBring(default, set):Any = null;
    function getDefaultVariables():Map<String, Dynamic> {
        return [
			"Type"				=> Type,
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
			"Sys"				=> Sys,
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

		set('add', FlxG.state.add);
		set('insert', FlxG.state.insert);
		set('remove', FlxG.state.remove);

		if (PlayState.instance == FlxG.state) {
			var psInstance:PlayState = PlayState.instance;
			set('addBehindGF', (obj:FlxBasic, ?order:Int = 0) -> psInstance.insert(psInstance.members.indexOf(psInstance.gfGroup) - order, obj));
			set('addBehindDad', (obj:FlxBasic, ?order:Int = 0) -> psInstance.insert(psInstance.members.indexOf(psInstance.dadGroup) - order, obj));
			set('addBehindBF', (obj:FlxBasic, ?order:Int = 0) -> psInstance.insert(psInstance.members.indexOf(psInstance.boyfriendGroup) - order, obj));
			setParent(psInstance); // allow use vars from playstate without "game" thing
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

	#if LUA_ALLOWED
	public static function initHaxeModuleCode(funk:FunkinLua, codeToRun:String, ?varsToBring:Any) funk.initHaxeModule(codeToRun, varsToBring);
	public static function initHaxeModule(funk:FunkinLua) funk.initHaxeModule();
	#end
	public function executeCode(?funcToRun:String, ?args:Array<Dynamic>):Dynamic return run(funcToRun, args);
	public function executeFunction(?funcToRun:String, ?args:Array<Dynamic>):AlterCall {
		if (funcToRun == null || !exists(funcToRun)) return null;
		return call(funcToRun, args);
	}

	public function run(?func:String, ?args:Array<Dynamic>, safe:Bool = true):Dynamic { // its the objectively better one
		try {
			if (func != null) {
				if (!executed) execute();
				if (!exists(func)) {
					if (!safe) {
						#if LUA_ALLOWED
						if (parentLua != null)
							FunkinLua.luaTrace('$origin - No function in HScript named "$func"!', false, false, FlxColor.RED);
						else PlayState.instance.addTextToDebug('$origin - No function named "$func"!', FlxColor.RED);
						#else
						PlayState.instance.addTextToDebug('$origin - No function named "$func"!', FlxColor.RED);
						#end
					}
					return null;
				}
				var result:AlterCall = call(func, args);
				return result?.returnValue ?? null;
			} else return execute();
		} catch (e:ImprError) {
			errorCaught(e);
			return null;
		}
	}

	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua) {
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
			try {
				initHaxeModuleCode(funk, codeToRun, varsToBring);
				var result:Dynamic = funk.hscript.run(funcToRun, funcArgs, false);
				if (LuaUtils.typeSupported(result)) return result;
			} catch (e:ImprError) funk.hscript.errorCaught(e);
			return null;
		});

		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			if (funk.hscript != null) {
				var result:Dynamic = funk.hscript.run(funcToRun, funcArgs, false);
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