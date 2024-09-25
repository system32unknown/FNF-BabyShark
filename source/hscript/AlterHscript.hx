package hscript;

import haxe.ds.StringMap;
import hscript.IrisConfig;

@:structInit
class IrisCall {
	/**
	 * an HScript Function Name.
	**/
	public var funName:String;

	/**
	 * an HScript Function's signature.
	**/
	public var signature:Dynamic;

	/**
	 * an HScript Method's return value.
	**/
	public var returnValue:Dynamic;
}

/**
 * This basic object helps with the creation of scripts,
 * along with having neat helper functions to initialize and stop scripts
 *
 * It is highly recommended that you override this class to add custom defualt variables and such.
 * Hscript-Iris but I modified it.
**/
class AlterHscript {
	static function getDefaultPos(name:String = "hscript-alter"):haxe.PosInfos {
		return {
			fileName: name,
			lineNumber: -1,
			className: "UnknownClass",
			methodName: "unknownFunction",
			customParams: null
		}
	}

	public static var instances:StringMap<AlterHscript> = new StringMap<AlterHscript>();

	public var config:IrisConfig = null;

	/**
	 * Current script name, from `config.name`.
	**/
	public var name(get, never):String;
	inline function get_name():String return config.name;

	var scriptCode:String = "";

	public var interp:Interp;
	public var parser:Parser;
	var expr:Expr;

    public function new(scriptCode:String, ?config:AutoIrisConfig):Void {
		if (config == null) config = new IrisConfig("hscript-alter", false, []);
		this.scriptCode = scriptCode;
		this.config = IrisConfig.from(config);
		this.config.name = fixScriptName(this.name);

		parser = new Parser();
		interp = new Interp();

		// run the script.
		if (this.config.autoRun) execute();

		interp.allowStaticVariables = interp.allowPublicVariables = true;
		parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;
    }

	static function fixScriptName(toFix:String):String {
		// make sure to never have an indentically named instance.
		var _name:String = toFix;
		var copyID:Int = 1;
		while (instances.exists(_name)) {
			_name = '${toFix}_${copyID}';
			copyID += 1;
		}
		return _name;
	}

	public function execute():Dynamic {
		if (interp == null) throw "Attempt to run script failed, script is probably destroyed.";

		if (expr == null) expr = parse();
		@:privateAccess interp.execute(parser.mk(EBlock([]), 0, 0));
		instances.set(this.name, this);
		return interp.execute(expr);
	}

	public function parse(force:Bool = false):Expr {
		if (force || expr == null) return expr = parser.parseString(scriptCode);
		return expr;
	}

	public function get(field:String):Dynamic {
		return interp != null ? interp.variables.get(field) : false;
	}

	public function set(name:String, value:Dynamic, allowOverride:Bool = true):Void {
		if (interp == null || interp.variables == null) return;
		if (allowOverride || !interp.variables.exists(name)) interp.setVar(name, value);
	}

	public function call(fun:String, ?args:Array<Dynamic>):IrisCall {
		if (interp == null) return null;
		args ??= [];

		var ny:Dynamic = interp.variables.get(fun);
		var isFunction:Bool = false;
		try {
			isFunction = ny != null && Reflect.isFunction(ny);
			if (!isFunction) throw 'Tried to call a non-function, for "$fun"';

			final ret:Dynamic = Reflect.callMethod(null, ny, args);
			return {funName: fun, signature: ny, returnValue: ret};
		}
		#if hscriptPos
		catch (e:Expr.Error) {Logs.trace("HSCRIPT ERROR: " + Printer.errorToString(e) + " [" + this.interp.posInfos() + "]", ERROR);}
		#end
		catch (e:haxe.Exception) {Logs.trace("HSCRIPT ERROR: " + e + " [" + (isFunction ? this.interp.posInfos() : getDefaultPos(this.name)) + "]", ERROR);}
		return null;
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

		if (instances.exists(this.name)) instances.remove(this.name);

		//Then, stops this script.
		interp = null;
		parser = null;
	}

	public static function destroyAll():Void {
		for (key in instances.keys()) {
			if (instances.get(key).interp == null) continue;
			instances.get(key).destroy();
		}
	}

	public function setParent(parent:Dynamic) {
		interp.scriptObject = parent;
	}
}