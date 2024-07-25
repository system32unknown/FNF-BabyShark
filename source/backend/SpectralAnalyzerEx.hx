package backend;

import funkin.vis.dsp.SpectralAnalyzer;
import funkin.vis.dsp.RecentPeakFinder;
import lime.utils.UInt8Array;

using grig.audio.lime.UInt8ArrayTools;

class SpectralAnalyzerEx extends SpectralAnalyzer {
	var _levels:Array<Bar> = [];
	public function recycledLevels():Array<Bar> {
		var numOctets:Int = Std.int(audioSource.buffer.bitsPerSample / 8);
		var wantedLength:Int = fftN * numOctets * audioSource.buffer.channels;
		var startFrame:Int = audioClip.currentFrame;
		startFrame -= startFrame % numOctets;
		var segment:UInt8Array = audioSource.buffer.data.subarray(startFrame, min(startFrame + wantedLength, audioSource.buffer.data.length));
		var signal:Array<Float> = recycledInterleaved(segment, audioSource.buffer.bitsPerSample);

		if (audioSource.buffer.channels > 1) {
			var mixed:Array<Float> = [];
			mixed.resize(Std.int(signal.length / audioSource.buffer.channels));
			for (i in 0...mixed.length) {
				mixed[i] = 0.0;
				for (c in 0...audioSource.buffer.channels)
					mixed[i] += 0.7 * signal[i * audioSource.buffer.channels + c];

				mixed[i] *= blackmanWindow[i];
			}
			signal = mixed;
		}

		var range:Int = 16;
		var freqs:Array<Float> = fft.calcFreq(signal);
		var bars:Array<Int> = vis.makeLogGraph(freqs, barCount, Math.floor(maxDb - minDb), range);

		if (bars.length > barHistories.length) barHistories.resize(bars.length);

		_levels.resize(bars.length);
		for (i in 0...bars.length) {
			if (barHistories[i] == null) {
				barHistories[i] = new RecentPeakFinder();
				trace('created barHistories[$i]');
			}
			var recentValues:RecentPeakFinder = barHistories[i];
			var value:Float = bars[i] / range;

			// slew limiting
			var lastValue:Float = recentValues.lastValue;
			if (maxDelta > 0.0) {
				var delta:Float = clamp(value - lastValue, -1 * maxDelta, maxDelta);
				value = lastValue + delta;
			}
			recentValues.push(value);

			var recentPeak:Float = recentValues.peak;
			if(_levels[i] != null) {
				_levels[i].value = value;
				_levels[i].peak = recentPeak;
			} else _levels[i] = {value: value, peak: recentPeak};
		}
		return _levels;
	}

	var _buffer:Array<Float> = [];
	function recycledInterleaved(data:UInt8Array, bitsPerSample:Int):Array<Float> {
		switch(bitsPerSample) {
			case 8:
				_buffer.resize(data.length);
				for (i in 0...data.length) _buffer[i] = data[i] / 128.0;

			case 16:
				_buffer.resize(Std.int(data.length / 2));
				for (i in 0..._buffer.length) _buffer[i] = data.getInt16(i * 2) / 32767.0;

			case 24:
				_buffer.resize(Std.int(data.length / 3));
				for (i in 0..._buffer.length) _buffer[i] = data.getInt24(i * 3) / 8388607.0;

			case 32:
				_buffer.resize(Std.int(data.length / 4));
				for (i in 0..._buffer.length) _buffer[i] = data.getInt32(i * 4) / 2147483647.0;

			default: trace('Unknown integer audio format');
		}
		return _buffer;
	}

	@:generic
	static inline function min<T:Float>(x:T, y:T):T {
		return x > y ? y : x;
	}
	
	@:generic
	static inline function clamp<T:Float>(val:T, min:T, max:T):T {
		return val <= min ? min : val >= max ? max : val;
	}
}