package states;

import psychlua.HScript;
import psychlua.LuaUtils;
import alterhscript.AlterHscript;

class HscriptState extends MusicBeatState {
	public var hscript:HScript;
	public static var instance:HscriptState;

	public function new(file:String) {
		super();
		instance = this;

		hscript = new HScript(null, file); // skip init create call to avoid errors
		hscript.set('instance', instance);
	}

	override function create() {
		if (hscript.exists('onCreate')) hscript.call("onCreate");
		super.create();
		callOnHScript("onCreatePost");
	}

	override function update(elapsed:Float) {
		callOnHScript("onUpdate", [elapsed]);
		super.update(elapsed);
		callOnHScript("onUpdatePost", [elapsed]);
	}

	override function destroy() {
		if (hscript != null) {
			if (hscript.exists('onDestroy')) hscript.call('onDestroy');
			hscript = null;
		}
		super.destroy();
	}

	public function callOnHScript(funcToCall:String, ?args:Array<Dynamic>, ?ignoreStops:Bool = false, ?exclusions:Array<String>, ?excludeValues:Array<Dynamic>):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		#if HSCRIPT_ALLOWED
		if (exclusions == null) exclusions = [];
		if (excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		@:privateAccess
		if (hscript == null || !hscript.exists(funcToCall) || exclusions.contains(hscript.origin)) return null;

		var callValue:AlterCall = hscript.call(funcToCall, args);
		if (callValue != null) {
			var myValue:Dynamic = callValue.returnValue;
			if ((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops) returnVal = myValue;
			if (myValue != null && !excludeValues.contains(myValue)) returnVal = myValue;
		}
		#end
		return returnVal;
	}
}