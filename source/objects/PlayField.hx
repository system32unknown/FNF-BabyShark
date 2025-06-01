package objects;

class PlayField extends flixel.group.FlxGroup {

	public var unspawnedNotes:Array<Note> = [];

	var noteSpawnIndex:Int = 0;
	var noteSpawnDelay:Float = 1500;

	var keys:Array<String> = [];

	public dynamic function noteHit():Void {}
	public dynamic function noteMiss(note:Note):Void {}
	public dynamic function opponentMiss(note:Note):Void {}
	public dynamic function ghostTap():Void {}

	public var strumlines:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();

	public function new() {
		super();

		add(this.strumlines = new FlxTypedSpriteGroup<StrumNote>());

		Application.current.window.onKeyDown.add(input);
		Application.current.window.onKeyUp.add(release);
	}

	override function destroy():Void {
		Application.current.window.onKeyDown.remove(input);
		Application.current.window.onKeyUp.remove(release);

		super.destroy();
	}

	var keysHeld:Array<Bool> = [for (_ in 0...4) false];
	inline function input(key:KeyCode, _):Void {
	}

	inline function release(key:KeyCode, _):Void {
	}
}