package objects;

import Note.CastNote;
class NoteGroup extends FlxTypedGroup<Note> {
    public var pool:Array<Note> = [];
    public function spawnNote(castNote:CastNote, ?oldNote:Note):Note {
        var index:Int = pool.lastIndexOf(null);
        var _ecyc_e:Note = new Note();
        if (index >= 0) {
            _ecyc_e = pool[index];
            pool[index] = null;
        } else {
            _ecyc_e.exists = false;
            _ecyc_e.recycleNote(castNote, oldNote);
            add(_ecyc_e);
        }
        return _ecyc_e;
    }
}