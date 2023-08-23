package backend;

class EtternaFunctions {
	static var erfs:Array<Float> = [.254829592, -.284496736, 1.421413741, 1.453152027, 1.061405429, .3275911];
	static function erf(x:Float):Float {
		var sign = (x < 0 ? -1 : 1);
		x = Math.abs(x);

		var t = 1. / (1. + erfs[5] * x);
		var y = 1. - (((((erfs[4] * t + erfs[3]) * t) + erfs[2]) * t + erfs[1]) * t + erfs[0]) * t * Math.exp(-x * x);
		return sign * y;
	}

	public static function wife3(maxms:Float) {
		var ts = PlayState.instance.playbackRate;
		var max_points = 1.0;
		var miss_weight = -5.5;
		var ridic = 5 * ts;
		var max_boo_weight = PlayState.instance.ratingsData[0].hitWindow;
		var ts_pow = .75;
		var zero = 65 * Math.pow(ts, ts_pow);
		var dev = 22.7 * Math.pow(ts, ts_pow);

		if (maxms <= ridic) // anything below this (judge scaled) threshold is counted as full pts
			return max_points;
		else if (maxms <= zero) // ma/pa region, exponential
			return max_points * erf((zero - maxms) / dev);
		else if (maxms <= max_boo_weight) // cb region, linear
			return (maxms - zero) * miss_weight / (max_boo_weight - zero);
		else return miss_weight;
	}
}