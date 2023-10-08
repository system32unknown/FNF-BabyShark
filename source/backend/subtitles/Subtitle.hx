package backend.subtitles;

import flixel.util.FlxAxes;
import flixel.addons.text.FlxTypeText;

class Subtitle extends FlxTypeText {
    public var manager:SubtitleManager;
    public var onSubComplete:Void->Void;
    public function new(text:String, ?typeSpeed, showTime:Float, properties:SubtitleProperties, onComplete:Void->Void) {
        properties = init(properties);

        super(properties.x, properties.y, FlxG.width, text, 36);
        sounds = properties.sounds;
        onSubComplete = onComplete;
        
        setFormat(Paths.font(properties.fonts), properties.subtitleSize, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        antialiasing = true;
        borderSize = 2;

        if (properties.centerScreen)
            screenCenter(properties.screenCenter);
        
        start(properties.typeSpeed, false, false, [], () -> new FlxTimer().start(showTime, (timer:FlxTimer) -> FlxTween.tween(this, {alpha: 0}, .5, {onComplete: (tween:FlxTween) -> finish()})));
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
        if (properties.screenCenter == null) properties.screenCenter = FlxAxes.XY;
        if (properties.sounds == null) properties.sounds = null;
        if (properties.fonts == null) properties.fonts = "Comic Sans MS Bold";
        return properties;
    }
}