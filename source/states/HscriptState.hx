package states;

import psychlua.HScript;

class HscriptState extends MusicBeatState {
    public var hscriptRef:HScript;
    public static var instance:HscriptState = null;
    public function new(file:String) {
        super();
        instance = this;

        hscriptRef = new HScript(null, file); // skip init create call to avoid errors
        hscriptRef.set('instance', instance);
    }

    override function create() {
        hscriptRef.call("onCreate");
        super.create();
        hscriptRef.call("onCreatePost");
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