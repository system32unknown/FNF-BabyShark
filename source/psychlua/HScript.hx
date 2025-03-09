package psychlua;

import flixel.FlxBasic;
import lime.app.Application;
#if HSCRIPT_ALLOWED
import alterhscript.AlterHscript;
import hscript.Expr.Error as AlterError;
import hscript.Printer;
import haxe.ValueException;

typedef HScriptInfos = {
	> haxe.PosInfos,
	var ?funcName:String;
	var ?showLine:Null<Bool>;
	#if LUA_ALLOWED
	var ?isLua:Null<Bool>;
	#end
}

class HScript extends AlterHscript {
	public var filePath:String;
	public var modFolder:String;
	public var returnValue:Dynamic;

	#if LUA_ALLOWED
	public var parentLua:FunkinLua;
	public static function initHaxeModule(parent:FunkinLua) {
		if (parent.hscript == null) {
			trace('initializing haxe interp for: ${parent.scriptName}');
			parent.hscript = new HScript(parent);
		}
	}

	public static function initHaxeModuleCode(parent:FunkinLua, code:String, ?varsToBring:Any = null) {
		var hs:HScript = try parent.hscript catch (e) null;
		if (hs == null) {
			trace('initializing haxe interp for: ${parent.scriptName}');
			try {
				parent.hscript = new HScript(parent, code, varsToBring);
			} catch (e:AlterError) {
				var pos:HScriptInfos = cast {fileName: parent.scriptName, isLua: true};
				if (parent.lastCalledFunction != '') pos.funcName = parent.lastCalledFunction;
				AlterHscript.error(Printer.errorToString(e, false), pos);
				parent.hscript = null;
			}
		} else {
			try {
				hs.scriptCode = code;
				hs.varsToBring = varsToBring;
				hs.parse(true);
				var ret:Dynamic = hs.execute();
				hs.returnValue = ret;
			} catch (e:AlterError) {
				var pos:HScriptInfos = cast hs.interp.posInfos();
				pos.isLua = true;
				if (parent.lastCalledFunction != '') pos.funcName = parent.lastCalledFunction;
				AlterHscript.error(Printer.errorToString(e, false), pos);
				hs.returnValue = null;
			}
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
			if ('${myFolder[0]}/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) // is inside mods folder
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
		super(scriptThing, new alterhscript.AlterConfig(scriptName, false, false));
		#if LUA_ALLOWED
		parentLua = parent;
		if (parent != null) {
			this.origin = parent.scriptName;
			this.modFolder = parent.modFolder;
		}
		#end
		preset();
		this.varsToBring = varsToBring;
		if (!manualRun) {
			try {
				var ret:Dynamic = execute();
				returnValue = ret;
			} catch (e:AlterError) {
				returnValue = null;
				this.destroy();
				throw e;
			}
		}
	}

	var varsToBring(default, set):Any = null;

	function getDefaultVariables():Map<String, Dynamic> {
		return [
			"Type" => Type,
			"Sys" => Sys,
			"Date" => Date,
			"DateTools" => DateTools,
			"Reflect" => Reflect,
			"HScript" => HScript,
			"Xml" => Xml,
			"EReg" => EReg,
			"Lambda" => Lambda,

			#if flxanimate
			"FlxAnimate" => FlxAnimate,
			#end

			// Sys related stuff
			#if sys
			"File" => File, "FileSystem" => FileSystem,
			#end
			"Assets" => openfl.Assets,

			// OpenFL & Lime related stuff
			"Application" => Application,
			"window" => Application.current.window,

			// Flixel related stuff
			"FlxG" => FlxG,
			"FlxSprite" => FlxSprite,
			"FlxBasic" => FlxBasic,
			"FlxCamera" => FlxCamera,
			"PsychCamera" => backend.PsychCamera,
			"FlxTween" => FlxTween,
			"FlxEase" => FlxEase,
			"FlxPoint" => getClassHSC('flixel.math.FlxPoint'),
			"FlxAxes" => getClassHSC('flixel.util.FlxAxes'),
			"FlxColor" => getClassHSC('flixel.util.FlxColor'),
			"FlxKey" => getClassHSC('flixel.input.keyboard.FlxKey'),
			"FlxSound" => FlxSound,
			"FlxAssets" => flixel.system.FlxAssets,
			"FlxMath" => FlxMath,
			"FlxGroup" => flixel.group.FlxGroup,
			"FlxTypedGroup" => FlxTypedGroup,
			"FlxSpriteGroup" => FlxSpriteGroup,
			"FlxTypeText" => flixel.addons.text.FlxTypeText,
			"FlxText" => FlxText,
			"FlxTimer" => FlxTimer,

			// Engine related stuff
			"Countdown" => backend.BaseStage.Countdown,
			"PlayState" => PlayState,
			"Note" => objects.Note,
			"CustomSubstate" => CustomSubstate,
			"NoteSplash" => objects.NoteSplash,
			"HealthIcon" => objects.HealthIcon,
			"StrumLine" => objects.StrumNote,
			"Character" => objects.Character,
			"Paths" => Paths,
			"Conductor" => Conductor,
			"Alphabet" => Alphabet,
			"DeltaTrail" => objects.DeltaTrail,
			#if ACHIEVEMENTS_ALLOWED
			"Achievements" => Achievements,
			#end

			"CoolUtil" => CoolUtil,
			"ClientPrefs" => ClientPrefs,

			#if (!flash && sys)
			"FlxRuntimeShader" => flixel.addons.display.FlxRuntimeShader, "ErrorHandledRuntimeShader" => shaders.ErrorHandledShader.ErrorHandledRuntimeShader,
			#end
			'ShaderFilter' => openfl.filters.ShaderFilter,

			"version" => Main.engineVer.version.trim(),
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
					AlterHscript.error('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', this.interp.posInfos());
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
			return switch (name) {
				case 'left': Controls.justPressed('note_left');
				case 'down': Controls.justPressed('note_down');
				case 'up': Controls.justPressed('note_up');
				case 'right': Controls.justPressed('note_right');
				default: Controls.justPressed(name);
			}
		});
		set('keyPressed', function(name:String = '') {
			name = name.toLowerCase();
			return switch (name) {
				case 'left': Controls.pressed('note_left');
				case 'down': Controls.pressed('note_down');
				case 'up': Controls.pressed('note_up');
				case 'right': Controls.pressed('note_right');
				default: Controls.pressed(name);
			}
		});
		set('keyReleased', function(name:String = '') {
			name = name.toLowerCase();
			return switch (name) {
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
			else AlterHscript.error('createCallback ($name): 3rd argument is null', this.interp.posInfos());
		});
		#end

		set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
			try {
				var str:String = '';
				if (libPackage.length > 0) str = '$libPackage.';
				set(libName, Type.resolveClass(str + libName));
			} catch (e:AlterError) AlterHscript.error(Printer.errorToString(e, false), this.interp.posInfos());
		});
		set('parentLua', #if LUA_ALLOWED parentLua #else null #end);
		set("openState", (name:String) -> {
			final blacklistStates:Array<String> = ['loadingstate'];
			if (blacklistStates.contains(name.toLowerCase())) return;

			FlxG.sound.music?.stop();
			var hxFile:String = Paths.getPath('scripts/states/$name.hx');
			if (FileSystem.exists(hxFile)) FlxG.switchState(() -> new states.HscriptState(hxFile));
			else {
				try {
					final rawClass:Class<Dynamic> = Type.resolveClass(name);
					if (rawClass == null) return;
					FlxG.switchState(() -> cast(Type.createInstance(rawClass, []), flixel.FlxState));
				} catch (e:AlterError) {
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
				} catch (e:Dynamic) {
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
		set('Function_StopLua', LuaUtils.Function_StopLua); // doesnt do much cuz HScript has a lower priority than Lua
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
		#if LUA_ALLOWED FunkinLua.lastCalledScript = prevLua; #end
		return result;
	}

	public override function parse(force:Bool = false) {
		return super.parse(force);
	}

	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua) {
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
			initHaxeModuleCode(funk, codeToRun, varsToBring);
			if (funk.hscript != null) {
				final retVal:AlterCall = funk.hscript.call(funcToRun, funcArgs);
				if (retVal != null) {
					return (LuaUtils.isLuaSupported(retVal.returnValue)) ? retVal.returnValue : null;
				} else if (funk.hscript.returnValue != null) return funk.hscript.returnValue;
			}
			return null;
		});

		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			if (funk.hscript != null) {
				final retVal:AlterCall = funk.hscript.call(funcToRun, funcArgs);
				if (retVal != null) return (LuaUtils.isLuaSupported(retVal.returnValue)) ? retVal.returnValue : null;
			} else {
				var pos:HScriptInfos = cast {fileName: funk.scriptName, showLine: false};
				if (funk.lastCalledFunction != '') pos.funcName = funk.lastCalledFunction;
				AlterHscript.error("runHaxeFunction: HScript has not been initialized yet! Use \"runHaxeCode\" to initialize it", pos);
			}
			return null;
		});
		// This function is unnecessary because import already exists in HScript as a native feature
		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			var str:String = '';
			if (libPackage.length > 0) str = libPackage + '.';
			else if (libName == null) libName = '';
			var cls:Dynamic = funk.hscript.resolveClassOrEnum(str);

			if (funk.hscript == null)
				initHaxeModule(funk);

			var pos:HScriptInfos = cast funk.hscript.interp.posInfos();
			pos.showLine = false;
			if (funk.lastCalledFunction != '') pos.funcName = funk.lastCalledFunction;

			try {
				if (cls != null) funk.hscript.set(libName, cls);
			} catch (e:AlterError) AlterHscript.error(Printer.errorToString(e, false), pos);
			FunkinLua.lastCalledScript = funk;
			if (FunkinLua.getBool('luaDebugMode') && FunkinLua.getBool('luaDeprecatedWarnings'))
				AlterHscript.warn("addHaxeLibrary is deprecated! Import classes through \"import\" in HScript!", pos);
		});
	}
	#end

	inline function getClassHSC(className:String):Class<Dynamic> {
		return Type.resolveClass('${className}_HSC');
	}

	override function call(funcToRun:String, ?args:Array<Dynamic>):AlterCall {
		if (funcToRun == null || interp == null) return null;
		if (!exists(funcToRun)) {
			AlterHscript.error('No function named: $funcToRun', this.interp.posInfos());
			return null;
		}
		try {
			var func:Dynamic = interp.variables.get(funcToRun); // function signature
			final ret:Dynamic = Reflect.callMethod(null, func, args ?? []);
			return {funName: funcToRun, signature: func, returnValue: ret};
		} catch (e:AlterError) {
			var pos:HScriptInfos = cast this.interp.posInfos();
			pos.funcName = funcToRun;
			if (parentLua != null) {
				pos.isLua = true;
				if (parentLua.lastCalledFunction != '') pos.funcName = parentLua.lastCalledFunction;
			}
			AlterHscript.error(Printer.errorToString(e, false), pos);
		} catch (e:ValueException) {
			var pos:HScriptInfos = cast this.interp.posInfos();
			pos.funcName = funcToRun;
			#if LUA_ALLOWED
			if (parentLua != null) {
				pos.isLua = true;
				if (parentLua.lastCalledFunction != '') pos.funcName = parentLua.lastCalledFunction;
			}
			#end
			AlterHscript.error('$e', pos);
		}
		return null;
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
#else
class HScript {
	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua) {
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
	}
	#end
}
#end