package backend;

import haxe.Timer;
import haxe.ds.IntMap;
import haxe.ds.Vector;

import objects.Note;

class NoteProcessor {
	var hit:Int = 0;
	var totalCnt:Int = 0;

	public var skipBf:Int = 0;
	var skipCnt:Int = 0;

 	var nps:IntMap<Float> = new IntMap<Float>();
	public var npsVal:Float = 0;
	public var npsMax:Float = 0;
	var sideHit:Float = 0;

    public function update(?combo:Int) {
		if (!Settings.data.processFirst) {
            noteSpawn();
            noteUpdate();
        } else {
            noteUpdate();
            noteSpawn();
        }
		skipCnt = skipBf;
		if (skipCnt > 0 && combo != null) combo += skipBf;
    }

    public function noteSpawn() {
        
    }

    public function noteUpdate() {
        
    }

    public function updateNPS() {
        var npsTime:Int = Math.round(Conductor.songPosition);
		if (sideHit > 0) nps.set(npsTime, sideHit);
		for (key => value in nps) {
			if (key + 1000 > npsTime) {
				if (sideHit > 0) {
					npsVal += sideHit;
					sideHit = 0;
				} else continue;
			} else {
				npsVal -= value;
				nps.remove(key);
			}
		}

		npsMax = Math.max(npsVal, npsMax);
    }
}