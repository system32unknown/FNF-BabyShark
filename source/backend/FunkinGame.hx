package backend;

class FunkinGame extends flixel.FlxGame {
    public function new(gameWidth = 0, gameHeight = 0, ?initialState:flixel.util.typeLimit.NextState, updateFramerate = 60, drawFramerate = 60, skipSplash = false, startFullscreen = false) {
        super(gameWidth, gameHeight, initialState, updateFramerate, drawFramerate, skipSplash, startFullscreen);
        _customSoundTray = flixel.custom.CustomSoundTray;
    }
    var skipNextTickUpdate:Bool = false;
    public override function switchState() {
        super.switchState();
        draw();
		_total = ticks = getTicks();
        skipNextTickUpdate = true;
    }

    public override function onEnterFrame(t) {
        if (skipNextTickUpdate != (skipNextTickUpdate = false))
            _total = ticks = getTicks();
        super.onEnterFrame(t);
    }
}