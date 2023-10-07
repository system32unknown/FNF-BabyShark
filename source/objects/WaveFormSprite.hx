package objects;

import haxe.io.Bytes;
import openfl.geom.Rectangle;
import lime.media.AudioBuffer;

class WaveFormSprite extends FlxSprite {
    public var buffer:AudioBuffer;
    public var data:Bytes;

    public function new(x:Float, y:Float, audioPath:String, width:Int, height:Int) {
        super(x, y);

        var path = audioPath.replace("songs:", "");
        buffer = AudioBuffer.fromFile(path);

        makeGraphic(width, height, FlxColor.TRANSPARENT);
        data = buffer.data.toBytes();
    }

    public function drawWaveform() {
		var index:Int = 0;
		var drawIndex:Int = 0;
		var samplesPerCollumn:Int = 600;

		var min:Float = 0;
		var max:Float = 0;

        while ((index * 4) < (data.length - 1)) {
			var byte:Int = data.getUInt16(index * 4);
			if (byte > 65535 / 2) byte -= 65535;

			var sample:Float = (byte / 65535);
			if (sample > 0 && sample > max) max = sample;
			else if (sample < 0 && sample < min) min = sample;

            if ((index % samplesPerCollumn) == 0) {
				if (drawIndex > 350)
					drawIndex = 0;
				var pixelsMin:Float = Math.abs(min * 300);
				var pixelsMax:Float = max * 300;
				pixels.fillRect(new Rectangle(drawIndex, x, 1, height), 0xFF000000);
				pixels.fillRect(new Rectangle(drawIndex, y - pixelsMin, 1, pixelsMin + pixelsMax), FlxColor.WHITE);
				drawIndex += 1;
				min = 0;
				max = 0;
			}
			index += 1;
		}
    }
}