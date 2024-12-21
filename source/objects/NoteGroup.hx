package objects;

import objects.Note.CastNote;
class NoteGroup extends FlxTypedGroup<Note> {
    var pool:Array<Note> = [];
    var _ecyc_e:Note;

    public function push(n:Note) {
        pool.push(n);
    }

    public function spawnNote(castNote:CastNote, ?oldNote:Note) {
        if (pool.length > 0) {
            _ecyc_e = pool.pop();
            _ecyc_e.exists = true;
        } else {
            _ecyc_e = null;
            _ecyc_e = new Note();
            members.push(_ecyc_e);
            ++length;
        }
        return _ecyc_e.recycleNote(castNote, oldNote);
    }
}