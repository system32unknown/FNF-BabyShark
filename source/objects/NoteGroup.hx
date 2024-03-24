package objects;

class NoteGroup extends FlxTypedGroup<Note> {
	var __loopSprite:Note;
	var i:Int = 0;
	var __currentlyLooping:Bool = false;
	var __time:Float = -1.0;

	public override function update(elapsed:Float) {
		i = length - 1;
		__loopSprite = null;
		__time = Conductor.songPosition;
		while(i >= 0) {
			__loopSprite = members[i--];
			if (__loopSprite == null || !__loopSprite.exists || !__loopSprite.active) continue;
			__loopSprite.update(elapsed);
		}
	}

	public override function draw() {
		@:privateAccess var oldDefaultCameras:Array<FlxCamera> = FlxCamera._defaultCameras;
		@:privateAccess if (cameras != null) FlxCamera._defaultCameras = cameras;

		var oldCur:Bool = __currentlyLooping;
		__currentlyLooping = true;

		i = length - 1;
		__loopSprite = null;
		__time = Conductor.songPosition;
		while(i >= 0) {
			__loopSprite = members[i--];
			if (__loopSprite == null || !__loopSprite.exists || !__loopSprite.visible) continue;
			__loopSprite.draw();
		}
		__currentlyLooping = oldCur;

		@:privateAccess FlxCamera._defaultCameras = oldDefaultCameras;
	}

	/**
	 * Gets the correct order of notes
	 **/
	public function get(id:Int) {
		return members[length - 1 - id];
	}

	public override function forEach(noteFunc:Note->Void, recursive:Bool = false) {
		i = length - 1;
		__loopSprite = null;
		__time = Conductor.songPosition;

		var oldCur:Bool = __currentlyLooping;
		__currentlyLooping = true;

		while(i >= 0) {
			__loopSprite = members[i--];
			if (__loopSprite == null || !__loopSprite.exists) continue;
			noteFunc(__loopSprite);
		}
		__currentlyLooping = oldCur;
	}
	public override function forEachAlive(noteFunc:Note->Void, recursive:Bool = false) {
		forEach((note) -> if (note.alive) noteFunc(note), recursive);
	}

	public override function remove(Object:Note, Splice:Bool = false):Note {
		if (members == null) return null;

		var index:Int = members.indexOf(Object);
		if (index < 0) return null;

		// doesnt prevent looping from breaking
		if (Splice && __currentlyLooping && i >= index) i++;

		if (Splice) {
			members.splice(index, 1);
			length--;
		} else members[index] = null;

		if (_memberRemoved != null)
			_memberRemoved.dispatch(Object);

		return Object;
	}
}