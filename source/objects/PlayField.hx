package objects;

class PlayField extends flixel.group.FlxGroup {
    public dynamic function noteHit():Void {}
    public dynamic function noteMiss(note:Note:Void) {}
    public dynamic function opponentMiss(note:Note):Void {}
    public dynamic function ghostTap():Void {}

	public var unspawnedNotes:Array<Note> = [];
	var noteSpawnIndex:Int = 0;
	var noteSpawnDelay:Float = 1500;

    var keys:Array<String> = [];

    public function new() {
        super();
    }
}