package states;

import psychlua.HScript;

class HscriptState extends MusicBeatState {
    public var hscriptRef:HScript;
    public static var instance:HscriptState = null;
    public function new(className:String, test:Bool = false) {
        super();
        instance = this;
        hscriptRef = new HScript(null, 'assets/scripts/states/$className.hx'); //skip init create call to avoid errors
        hscriptRef.set('instance', instance);
    }

    override function create() {
        hscriptRef.call("onCreate");
        super.create();
        hscriptRef.call("postCreate");
    }

    override function update(elapsed:Float) {
        hscriptRef.call("onUpdate", [elapsed]);
        super.update(elapsed);
        hscriptRef.call("onUpdatePost", [elapsed]);
    }
}