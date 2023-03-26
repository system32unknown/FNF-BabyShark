package game.subtitles;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.addons.text.FlxTypeText;

typedef SubtitleProperties = {
	var ?x:Float;
	var ?y:Float;
	var ?subtitleSize:Int;
	var ?typeSpeed:Float;
	var ?centerScreen:Bool;
	var ?screenCenter:FlxAxes;
	var ?sounds:Array<FlxSound>;
    var ?fonts:String;
}

class Subtitle extends FlxTypeText {
	public var manager:SubtitleManager;
	public var onSubComplete:Void->Void;

	public function new(text:String, ?typeSpeed, showTime:Float, properties:SubtitleProperties, onComplete:Void->Void) {
		properties = init(properties);

		super(properties.x, properties.y, FlxG.width, text, properties.subtitleSize);
		sounds = properties.sounds;
		onSubComplete = onComplete;

		setFormat(properties.fonts, properties.subtitleSize, FlxColor.WHITE, FlxTextAlign.CENTER);
        setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2);

		antialiasing = true;

		if (properties.centerScreen) {
			screenCenter(properties.screenCenter);
		}

		start(properties.typeSpeed, false, false, [], function() {
			new FlxTimer().start(showTime, function(timer:FlxTimer) {
				FlxTween.tween(this, {alpha: 0}, 0.5, {
					onComplete: function(tween:FlxTween) {
						finish();
					}
				});
			});
		});
	}

	public function finish() {
		if (onSubComplete != null) {
			onSubComplete();
		}

        manager.onSubtitleComplete(this);
	}

	function init(properties:SubtitleProperties):SubtitleProperties {
		if (properties == null)
			properties = {};

		if (properties.x == null)
			properties.x = FlxG.width / 2;
		if (properties.y == null)
			properties.y = (FlxG.height / 2) - 200;
		if (properties.subtitleSize == null)
			properties.subtitleSize = 36;
		if (properties.typeSpeed == null)
			properties.typeSpeed = 0.02;
		if (properties.centerScreen == null)
			properties.centerScreen = true;
		if (properties.screenCenter == null)
			properties.screenCenter = FlxAxes.XY;
		if (properties.sounds == null)
			properties.sounds = null;
		return properties;
	}
}
