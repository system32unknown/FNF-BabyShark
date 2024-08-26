package backend;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import openfl.utils.ByteArray;
import openfl.media.Sound;

class BeatByte {
    public static function make(secs:Int, byteBeat:(i:Int)->Int):Bytes {
        var output:BytesOutput = new BytesOutput();

        // Write RIFF header
        output.writeString("RIFF");
        output.writeInt32(0); // Placeholder for chunk size
        output.writeString("WAVE");

        // Write fmt chunk
        output.writeString("fmt ");
        output.writeInt32(16); // Chunk size
        output.writeInt16(1); // Audio format (PCM)

        var channels:Int = 1;
        var sampleRate:Int = 8000;
        var bitsPerSample:Int = 8;

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

    public static function getSound(b:Bytes):FlxSound {
        var bArray:ByteArray = ByteArray.fromBytes(b);
        var tmpSound:Sound = new Sound();
        tmpSound.loadCompressedDataFromByteArray(bArray, bArray.length);
        var tmpFlxSnd:FlxSound = new FlxSound();
        tmpFlxSnd.loadEmbedded(tmpSound);
        return tmpFlxSnd;
    }
}