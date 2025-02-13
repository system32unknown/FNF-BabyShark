package backend;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import openfl.media.Sound;

class BeatByte {
    /**
     * Number of audio channels (1 = mono, 2 = stereo).
     */
    public var channels:Int;
    /**
     * The number of samples per second (default is 8000 Hz).
     */
    public var sampleRate:Int;
    /**
     * Bit depth of each sample (default is 8-bit).
     */
    public var bitsPerSample:Int;

    public var byteRate(get, never):Int;
    @:noCompletion public function get_byteRate():Int {
        return Std.int(sampleRate * channels * bitsPerSample / 8);
    }
    public var blockAlign(get, never):Int;
    @:noCompletion public function get_blockAlign():Int {
        return Std.int(channels * bitsPerSample / 8);
    }
    public var length(get, never):Float;
    @:noCompletion public function get_length():Float {
        var numSamples:Float = totalSize / (bitsPerSample / 8 * channels);
        return numSamples / sampleRate;
    }

    public var totalSize:Int;
    var output:BytesOutput;

    /**
     * Initializes the object with audio settings.
     @param   channels Number of audio channels (1 = mono, 2 = stereo).
     @param   sampleRate The number of samples per second (default is 8000 Hz).
     @param   bitsPerSample Bit depth of each sample (default is 8-bit).
     */
    public function new(?channels:Int = 1, ?sampleRate:Int = 8000, ?bitsPerSample:Int = 8) {
        this.channels = channels;
        this.sampleRate = sampleRate;
        this.bitsPerSample = bitsPerSample;
    }

    /**
     * Generates a bytebeat-style WAV audio file.
     */
    public function make(secs:Int, byteBeat:(i:Int) -> Int):Bytes {
        output = new BytesOutput();

        // Write RIFF header
        output.writeString("RIFF");
        output.writeInt32(0); // Placeholder for chunk size
        output.writeString("WAVEfmt "); // Write fmt chunk
        output.writeInt32(16); // Chunk size
        output.writeInt16(1); // Audio format (PCM)

        output.writeInt16(channels);
        output.writeInt32(sampleRate);
        output.writeInt32(byteRate); // Byte rate
        output.writeInt16(blockAlign); // Block align
        output.writeInt16(bitsPerSample);

        // Write data chunk
        output.writeString("data");

        var data:Bytes = Bytes.alloc(sampleRate * secs);
        for (t in 0...data.length) data.set(t, Std.int(byteBeat(t)) & 0xFF);

        output.writeInt32(data.length * channels * Std.int(bitsPerSample / 8));
        output.writeBytes(data, 0, data.length);

        // Update chunk size
        totalSize = output.length;
        var bytes:Bytes = output.getBytes();
        bytes.setInt32(4, totalSize - 8);

        return bytes;
    }

    /**
     * Converts raw byte data into a Flixel sound object (`FlxSound`).
     */
    public function toSound(b:Bytes):FlxSound {
        if (b == null) return null;

        var tmpSound:Sound = new Sound();
        tmpSound.loadCompressedDataFromByteArray(openfl.utils.ByteArray.fromBytes(b), b.length);
        return new FlxSound().loadEmbedded(tmpSound);
    }

    /**
     * Cleans up memory by closing the `BytesOutput` stream and setting it to `null`.
    */
    public function dispose():Void {
        output.close();
        output = null;
    }

    public function toString():String {
        return '(Channels: $channels | SampleRate: $sampleRate | BitsPerSample: $bitsPerSample | Length: $length)';
    }
}