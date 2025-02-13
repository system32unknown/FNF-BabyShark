package backend;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import openfl.media.Sound;

class BeatByte {
    public var channels:Int;
    public var sampleRate:Int;
    public var bitsPerSample:Int;

    var output:BytesOutput;

    public function new(?channels:Int = 1, ?sampleRate:Int = 8000, ?bitsPerSample:Int = 8) {
        this.channels = channels;
        this.sampleRate = sampleRate;
        this.bitsPerSample = bitsPerSample;
    }

    public function make(secs:Int, byteBeat:(i:Int) -> Int):Bytes {
        output = new BytesOutput();

        // Write RIFF header
        output.writeString("RIFF");
        output.writeInt32(0); // Placeholder for chunk size
        output.writeString("WAVE");

        // Write fmt chunk
        output.writeString("fmt ");
        output.writeInt32(16); // Chunk size
        output.writeInt16(1); // Audio format (PCM)

        output.writeInt16(channels);
        output.writeInt32(sampleRate);
        output.writeInt32(Std.int(sampleRate * channels * bitsPerSample / 8)); // Byte rate
        output.writeInt16(Std.int(channels * bitsPerSample / 8)); // Block align
        output.writeInt16(bitsPerSample);

        // Write data chunk
        output.writeString("data");

        var data:Bytes = Bytes.alloc(sampleRate * secs);
        for (t in 0...data.length) data.set(t, Std.int(byteBeat(t)) & 0xFF);

        output.writeInt32(data.length * channels * Std.int(bitsPerSample / 8));
        output.writeBytes(data, 0, data.length);

        // Update chunk size
        var totalSize:Int = output.length;
        var bytes:Bytes = output.getBytes();
        bytes.setInt32(4, totalSize - 8);

        return bytes;
    }

    public function getSound(b:Null<Bytes>):FlxSound {
        var tmpSound:Sound = new Sound();
        tmpSound.loadCompressedDataFromByteArray(openfl.utils.ByteArray.fromBytes(b), b.length);
        return new FlxSound().loadEmbedded(tmpSound);
    }

    public function toString():String {
        return '(Channels: $channels | SampleRate: $sampleRate | BitsPerSample: $bitsPerSample)';
    }

    public function dispose():Void {
        output.close();
        output = null;
    }
}