package psychlua;

#if HSCRIPT_ALLOWED
import hscript.Parser;
import hscript.Interp;

class HScript extends Interp {
	public var active:Bool = true;
	public var parser:Parser;
	public var parentLua:FunkinLua;
	public var exception:haxe.Exception;
	
	public static function initHaxeModule(parent:FunkinLua) {
		if(parent.hscript == null) {
			var times:Float = Date.now().getTime();
			parent.hscript = new HScript(parent);
			Logs.trace('initialized hscript interp successfully: ${parent.scriptName} (${Std.int(Date.now().getTime() - times)}ms)');
		}
	}

	public static function hscriptTrace(text:String, color:FlxColor = FlxColor.WHITE) {
		PlayState.instance.addTextToDebug(text, color);
		Logs.trace(text);
	}

	public var origin:String;
	override public function new(?parent:FunkinLua, ?file:String) {
		super();

		var content:String = null;
		if (file != null) content = Paths.getTextFromFile(file, false, true);
		
		parentLua = parent;
		if (parent != null) origin = parent.scriptName;
		if (content != null) origin = file;
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

			#if VIDEOS_ALLOWED
			"VideoSpriteHandler"=> backend.VideoSpriteHandler,
			"VideoHandler" 		=> backend.VideoHandler,
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
            "FlxBasic"          => flixel.FlxBasic,
            "FlxCamera"         => FlxCamera,
            "state"             => FlxG.state,
            "FlxTween"          => FlxTween,
            "FlxEase"           => FlxEase,
            "FlxPoint"          => getMacroAbstractClass("flixel.math.FlxPoint"),
            "FlxAxes"           => getMacroAbstractClass("flixel.util.FlxAxes"),
            "FlxColor"          => getMacroAbstractClass("flixel.util.FlxColor"),
            "FlxKey"            => getMacroAbstractClass("flixel.input.keyboard.FlxKey"),
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
			"DeltaTrail" => objects.DeltaTrail,

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

    function getMacroAbstractClass(className:String)
		return Type.resolveClass('${className}_HSC');
	
	function preset() {
		parser = new Parser();
		parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;
		parser.preprocesorValues = getDefaultPreprocessors();
		scriptObject = PlayState.instance; // allow use vars from playstate without "game" thing

        for (key => type in getDefaultVariables()) setVar(key, type);

		// Functions & Variables
		setVar('setVar', (name:String, value:Dynamic) -> PlayState.instance.variables.set(name, value));
		setVar('getVar', (name:String) -> return PlayState.instance.variables.get(name));
		setVar('removeVar', (name:String) -> return PlayState.instance.variables.remove(name));
		setVar('debugPrint', (text:String, ?color:FlxColor = FlxColor.WHITE) -> PlayState.instance.addTextToDebug(text, color));

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
			if(parentLua != null) funk.addLocalCallback(name, func);
			else FunkinLua.luaTrace('createCallback ($name): 3rd argument is null', false, false, FlxColor.RED);
		});

		setVar('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
			var str:String = '';
			if(libPackage.length > 0)
				str = '$libPackage.';
			setVar(libName, resolveClassOrEnum(str + libName));
		});
		setVar('parentLua', parentLua);
		setVar('this', this);
		setVar('game', PlayState.instance);

		setVar('buildTarget', FunkinLua.getBuildTarget());
		setVar('customSubstate', CustomSubstate.instance);
		setVar('customSubstateName', CustomSubstate.name);

		setVar('Function_Stop', FunkinLua.Function_Stop);
		setVar('Function_Continue', FunkinLua.Function_Continue);
		setVar('Function_StopLua', FunkinLua.Function_StopLua); //doesnt do much cuz HScript has a lower priority than Lua
		setVar('Function_StopHScript', FunkinLua.Function_StopHScript);
		setVar('Function_StopAll', FunkinLua.Function_StopAll);
	}

	function getDefaultPreprocessors():Map<String, Dynamic> {
		var defines = macros.DefinesMacro.defines;
		defines.set("ALTER_ENGINE", true);
		defines.set("ALTER_VER", lime.app.Application.current.meta.get('version'));
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

			if(varsToBring != null)
				for (key in Reflect.fields(varsToBring)) funk.hscript.setVar(key, Reflect.field(varsToBring, key));

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

			var c:Dynamic = funk.hscript.resolveClassOrEnum(str + libName);
			try {
				funk.hscript.setVar(libName, c);
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