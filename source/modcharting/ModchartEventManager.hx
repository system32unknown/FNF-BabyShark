package modcharting;

class ModchartEventManager {
    var renderer:PlayfieldRenderer;
    public function new(renderer:PlayfieldRenderer) {
        this.renderer = renderer;
    }
    var events:Array<ModchartEvent> = [];

    public function update(elapsed:Float) {
        if (events.length > 1) {
            events.sort((a, b) -> {
                if (a.time < b.time) return -1;
                else if (a.time > b.time) return 1;
                else return 0;
            });
        }
		while(events.length > 0) {
			var event:ModchartEvent = events[0];
			if(Conductor.songPosition < event.time) break;
            event.func(event.args);
			events.shift();
		}
        Modifier.beat = ((Conductor.songPosition * .001) * (Conductor.bpm / 60));
    }

    public function addEvent(beat:Float, func:Array<String>->Void, args:Array<String>) {
        events.push(new ModchartEvent(ModchartUtil.getTimeFromBeat(beat), func, args));
    }

    public function clearEvents() {
        events = [];
    }
}