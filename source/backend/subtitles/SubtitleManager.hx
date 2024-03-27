package backend.subtitles;

class SubtitleManager extends FlxTypedGroup<Subtitle> {
    public function addSubtitle(text:String, ?typeSpeed:Float, showTime:Float, ?properties:SubtitleProperties, ?onComplete:Void->Void) {
		var subtitle:Subtitle = new Subtitle(text, typeSpeed, showTime, properties, onComplete);
		subtitle.manager = this;
		add(subtitle);
	}
	public function onSubtitleComplete(subtitle:Subtitle) remove(subtitle);
}