package psychlua;

#if HSCRIPT_ALLOWED
import hscript.AlterHscript;
import hscript.AlterHscript.IrisCall;
import hscript.Expr.Error as ImprError;
import flixel.FlxBasic;

class HScript extends AlterHscript {
	public var parentLua:FunkinLua;
	public var filePath:String;
	public var modFolder:String;
	public var returnValue:Dynamic = null;

	public function errorCaught(e:ImprError, ?funcName:String) {
		var header:String = (funcName != null ? '$origin: $funcName' : origin);
		#if LUA_ALLOWED
		FunkinLua.luaTrace('ERROR ($header) - ${e.toString()}', false, false, FlxColor.RED);
		#else
		PlayState.instance.addTextToDebug('ERROR ($header) - ${e.toString()}', FlxColor.RED);
		#end
	}

	public static function initHaxeModuleCode(parent:FunkinLua, code:String, ?varsToBring:Any = null):Dynamic {
		var hs:HScript = try parent.hscript catch (e) null;
		if(hs == null) {
			trace('initializing haxe interp for: ${parent.scriptName}');
			parent.hscript = new HScript(parent, code, varsToBring);
			return parent.hscript.returnValue;
		} else {
			var prevCode:String = hs.scriptCode;
			try {
				if (hs.scriptCode != code) {
					hs.scriptCode = code;
					hs.parse(true);
				}
				hs.varsToBring = varsToBring;
				hs.returnValue = hs.execute();
				return hs.returnValue;
			} catch(e:ImprError) {
				hs.errorCaught(e);
				hs.returnValue = null;
				hs.scriptCode = prevCode;
				return e;
			}
		}
		return null;
	}

	public var origin:String;
	public override function new(?parent:Dynamic, ?file:String, ?varsToBring:Any = null) {
		if (file == null) file = '';

		super(null);

		parentLua = parent;
		if (parent != null) {
			this.origin = parent.scriptName;
			this.modFolder = parent.modFolder;
		}

		filePath = file;
		if (filePath != null && filePath.length > 0 && parent == null) {
			this.origin = filePath;
			#if MODS_ALLOWED
			var myFolder:Array<String> = filePath.split('/');
			if('${myFolder[0]}/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) //is inside mods folder
				this.modFolder = myFolder[1];
			#end
		}

		var scriptThing:String = file;
		if(parent == null && file != null) {
			var f:String = file.replace('\\', '/');
			if(f.contains('/') && !f.contains('\n')) scriptThing = File.getContent(f);
		}
		preset();
		this.scriptCode = scriptThing;
		this.varsToBring = varsToBring;
		try {
			this.returnValue = execute();
		} catch (e:ImprError) {
			this.errorCaught(e);
			this.returnValue = e;
		}
	}

	var varsToBring(default, set):Any = null;
    function getDefaultVariables():Map<String, Dynamic> {
        return [
			"Date"				=> Date,
			"DateTools"			=> DateTools,
			"Math"				=> Math,
			"Reflect"			=> Reflect,
			"Std"				=> Std,
			"HScript"			=> HScript,
			"Type"				=> Type,
            "Xml"               => Xml,
			"EReg"				=> EReg,
			"StringTools"		=> StringTools,
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
            "Application"       => lime.app.Application,
            "window"            => lime.app.Application.current.window,

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
            "PlayState"         => PlayState,
            "Note"              => objects.Note,
            "NoteSplash"        => objects.NoteSplash,
            "HealthIcon"        => objects.HealthIcon,
            "StrumLine"         => objects.StrumNote,
            "Character"         => objects.Character,
            "Paths"             => Paths,
            "Conductor"         => Conductor,
            "Alphabet"          => Alphabet,
			"DeltaTrail" 		=> objects.DeltaTrail,

            "CoolUtil"          => CoolUtil,
            "ClientPrefs"       => ClientPrefs,

			#if (!flash && sys)
			"FlxRuntimeShader"  => flixel.addons.display.FlxRuntimeShader,
			#end
			'ShaderFilter'		=> openfl.filters.ShaderFilter,

			"version" 			=> Main.engineVer.version.trim(),
            "engine" => {
				app_version: lime.app.Application.current.meta.get('version'),
                commit: macros.GitCommitMacro.commitNumber,
                hash: macros.GitCommitMacro.commitHash.trim(),
                name: "Alter Engine"
            }
        ];
    }

	function preset() {
		parser.preprocesorValues = getDefaultPreprocessors();
        for (key => type in getDefaultVariables()) set(key, type);

		// Functions & Variables
		set('setVar', (name:String, value:Dynamic) -> {
			MusicBeatState.getVariables().set(name, value);
			return value;
		});
		set('getVar', (name:String) -> {
			if(MusicBeatState.getVariables().exists(name))
				return MusicBeatState.getVariables().get(name);
			return null;
		});
		set('removeVar', (name:String) -> {
			if(MusicBeatState.getVariables().exists(name)) {
				MusicBeatState.getVariables().remove(name);
				return true;
			}
			return false;
		});
		set('debugPrint', (text:String, ?color:FlxColor = FlxColor.WHITE) -> PlayState.instance.addTextToDebug(text, color));

		set('getModSetting', function(saveTag:String, ?modName:String = null) {
			if(modName == null) {
				if(this.modFolder == null) {
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
		set('createGlobalCallback', function(name:String, func:haxe.Constraints.Function) {
			#if LUA_ALLOWED
			for (script in PlayState.instance.luaArray)
				if(script != null && script.lua != null && !script.closed)
					script.set(name, func);
			#end
			FunkinLua.customFunctions.set(name, func);
		});

		set('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null) {
			if(funk == null) funk = parentLua;
			if(funk != null) funk.addLocalCallback(name, func);
			else FunkinLua.luaTrace('createCallback ($name): 3rd argument is null', false, false, FlxColor.RED);
		});

		set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
			try {
				var str:String = '';
				if(libPackage.length > 0) str = '$libPackage.';
				set(libName, resolveClassOrEnum(str + libName));
			} catch (e:Dynamic) {
				var msg:String = e.message.substr(0, e.message.indexOf('\n'));
				#if LUA_ALLOWED
				if(parentLua != null) {
					FunkinLua.lastCalledScript = parentLua;
					FunkinLua.luaTrace('$origin: ${parentLua.lastCalledFunction} - $msg', false, false, FlxColor.RED);
					return;
				}
				#end
				if(PlayState.instance != null) PlayState.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
				else Logs.trace('$origin - $msg', ERROR);
			}
		});

		set("openState", (name:String) -> {
			FlxG.sound.music?.stop();
			var hxFile:String = Paths.getPath('scripts/states/$name.hx');
            if(FileSystem.exists(hxFile)) FlxG.switchState(() -> new states.HscriptState(hxFile));
            else {
                try {
                    final rawClass:Class<Dynamic> = Type.resolveClass(name);
                    if(rawClass == null) return; 
                    FlxG.switchState(cast(Type.createInstance(rawClass, []), flixel.FlxState));
                } catch(e:Dynamic) {
                    Logs.trace('$e: Unspecified result for switching state "$name", could not switch states!', ERROR);
                    return;
                }
            }
        });
        set("openSubState", (name:String, args:Array<Dynamic>) -> {
			var hxFile:String = Paths.getPath('scripts/substates/$name.hx');
            if(FileSystem.exists(hxFile)) FlxG.state.openSubState(new substates.HscriptSubstate(hxFile, args));
            else {
                try {
                    final rawClass:Class<Dynamic> = Type.resolveClass(name);
					if(rawClass == null) return;
                    FlxG.state.openSubState(cast(Type.createInstance(rawClass, args), FlxSubState));
                } catch(e:Dynamic) {
                    Logs.trace('$e: Unspecified result for opening substate "$name", could not be opened!', ERROR);
                    return;
                }
            }
        });

		set('close', destroy);

		set('parentLua', #if LUA_ALLOWED parentLua #else null #end);
		set('this', this);
		set('game', FlxG.state);
		set('controls', Controls);

		set('buildTarget', LuaUtils.getBuildTarget());
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

		if(PlayState.instance == FlxG.state) {
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
		defines.set("ALTER_APP_VER", lime.app.Application.current.meta.get('version'));
		defines.set("ALTER_COMMIT", macros.GitCommitMacro.commitNumber);
		defines.set("ALTER_HASH", macros.GitCommitMacro.commitHash);
		return defines;
	}

	function resolveClassOrEnum(name:String):Dynamic {
		var c:Dynamic = Type.resolveClass(name);
		if (c == null) c = Type.resolveEnum(name);
		return c;
	}

	public function executeCode(?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
		if (funcToRun == null) return null;
		if (!exists(funcToRun)) {
			#if LUA_ALLOWED
			FunkinLua.luaTrace('$origin - No function named: $funcToRun', false, false, FlxColor.RED);
			#else
			PlayState.instance.addTextToDebug('$origin - No function named: $funcToRun', FlxColor.RED);
			#end
			return null;
		}

		try {
			return call(funcToRun, funcArgs);
		} catch(e:ImprError) errorCaught(e, funcToRun);
		return null;
	}

	public function executeFunction(funcToRun:String = null, funcArgs:Array<Dynamic> = null):IrisCall {
		if (funcToRun == null || !exists(funcToRun)) return null;
		return call(funcToRun, funcArgs);
	}

	public static function implement(funk:FunkinLua) {
		#if LUA_ALLOWED
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any, ?funcToRun:String, ?funcArgs:Array<Dynamic>):Dynamic {
			#if HSCRIPT_ALLOWED
			final retVal:Dynamic = initHaxeModuleCode(funk, codeToRun, varsToBring);
			if (Std.isOfType(retVal, ImprError)) return null;
			if (funcToRun == null) return (LuaUtils.typeSupported(retVal)) ? retVal : null;

			try {
				final retCall:IrisCall = funk.hscript.executeCode(funcToRun, funcArgs);
				if (retCall != null) return (LuaUtils.typeSupported(retCall.returnValue)) ? retCall.returnValue : null;
			} catch(e:ImprError) funk.hscript.errorCaught(e, funcToRun);
			#else
			FunkinLua.luaTrace("runHaxeCode: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end
			return null;
		});
		
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			#if HSCRIPT_ALLOWED
			try {
				final retVal:IrisCall = funk.hscript.executeFunction(funcToRun, funcArgs);
				if (retVal != null) return (LuaUtils.typeSupported(retVal.returnValue)) ? retVal.returnValue : null;
			} catch(e:ImprError) funk.hscript.errorCaught(e, funcToRun);
			return null;
			#else
			FunkinLua.luaTrace("runHaxeFunction: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			return null;
			#end
		});
		// This function is unnecessary because import already exists in SScript as a native feature
		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			var str:String = '';
			if(libPackage.length > 0) str = '$libPackage.';
			else if(libName == null) libName = '';

			var c:Dynamic = funk.hscript.resolveClassOrEnum(str + libName);
			#if HSCRIPT_ALLOWED
			if (funk.hscript != null) {
				try {
					if (c != null) funk.hscript.set(libName, c);
				} catch (e:ImprError) FunkinLua.luaTrace(funk.hscript.origin + ":" + funk.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			}
			FunkinLua.luaTrace("addHaxeLibrary is deprecated! Import classes through \"import\" in HScript!", false, true);
			#else
			FunkinLua.luaTrace("addHaxeLibrary: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end
		});
		#end
	}

	inline function getClassHSC(className:String):Class<Dynamic> {
		return Type.resolveClass('${className}_HSC');
	}

	public override function destroy() {
		origin = null;
		#if LUA_ALLOWED parentLua = null; #end
		super.destroy();
	}

	function set_varsToBring(values:Any) {
		if (varsToBring != null) for (key in Reflect.fields(varsToBring)) if(exists(key.trim())) interp.variables.remove(key.trim());
		if (values != null) {
			for (key in Reflect.fields(values)) {
				key = key.trim();
				set(key, Reflect.field(values, key));
			}
		}
		return varsToBring = values;
	}
}
#end