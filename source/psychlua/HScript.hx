package psychlua;

import flixel.FlxBasic;
import objects.Character;

#if (HSCRIPT_ALLOWED && SScript >= "3.0.0")
import tea.SScript;
class HScript extends SScript {
	public var parentLua:FunkinLua;
	
	public static function initHaxeModule(parent:FunkinLua) {
		if(parent.hscript == null) {
			trace('initializing haxe interp for: ${parent.scriptName}');
			parent.hscript = new HScript(parent);
		}
	}

	public var origin:String;
	override public function new(?parent:FunkinLua, ?file:String) {
		if (file == null) file = '';

		super(null, false, false);
		doFile(file);
		
		parentLua = parent;
		if (parent != null) origin = parent.scriptName;
		if (scriptFile != null && scriptFile.length > 0) origin = scriptFile;
		preset();
		execute();
	}

    function getDefaultVariables():Map<String, Dynamic> {
        return [
            // Haxe related stuff
            "Reflect"           => Reflect,
            "Xml"               => Xml,

            "Json"              => haxe.Json,
            // OpenFL & Lime related stuff
            "Application"       => lime.app.Application,
            "window"            => lime.app.Application.current.window,

            // Flixel related stuff
            "FlxG"              => FlxG,
            "FlxSprite"         => FlxSprite,
            "FlxBasic"          => FlxBasic,
            "FlxCamera"         => FlxCamera,
            "state"             => FlxG.state,
            "FlxEase"           => FlxEase,
            "FlxTween"          => FlxTween,
            "FlxSound"          => flixel.sound.FlxSound,
            "FlxAssets"         => flixel.system.FlxAssets,
            "FlxMath"           => FlxMath,
            "FlxGroup"          => flixel.group.FlxGroup,
            "FlxTypedGroup"     => FlxTypedGroup,
            "FlxSpriteGroup"    => FlxSpriteGroup,
            "FlxTypeText"       => flixel.addons.text.FlxTypeText,
            "FlxText"           => FlxText,
            "FlxTimer"          => FlxTimer,
            "FlxPoint"          => getMacroAbstractClass("flixel.math.FlxPoint"),
            "FlxAxes"           => getMacroAbstractClass("flixel.util.FlxAxes"),
            "FlxColor"          => getMacroAbstractClass("flixel.util.FlxColor"),
            "FlxKey"            => getMacroAbstractClass("flixel.input.keyboard.FlxKey"),

            // Engine related stuff
            "PlayState"         => PlayState,
            "game"              => PlayState.instance,
            "Note"              => objects.Note,
            "NoteSplash"        => objects.NoteSplash,
            "HealthIcon"        => objects.HealthIcon,
            "StrumLine"         => objects.StrumNote,
            "Character"         => Character,
            "Paths"             => Paths,
            "Conductor"         => Conductor,
            "Alphabet"          => Alphabet,

            "CoolUtil"          => CoolUtil,
            "ClientPrefs"       => ClientPrefs,

			#if (!flash && sys)
			"FlxRuntimeShader"  => flixel.addons.display.FlxRuntimeShader,
			#end
			'ShaderFilter'		=> openfl.filters.ShaderFilter,

            "DeltaTrail" => objects.DeltaTrail,
            "engine" => {
				version: Main.engineVer.version.trim(),
				app_version: lime.app.Application.current.meta.get('version'),
                commit: macro.GitCommitMacro.commitNumber,
                hash: macro.GitCommitMacro.commitHash,
                name: "Alter Engine"
            }
        ];
    }

    function getMacroAbstractClass(className:String)
		return Type.resolveClass('${className}_HSC');

	override function preset() {
		super.preset();

        for (key => type in getDefaultVariables()) set(key, type);

		// Functions & Variables
		set('setVar', (name:String, value:Dynamic) -> {PlayState.instance.variables.set(name, value);});
		set('getVar', (name:String) -> {return PlayState.instance.variables.get(name);});
		set('removeVar', (name:String) -> {return PlayState.instance.variables.remove(name);});
		set('debugPrint', (text:String, ?color:FlxColor = FlxColor.WHITE) -> {PlayState.instance.addTextToDebug(text, color);});

		// For adding your own callbacks

		// not very tested but should work
		set('createGlobalCallback', function(name:String, func:haxe.Constraints.Function) {
			#if LUA_ALLOWED
			for (script in PlayState.instance.luaArray)
				if(script != null && script.lua != null && !script.closed)
					Lua_helper.add_callback(script.lua, name, func);
			#end
			FunkinLua.customFunctions.set(name, func);
		});

		// tested
		set('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null) {
			if(funk == null) funk = parentLua;
			if(parentLua != null) funk.addLocalCallback(name, func);
			else FunkinLua.luaTrace('createCallback ($name): 3rd argument is null', false, false, FlxColor.RED);
		});

		set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
			try {
				var str:String = '';
				if(libPackage.length > 0)
					str = libPackage + '.';

				var c:Dynamic = Type.resolveClass(str + libName);
				if (c == null) c = Type.resolveEnum(str + libName);
				set(libName, c);
			} catch (e:Dynamic) {
				var msg:String = e.message.substr(0, e.message.indexOf('\n'));
				if(parentLua != null) {
					FunkinLua.lastCalledScript = parentLua;
					msg = origin + ":" + parentLua.lastCalledFunction + " - " + msg;
				} else msg = '$origin - $msg';
				FunkinLua.luaTrace(msg, parentLua == null, false, FlxColor.RED);
			}
		});
		set('parentLua', parentLua);
		set('this', this);
		set('game', PlayState.instance);
		set('buildTarget', FunkinLua.getBuildTarget());
		set('customSubstate', CustomSubstate.instance);
		set('customSubstateName', CustomSubstate.name);

		set('Function_Stop', FunkinLua.Function_Stop);
		set('Function_Continue', FunkinLua.Function_Continue);
		set('Function_StopLua', FunkinLua.Function_StopLua); //doesnt do much cuz HScript has a lower priority than Lua
		set('Function_StopHScript', FunkinLua.Function_StopHScript);
		set('Function_StopAll', FunkinLua.Function_StopAll);
		
		set('add', function(obj:FlxBasic) PlayState.instance.add(obj));
		set('addBehindGF', function(obj:FlxBasic) PlayState.instance.insert(PlayState.instance.members.indexOf(PlayState.instance.gfGroup), obj));
		set('addBehindDad', function(obj:FlxBasic) PlayState.instance.insert(PlayState.instance.members.indexOf(PlayState.instance.dadGroup), obj));
		set('addBehindBF', function(obj:FlxBasic) PlayState.instance.insert(PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup), obj));
		set('insert', function(pos:Int, obj:FlxBasic) PlayState.instance.insert(pos, obj));
		set('remove', function(obj:FlxBasic, splice:Bool = false) PlayState.instance.remove(obj, splice));
	}

	function resolveClassOrEnum(name:String):Dynamic {
		var c:Dynamic = Type.resolveClass(name);
		if (c == null) c = Type.resolveEnum(name);
		return c;
	}

	@:deprecated("Use executeFunction instead.")
	public function executeCode(?funcToRun:String, ?funcArgs:Array<Dynamic>):SCall {
		return executeFunction(funcToRun, funcArgs);
	}

	public function executeFunction(?funcToRun:String, ?funcArgs:Array<Dynamic>):SCall {
		var callValue:SCall = call(funcToRun, funcArgs);
		if (!callValue.succeeded) {
			var e = callValue.exceptions[0];
			if (e != null)
				FunkinLua.luaTrace('ERROR (${callValue.calledFunction}) - $e', false, false, FlxColor.RED);
		}
		return callValue;
	}

	public static function implement(funk:FunkinLua) {
		#if LUA_ALLOWED
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any, ?funcToRun:String, ?funcArgs:Array<Dynamic>):Dynamic {
			var retVal:SCall = null;
			initHaxeModule(funk);
			if(varsToBring != null) {
				if (varsToBring is Array) {
					for (vars in cast(varsToBring, Array<Dynamic>)) if (vars is String) {
						funk.hscript.doString('function temp__sscriptfunc() { return $vars; this.unset("bmV2ZXIgZ29ubmEgZ2l2ZSB5b3UgdXA"); }');
						var obj = funk.hscript.call('temp__sscriptfunc').returnValue;
						var fields = (obj is Class) ? Type.getClassFields(obj) : Reflect.fields(obj);
						for (key in fields)
							funk.hscript.set(key, Reflect.field(obj, key));
					}
				} else for (key in Reflect.fields(varsToBring))
					funk.hscript.set(key, Reflect.field(varsToBring, key));
			}
			funk.hscript.doString(codeToRun);

			if (funcToRun != null) {
				retVal = funk.hscript.executeFunction(funcToRun, funcArgs);
				if (retVal.returnValue != null)
					return retVal.returnValue;
			}
			return funk.hscript.returnValue;
		});
		
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic>):Dynamic {
			initHaxeModule(funk);
			return funk.hscript.executeFunction(funcToRun, funcArgs).returnValue;
		});
		// This function is unnecessary because import already exists in SScript as a native feature
		funk.addLocalCallback("addHaxeLibrary", function(?libName:String = '', ?libPackage:String = '') {
			var str:String = '';
			if(libPackage.length > 0)
				str = libPackage + '.' + libName;

			initHaxeModule(funk);
			funk.hscript.set(libName, funk.hscript.resolveClassOrEnum(str + libName));
		});
		#end
	}

	override public function destroy() {
		origin = null;
		parentLua = null;

		super.destroy();
	}
}
#end