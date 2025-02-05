package substates;

import psychlua.HScript;

class HscriptSubstate extends MusicBeatSubstate {
    public var hscriptRef:HScript;
    public static var instance:HscriptSubstate = null;
    public function new(file:String, args:Array<Dynamic>) {
        super();
        instance = this;

        hscriptRef = new HScript(null, file);
        hscriptRef.set("instance", instance);
        if (hscriptRef.exists('onCreate')) hscriptRef.call('onCreate');
        if (hscriptRef.exists('new')) hscriptRef.call("new", args);
    }

    override function update(elapsed:Float) {
        hscriptRef.call("onUpdate", [elapsed]);
        super.update(elapsed);
        hscriptRef.call("onUpdatePost", [elapsed]);
    }

    override function destroy() {
        if (hscriptRef.exists('onDestroy')) hscriptRef.call('onDestroy');
        super.destroy();
    }
}