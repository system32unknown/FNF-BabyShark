package hscript;

import hscript.Parser;
import hscript.Interp;

import haxe.ds.StringMap;
import haxe.Exception;

typedef InitRules = {
	var name:String;
	var autoRun:Bool;
	var preset:Bool;
}

class AlterHscript {
	public static var instances:StringMap<AlterHscript> = new StringMap<AlterHscript>();
    public var active:Bool = false;

	public var ruleSet:InitRules = null;
	var scriptStr:String = "";

	public var interp:Interp;
	public var parser:Parser;

    public function new(scriptStr:String, ?rules:InitRules) {
		if (rules == null) rules = {name: "alter", autoRun: true, preset: true};

		this.scriptStr = scriptStr;
		this.ruleSet = rules;

		parser = new Parser();
		interp = new Interp();

		interp.allowStaticVariables = interp.allowPublicVariables = true;
		parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;

		if (rules.autoRun) execute();
    }

	public function execute():Void {
		if (active || interp == null) return;

		if (ruleSet.preset) preset();

		instances.set(ruleSet.name, this);
		interp.execute(parser.parseString(scriptStr));
		active = true;
	}

	public function preset():Void {
		set("Math", Math);
		set("StringTools", StringTools);
	}

	public function get(field:String):Dynamic {
		return interp != null ? interp.variables.get(field) : false;
	}

	public function set(name:String, value:Dynamic, allowOverride:Bool = false):Void {
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

		//Then, stops this script.
		active = false;
		interp = null;
		parser = null;
		ruleSet = null;
	}

	public static function destroyAll():Void {
		for (key in instances.keys()) {
			if (instances.get(key).interp == null) continue;
			instances.get(key).destroy();
		}
	}
}