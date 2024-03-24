package psychlua;

#if HSCRIPT_ALLOWED
import flixel.FlxBasic;
import hscript.Parser;
import hscript.Interp;

class HScript extends Interp {
	public var active:Bool = true;
	public var parser:Parser;
	public var parentLua:FunkinLua;
	public var modFolder:String;
	public var exception:haxe.Exception;
	
	public static function initHaxeModule(parent:FunkinLua) {
		if(parent.hscript == null) {
			var times:Float = Date.now().getTime();
			parent.hscript = new HScript(parent);
			trace('initialized hscript interp successfully: ${parent.scriptName} (${Std.int(Date.now().getTime() - times)}ms)');
		}
	}

	public var origin:String;
	override public function new(?parent:FunkinLua, ?file:String) {
		super();

		var content:String = null;
		if (file != null) content = Paths.getTextFromFile(file);
		trace(content);

		parentLua = parent;
		if (parent != null) {
			this.origin = parent.scriptName;
			this.modFolder = parent.modFolder;
		}
		if (content != null) {
			this.origin = file;
			var myFolder:Array<String> = file.split('/');
			if(myFolder[0] + '/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) //is inside mods folder
				this.modFolder = myFolder[1];
		}

		preset();
		executeCode(content);
	}

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

			#if VIDEOS_ALLOWED
			"VideoSpriteManager"=> backend.VideoSpriteManager,
			"VideoManager" 		=> backend.VideoManager,
			#end

			// Sys related stuff
			#if sys
			"File"				=> sys.io.File,
			"FileSystem"		=> sys.FileSystem,
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
            "FlxPoint"          => getMAClass("flixel.math.FlxPoint"),
            "FlxAxes"           => getMAClass("flixel.util.FlxAxes"),
            "FlxColor"          => getMAClass("flixel.util.FlxColor"),
            "FlxKey"            => getMAClass("flixel.input.keyboard.FlxKey"),
            "FlxSound"          => flixel.sound.FlxSound,
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

            "engine" => {
				version: Main.engineVer.version.trim(),
				app_version: lime.app.Application.current.meta.get('version'),
                commit: macros.GitCommitMacro.commitNumber,
                hash: macros.GitCommitMacro.commitHash.trim(),
                name: "Alter Engine"
            }
        ];
    }

    inline function getMAClass(className:String) return Type.resolveClass('${className}_HSC');
	
	function preset() {
		parser = new Parser();
		allowStaticVariables = allowPublicVariables = true;
		parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;
		parser.preprocesorValues = getDefaultPreprocessors();

        for (key => type in getDefaultVariables()) setVar(key, type);

		// Functions & Variables
		setVar('setVar', (name:String, value:Dynamic) -> {
			PlayState.instance.variables.set(name, value);
			return value;
		});
		setVar('getVar', (name:String) -> {
			if(PlayState.instance.variables.exists(name))
				return PlayState.instance.variables.get(name);
			return null;
		});
		setVar('removeVar', (name:String) -> {
			if(PlayState.instance.variables.exists(name)) {
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});
		setVar('debugPrint', (text:String, ?color:FlxColor = FlxColor.WHITE) -> PlayState.instance.addTextToDebug(text, color));

		setVar('getModSetting', function(saveTag:String, ?modName:String = null) {
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
		setVar('keyboardJustPressed', (name:String) -> return Reflect.getProperty(FlxG.keys.justPressed, name));
		setVar('keyboardPressed', (name:String) -> return Reflect.getProperty(FlxG.keys.pressed, name));
		setVar('keyboardReleased', (name:String) -> return Reflect.getProperty(FlxG.keys.justReleased, name));

		setVar('keyJustPressed', function(name:String = '') {
			name = name.toLowerCase();
			return switch(name) {
				case 'left': Controls.instance.NOTE_LEFT_P;
				case 'down': Controls.instance.NOTE_DOWN_P;
				case 'up': Controls.instance.NOTE_UP_P;
				case 'right': Controls.instance.NOTE_RIGHT_P;
				default: Controls.instance.justPressed(name);
			}
		});
		setVar('keyPressed', function(name:String = '') {
			name = name.toLowerCase();
			return switch(name) {
				case 'left': Controls.instance.NOTE_LEFT;
				case 'down': Controls.instance.NOTE_DOWN;
				case 'up': Controls.instance.NOTE_UP;
				case 'right': Controls.instance.NOTE_RIGHT;
				default: Controls.instance.pressed(name);
			}
		});
		setVar('keyReleased', function(name:String = '') {
			name = name.toLowerCase();
			return switch(name) {
				case 'left': Controls.instance.NOTE_LEFT_R;
				case 'down': Controls.instance.NOTE_DOWN_R;
				case 'up': Controls.instance.NOTE_UP_R;
				case 'right': Controls.instance.NOTE_RIGHT_R;
				default: Controls.instance.justReleased(name);
			}
		});

		// For adding your own callbacks

		// not very tested but should work
		setVar('createGlobalCallback', function(name:String, func:haxe.Constraints.Function) {
			#if LUA_ALLOWED
			for (script in PlayState.instance.luaArray)
				if(script != null && script.lua != null && !script.closed)
					script.set(name, func);
			#end
			FunkinLua.customFunctions.set(name, func);
		});

		// tested
		setVar('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null) {
			if(funk == null) funk = parentLua;
			if(funk != null) funk.addLocalCallback(name, func);
			else FunkinLua.luaTrace('createCallback ($name): 3rd argument is null', false, false, FlxColor.RED);
		});

		setVar('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
			try {
				var str:String = '';
				if(libPackage.length > 0) str = '$libPackage.';
				setVar(libName, resolveClassOrEnum(str + libName));
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
		setVar('parentLua', parentLua);
		setVar('this', this);
		setVar('game', FlxG.state);
		setVar('controls', Controls.instance);

		setVar('buildTarget', LuaUtils.getBuildTarget());
		setVar('customSubstate', CustomSubstate.instance);
		setVar('customSubstateName', CustomSubstate.name);

		setVar('Function_Stop', LuaUtils.Function_Stop);
		setVar('Function_Continue', LuaUtils.Function_Continue);
		setVar('Function_StopLua', LuaUtils.Function_StopLua); //doesnt do much cuz HScript has a lower priority than Lua
		setVar('Function_StopHScript', LuaUtils.Function_StopHScript);
		setVar('Function_StopAll', LuaUtils.Function_StopAll);

		setVar('add', FlxG.state.add);
		setVar('insert', FlxG.state.insert);
		setVar('remove', FlxG.state.remove);

		if(PlayState.instance == FlxG.state) {
			var psInstance:PlayState = PlayState.instance;
			setVar('addBehindGF', (obj:FlxBasic, ?order:Int = 0) -> psInstance.insert(psInstance.members.indexOf(psInstance.gfGroup) - order, obj));
			setVar('addBehindDad', (obj:FlxBasic, ?order:Int = 0) -> psInstance.insert(psInstance.members.indexOf(psInstance.dadGroup) - order, obj));
			setVar('addBehindBF', (obj:FlxBasic, ?order:Int = 0) -> psInstance.insert(psInstance.members.indexOf(psInstance.boyfriendGroup) - order, obj));
			scriptObject = psInstance; // allow use vars from playstate without "game" thing
		}
	}

	function getDefaultPreprocessors():Map<String, Dynamic> {
		var defines = macros.DefinesMacro.defines;
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

	public function executeCode(?codeToRun:String):Dynamic {
		if (codeToRun == null || !active) return null;

		try {
			return execute(parser.parseString(codeToRun, origin));
		} catch(e) exception = e;
		return null;
	}

	public function executeFunction(?funcToRun:String, ?funcArgs:Array<Dynamic>):Dynamic {
		if (funcToRun == null || !active) return null;

		if (variables.exists(funcToRun)) {
			if (funcArgs == null) funcArgs = [];
			try {
				return Reflect.callMethod(null, variables.get(funcToRun), funcArgs);
			} catch(e) exception = e;
		}
		return null;
	}

	public static function implement(funk:FunkinLua) {
		#if LUA_ALLOWED
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any, ?funcToRun:String, ?funcArgs:Array<Dynamic>):Dynamic {
			initHaxeModule(funk);
			if (!funk.hscript.active) return null;

			if(varsToBring != null) for (key in Reflect.fields(varsToBring)) funk.hscript.setVar(key, Reflect.field(varsToBring, key));

			var retVal:Dynamic = funk.hscript.executeCode(codeToRun);
			if (funcToRun != null) {
				var retFunc:Dynamic = funk.hscript.executeFunction(funcToRun, funcArgs);
				if (retFunc != null) retVal = retFunc;
			}

			if (funk.hscript.exception != null) {
				funk.hscript.active = false;
				FunkinLua.luaTrace('ERROR (${funk.lastCalledFunction}) - ${funk.hscript.exception}', false, false, FlxColor.RED);
			}

			return retVal;
		});
		
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic>) {
			if (!funk.hscript.active) return null;
			var retVal:Dynamic = funk.hscript.executeFunction(funcToRun, funcArgs);
			if (funk.hscript.exception != null) {
				funk.hscript.active = false;
				FunkinLua.luaTrace('ERROR (${funk.lastCalledFunction}) - ${funk.hscript.exception}', false, false, FlxColor.RED);
			}
			return retVal;
		});
		// This function is unnecessary because import already exists in SScript as a native feature
		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			initHaxeModule(funk);
			if (!funk.hscript.active) return;
	
			var str:String = '';
			if(libPackage.length > 0) str = '$libPackage.';
			else if(libName == null) libName = '';

			try { funk.hscript.setVar(libName, funk.hscript.resolveClassOrEnum(str + libName));
			} catch(e) {
				funk.hscript.active = false;
				FunkinLua.luaTrace('ERROR (${funk.lastCalledFunction}) - $e', false, false, FlxColor.RED);
			}
		});
		#end
	}

	public function destroy() {
		active = false;
		parser = null;
		origin = null;
		parentLua = null;
		__instanceFields = [];
		binops.clear();
		customClasses.clear();
		declared = [];
		importBlocklist = [];
		locals.clear();
		resetVariables();
	}
}
#end