package objects;

import lime.app.Application;
import lime.ui.KeyCode;

class PlayField extends flixel.group.FlxSpriteGroup {
	public function new() {
		super();

		Application.current.window.onKeyDown.add(input);
		Application.current.window.onKeyUp.add(release);
	}

    override function destroy():Void {
		Application.current.window.onKeyDown.remove(input);
		Application.current.window.onKeyUp.remove(release);

		super.destroy();
	}

    override function update(delta:Float):Void {
    }

    inline function input(key:KeyCode, _):Void {
    }
    inline function release(key:KeyCode, _):Void {
    }
}