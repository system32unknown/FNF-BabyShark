package substates;

import psychlua.HScript;

class HscriptSubstate extends MusicBeatSubstate {
    public var hscriptRef:HScript;
    public static var instance:HscriptSubstate = null;
    public function new(name:String, args:Array<Dynamic>) {
        super();
        instance = this;

        hscriptRef = new HScript(null, 'assets/scripts/substates/$name.hx');

        hscriptRef.set("instance", instance);
        hscriptRef.call("new", args);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        hscriptRef.call("update", [elapsed]);
    }
}