package backend.subtitles;

class Subtitle extends flixel.addons.text.FlxTypeText {
    public var manager:SubtitleManager;
    public var onSubComplete:Void->Void;
    public function new(text:String, ?typeSpeed:Float, showTime:Float, properties:SubtitleProperties, onComplete:Void->Void) {
        properties = init(properties);

        super(properties.x, properties.y, FlxG.width, text, 36);
        onSubComplete = onComplete;
        
        setFormat(Paths.font(properties.fonts), properties.subtitleSize, FlxColor.WHITE, CENTER);
        setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        antialiasing = ClientPrefs.data.antialiasing;

        if (properties.centerScreen) screenCenter(properties.screenCenter);
        start(properties.typeSpeed, false, false, [], () -> FlxTimer.wait(showTime, () -> FlxTween.tween(this, {alpha: 0}, .5, {onComplete: (tween:FlxTween) -> finish()})));
    }

    public function finish() {
        if (onSubComplete != null) onSubComplete();
        manager.onSubtitleComplete(this);
    }

    function init(properties:SubtitleProperties):SubtitleProperties {
        if (properties == null) properties = {};
        
        if (properties.x == null) properties.x = FlxG.width / 2;
        if (properties.y == null) properties.y = (FlxG.height / 2) - 200;
        if (properties.subtitleSize == null) properties.subtitleSize = 36;
        if (properties.typeSpeed == null) properties.typeSpeed = .02;
        if (properties.centerScreen == null) properties.centerScreen = true;
        if (properties.screenCenter == null) properties.screenCenter = flixel.util.FlxAxes.XY;
        if (properties.fonts == null) properties.fonts = Paths.font("comic.ttf");
        return properties;
    }
}