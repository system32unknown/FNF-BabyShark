package scripting.lua;

#if (hscript && HSCRIPT_ALLOWED)
import hscript.Parser;
import hscript.Expr;
import hscript.Interp;
#end

import haxe.Exception;

class HScript
{
	#if (hscript && HSCRIPT_ALLOWED)
	public static var parser:Parser = new Parser();
	public var interp:Interp;

	public var parentLua:FunkinLua;

	public var variables(get, never):Map<String, Dynamic>;
	public function get_variables()
		return interp.variables;
	
	public static function initHaxeModule(parent:FunkinLua) {
		#if (hscript && HSCRIPT_ALLOWED)
		if(FunkinLua.hscript == null)
			FunkinLua.hscript = new HScript(parent); //TO DO: Fix issue with 2 scripts not being able to use the same variable names
		#end
	}

	public function setVar(key:String, data:Dynamic):Map<String, Dynamic> {
		variables.set(key, data);
		
		for (i in variables.keys())
			if (!variables.exists(i))
				variables.set(i, variables.get(i));

		return variables;
	}

	public function new(parent:FunkinLua) {
		interp = new Interp();
		parentLua = parent;
		setVars();
	}

	function setVars():Void {
		setVar('FlxG', FlxG);
		setVar('FlxSprite', FlxSprite);
		setVar('FlxCamera', FlxCamera);
		setVar('FlxTimer', FlxTimer);
		setVar('FlxTween', FlxTween);
		setVar('FlxEase', FlxEase);
		setVar('PlayState', PlayState);
		setVar('game', PlayState.instance);
		setVar('Paths', Paths);
		setVar('Character', game.Character);
		setVar('Alphabet', ui.Alphabet);
		setVar('CustomSubstate', CustomSubstate);
		#if (!flash && sys)
		setVar('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		#end
		setVar('ShaderFilter', openfl.filters.ShaderFilter);
		setVar('StringTools', StringTools);

		setVar('setVar', function(name:String, value:Dynamic) {
			PlayState.instance.variables.set(name, value);
		});
		setVar('getVar', function(name:String) {
			var result:Dynamic = null;
			if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
			return result;
		});
		setVar('removeVar', function(name:String) {
			if(PlayState.instance.variables.exists(name)) {
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});
		setVar('debugPrint', function(text:String, ?color:FlxColor = null) {
			if(color == null) color = FlxColor.WHITE;
			parentLua.luaTrace(text, true, false, color);
		});
		setVar('createCallback', function(name:String, adv:Bool, func:Dynamic, ?funk:FunkinLua = null) {
			if(funk == null) funk = parentLua;
			funk.addCallback(name, adv, func);
		});
		setVar('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
			try {
				var str:String = '';
				if(libPackage.length > 0)
					str = libPackage + '.';

				interp.variables.set(libName, Type.resolveClass(str + libName));
			} catch (e:Dynamic) {
				parentLua.luaTrace(parentLua.scriptName + ":" + parentLua.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			}
		});
		setVar('parentLua', parentLua);
	}

	public static function getImports(code:String):Array<String> {
	    var imports:Array<String> = [];
	    var re:EReg = ~/^(?:(?!"|')(?:[^"']|\.(?!"|'))*?)import\s+([\w.]+);$/m;
	    while (re.match(code)) {
	        imports.push(re.matched(1));
	        code = re.matchedRight();
	    }
	    return imports;
	}

	public function execute(codeToRun:String, ?funcToRun:String = null, ?funcArgs:Array<Dynamic>):Dynamic {
		for (imports in getImports(codeToRun)) {
			var splitted:Array<String> = imports.split('.');
			interp.variables.set(splitted[splitted.length - 1], Type.resolveClass(imports));
		}
        	codeToRun = ~/^(?:(?!"|')(?:[^"']|\.(?!"|'))*?)import\s+([\w.]+);$/mg.replace(codeToRun, "");

		parser.allowTypes = parser.allowJSON = parser.allowMetadata = true;
		parser.line = 1;
		var expr:Expr = parser.parseString(codeToRun);
		try {
			var value:Dynamic = interp.execute(expr);
			return (funcToRun != null) ? executeFunction(funcToRun, funcArgs) : value;
		} catch(e:Exception) {
			trace(e);
			return null;
		}
	}

	public function executeFunction(funcToRun:String = null, funcArgs:Array<Dynamic>) {
		if(funcToRun != null) {
			if(interp.variables.exists(funcToRun)) {
				if(funcArgs == null) funcArgs = [];
				return Reflect.callMethod(null, interp.variables.get(funcToRun), funcArgs);
			}
		}
		return null;
	}

	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua) {
		funk.addCallback("runHaxeCode", function(l:FunkinLua, codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null) {
			var retVal:Dynamic = null;

			#if hscript
			try {
				if(varsToBring != null)
					for (key in Reflect.fields(varsToBring))
						FunkinLua.hscript.interp.variables.set(key, Reflect.field(varsToBring, key));
				retVal = FunkinLua.hscript.execute(codeToRun, funcToRun, funcArgs);
			} catch (e:Dynamic) {
				l.luaTrace(funk.scriptName + ":" + funk.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			}
			#else
			l.luaTrace("runHaxeCode: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end

			if(retVal != null && !LuaUtils.isOfTypes(retVal, [Bool, Int, Float, String, Array])) retVal = null;
			return retVal;
		});

		funk.addCallback("runHaxeFunction", function(l:FunkinLua, funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			#if hscript
			try {
				return FunkinLua.hscript.executeFunction(funcToRun, funcArgs);
			} catch(e:Exception) {
				funk.luaTrace(Std.string(e));
				return null;
			}
			#else
			l.luaTrace("runHaxeFunction: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end
		});

		funk.addCallback("addHaxeLibrary", function(l:FunkinLua, libName:String, ?libPackage:String = '') {
			#if hscript
			try {
				var str:String = '';
				if(libPackage.length > 0)
					str = libPackage + '.';
				FunkinLua.hscript.variables.set(libName, Type.resolveClass(str + libName));
			} catch (e:Dynamic) {
				l.luaTrace(funk.scriptName + ":" + l.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			}
			#else
			l.luaTrace("addHaxeLibrary: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end
		});
		#end
	}
	#end
}