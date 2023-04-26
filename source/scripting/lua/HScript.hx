package scripting.lua;

#if (hscript && HSCRIPT_ALLOWED)
import hscript.Parser;
import hscript.Expr;
import hscript.Interp;
#end

class HScript
{
	#if (hscript && HSCRIPT_ALLOWED)
	static var MAX_POOL(default, null):Int = 255;

	public static var parser:Parser = new Parser();

	public var idEnumerator:Int = 0;

	public var exprs:Map<Int, Expr> = new Map(); // safe cache
	var pool:Map<Int, Expr> = new Map(); // unsafe immediate cache
	var keys:Map<String, Int> = new Map(); // indices
	var syek:Map<Int, String> = new Map(); // secidni (for pool)
	var poolarr:Array<Int> = [];

	public var interp:Interp;

	public var variables(get, never):Map<String, Dynamic>;
	public function get_variables()
		return interp.variables;
	
	public static function initHaxeModule() {
		#if (hscript && HSCRIPT_ALLOWED)
		if(FunkinLua.hscript == null)
			FunkinLua.hscript = new HScript(); //TO DO: Fix issue with 2 scripts not being able to use the same variable names
		#end
	}

	public function setVar(key:String, data:Dynamic):Map<String, Dynamic> {
		variables.set(key, data);
		
		for (i in variables.keys())
			if (!variables.exists(i))
				variables.set(i, variables.get(i));

		return variables;
	}

	public function new() {
		interp = new Interp();
		setVars();
	}

	function setVars():Void {
		setVar('FlxG', FlxG);
		setVar('FlxSprite', FlxSprite);
		setVar('FlxCamera', FlxCamera);
		setVar('FlxTimer', FlxTimer);
		setVar('FlxTween', FlxTween);
		setVar('FlxEase', FlxEase);
		setVar('PlayState', states.PlayState);
		setVar('game', states.PlayState.instance);
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
	}

	public function parse(code:String):Int {
		if (keys.exists(code)) return keys.get(code);
		var expr:Expr = parser.parseString(code);
		exprs.set(idEnumerator, expr);
		keys.set(code, idEnumerator);
		return idEnumerator++;
	}

	inline public function getExpr(id:Int):Expr
		return exprs.get(id);

	public function execute(expr:Expr):Dynamic {
		parser.allowTypes = parser.allowJSON = parser.allowMetadata = true;
		parser.line = 1;
		return interp.execute(expr);
	}

	public function immediateExecute(code:String):Dynamic {
		var expr:Expr;
		if (keys.exists(code)) expr = pool.get(keys.get(code));
		else {
			expr = parser.parseString(code);
			pool.set(idEnumerator, expr);
			keys.set(code, idEnumerator);
			syek.set(idEnumerator, code);
			poolarr.push(idEnumerator);
			idEnumerator++;
			while (poolarr.length > MAX_POOL) {
				var id:Int = poolarr.shift();
				var code:String = syek.get(id);
				syek.remove(id);
				keys.remove(code);
				pool.remove(id);
			}
		}
		return inline execute(expr);
	}

	public function destroy() {
		exprs.clear();
		pool.clear();
		keys.clear();
		syek.clear();
		poolarr.resize(0);
	}
	#end
}