package backend;

class FunkinGame extends flixel.FlxGame {
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