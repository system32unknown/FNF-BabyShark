package objects;

import openfl.events.KeyboardEvent;

class PlayField extends flixel.group.FlxSpriteGroup {
	public function new() {
		super();

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
	}

	override function destroy():Void {
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		super.destroy();
	}

	override function update(delta:Float):Void {
		
	}

	function onKeyPress(e:KeyboardEvent):Void {

	}

	function onKeyRelease(e:KeyboardEvent):Void {

	}

	public dynamic function noteHit(note:Note):Void {}
	public dynamic function noteMiss(note:Note):Void {}
}