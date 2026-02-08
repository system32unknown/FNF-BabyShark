package scripting;

import alterhscript.AlterHscript;
class HscriptSubstate extends MusicBeatSubstate {
	public var hscript:HScript;

	public static var instance:HscriptSubstate = null;

	public function new(file:String, args:Array<Dynamic>) {
		super();
		instance = this;

		hscript = new HScript(null, file);
		hscript.set("instance", instance);
		if (hscript.exists('onCreate')) hscript.call('onCreate');
		if (hscript.exists('new')) hscript.call("new", args);
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
		var returnVal:Dynamic = ScriptUtils.Function_Continue;
		#if HSCRIPT_ALLOWED
		if (exclusions == null) exclusions = [];
		if (excludeValues == null) excludeValues = [ScriptUtils.Function_Continue];

		@:privateAccess
		if (hscript == null || !hscript.exists(funcToCall) || exclusions.contains(hscript.origin)) return null;

		var callValue:AlterCall = hscript.call(funcToCall, args);
		if (callValue != null) {
			var myValue:Dynamic = callValue.returnValue;
			if ((myValue == ScriptUtils.Function_StopHScript || myValue == ScriptUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops) returnVal = myValue;
			if (myValue != null && !excludeValues.contains(myValue)) returnVal = myValue;
		}
		#end
		return returnVal;
	}
}
