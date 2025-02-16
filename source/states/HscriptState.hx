package states;

import psychlua.HScript;

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
        hscript.call("onCreatePost");
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