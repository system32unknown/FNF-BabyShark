package objects;

import openfl.geom.Rectangle;
import openfl.media.Sound;
import lime.media.AudioBuffer;

/**
    * A Sprite that represents waveform.
    * @author YoshiCrafter
*/
class WaveformSprite extends FlxSprite {
    var buffer:AudioBuffer;
    var sound:Sound;
    var peak:Float = 0;
    var valid:Bool = true;

    public override function destroy() {
        super.destroy();
        if (buffer != null) {
            buffer.data.buffer = null;
            buffer.dispose();
        }
    }

    public function new(x:Float, y:Float, buffer:Dynamic, w:Int, h:Int) @:privateAccess {
        super(x, y);
        this.buffer = null;
        if (Std.isOfType(buffer, FlxSound)) {
            this.sound = cast(buffer, FlxSound)._sound;
            this.buffer = this.sound.__buffer;
        } else if (Std.isOfType(buffer, Sound)) {
            this.sound = cast(buffer, Sound);
            this.buffer = this.sound.__buffer;
        } else if (Std.isOfType(buffer, AudioBuffer)) {
            this.buffer = cast(buffer, AudioBuffer);
        } else {
            valid = false;
            return;
        }
        peak = Math.pow(2, buffer.bitsPerSample - 1) - 1; // max positive value of a bitsPerSample bits integer
        makeGraphic(w, h, 0x00000000, true); // transparent
    }

    public function generate(startPos:Int, endPos:Int) {
        if (!valid) return;
        startPos -= startPos % buffer.bitsPerSample;
        endPos -= endPos % buffer.bitsPerSample;
        pixels.lock();
        pixels.fillRect(new Rectangle(0, 0, pixels.width, pixels.height), 0); 
        var diff = endPos - startPos;
        var diffRange = Math.floor(diff / pixels.height);
        for(y in 0...pixels.height) {
            var d = Math.floor(diff * (y / pixels.height));
            d -= d % buffer.bitsPerSample;
            var pos = startPos + d;
            var max:Int = 0;
            for(i in 0...Math.floor(diffRange / buffer.bitsPerSample)) {
                var thing = buffer.data.buffer.get(pos + (i * buffer.bitsPerSample)) | (buffer.data.buffer.get(pos + (i * buffer.bitsPerSample) + 1) << 8);
                if (thing > 256 * 128) thing -= 256 * 256;
                if (max < thing) max = thing;
            }
            var thing = max;
            var w = thing / peak * pixels.width;
            pixels.fillRect(new Rectangle((pixels.width / 2) - (w / 2), y, w, 1), 0xFFFFFFFF);
        }
        pixels.unlock();
    }

    public function generateFlixel(startPos:Float, endPos:Float) {
        if (!valid) return;
        var rateFrequency = (1 / buffer.sampleRate);
        var multiplicator = 1 / rateFrequency; // 1 hz/s
        multiplicator *= buffer.bitsPerSample;
        multiplicator -= multiplicator % buffer.bitsPerSample;

        generate(Math.floor(startPos * multiplicator / 4000 / buffer.bitsPerSample) * buffer.bitsPerSample, Math.floor(endPos * multiplicator / 4000 / buffer.bitsPerSample) * buffer.bitsPerSample);
    }

    public function getNumberFromBuffer(pos:Int, bytes:Int):Int {
        var am = 0;
        for(i in 0...bytes) {
            var val = buffer.data.buffer.get(pos + i);
            if (val < 0) val += 256;
            for(_ in 0...(bytes - i)) val *= 256;
            am += val;
        }
        return am;
    }
}