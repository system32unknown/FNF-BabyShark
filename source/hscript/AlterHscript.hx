package hscript;

import haxe.ds.StringMap;
import haxe.Exception;

class AlterHscript {
	public static var instances:StringMap<AlterHscript> = new StringMap<AlterHscript>();
    public var active:Bool = false;

	public var hscriptName:String = "";
	var scriptCode:String = "";

	public var interp:Interp;
	public var parser:Parser;
	var expr:Expr;

    public function new(scriptCode:String, name:String = "hscript-alter") {
		this.scriptCode = scriptCode;
		hscriptName = name;

		parser = new Parser();
		interp = new Interp();
		fixScriptName(hscriptName);

		interp.allowStaticVariables = interp.allowPublicVariables = true;
		parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;
    }

	function fixScriptName(defaultName:String):Void {
		// make sure to never have an indentically named instance.
		var copyID:Int = 1;
		while (instances.exists(hscriptName)) {
			hscriptName = '${defaultName}_$copyID';
			copyID++;
		}
	}

	public function execute():AlterHscript {
		if (active || interp == null) return this;

		instances.set(hscriptName, this);
		if (expr == null) expr = parse();
		@:privateAccess interp.execute(parser.mk(EBlock([]), 0, 0));
		if (expr != null) interp.execute(expr);
		active = instances.exists(hscriptName);

		return this;
	}

	public function parse():Expr {
		if (active || expr != null) return expr;
		return expr = parser.parseString(scriptCode);
	}

	public function get(field:String):Dynamic {
		return interp != null ? interp.variables.get(field) : false;
	}

	public function set(name:String, value:Dynamic, allowOverride:Bool = true):Void {
		if (interp == null) return;

		try {
			if (allowOverride || !interp.variables.exists(name)) interp.setVar(name, value);
		} catch (e:Exception) Logs.trace("HSCRIPT ERROR: " + e, ERROR);
	}

	public function call(func:String, ?args:Array<Dynamic>):Dynamic {
		if (interp == null) return 0;

		args ??= [];

		var ny:Dynamic = interp.variables.get(func);
		if (ny != null && Reflect.isFunction(ny)) {
			try {
				final ret:Dynamic = Reflect.callMethod(null, ny, args);
				return {methodName: func, methodReturn: ny, methodVal: ret}
			} catch (e:Exception) Logs.trace("HSCRIPT ERROR: " + e, ERROR);
		}
		return 0;
	}

	public function exists(field:String):Bool {
		return interp != null ? interp.variables.exists(field) : false;
	}

	//stolen from codename due to hscript exception format (ex: hscript:1: hscript:1: -> hscript:1:)
	public static function errorHandler(error:hscript.Expr.Error):String {
		var fn:String = '${error.origin}:${error.line}: ';
		var err:String = error.toString();
		if (err.startsWith(fn)) err = err.substr(fn.length);
		return err;
	}

	public function destroy() @:privateAccess {
		//First, Stopping Hscript-improved variables
		interp.__instanceFields = [];
		interp.binops.clear();
		interp.customClasses.clear();
		interp.declared = [];
		interp.importBlocklist = [];
		interp.locals.clear();
		interp.variables.clear();
		interp.resetVariables();

		if (instances.exists(hscriptName))
			instances.remove(hscriptName);

		//Then, stops this script.
		active = false;
		interp = null;
		parser = null;
	}

	public static function destroyAll():Void {
		for (key in instances.keys()) {
			if (instances.get(key).interp == null) continue;
			instances.get(key).destroy();
		}
	}
}