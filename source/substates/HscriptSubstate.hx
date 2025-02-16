package substates;

import psychlua.HScript;

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
        hscript.call("onUpdate", [elapsed]);
        super.update(elapsed);
        hscript.call("onUpdatePost", [elapsed]);
    }

    override function destroy() {
        if (hscript.exists('onDestroy')) hscript.call('onDestroy');
        super.destroy();
    }
}