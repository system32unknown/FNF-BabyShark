package backend;

class Wife3 {
	static final erfs:Array<Float> = [.254829592, -.284496736, 1.421413741, 1.453152027, 1.061405429];
	static final p:Float = .3275911;
	static function erf(x:Float):Float {
		var sign:Int = (x < 0 ? -1 : 1);
		x = Math.abs(x);

		var t:Float = 1 / (1 + p * x);
		var y:Float = 1 - (((((erfs[4] * t + erfs[3]) * t) + erfs[2]) * t + erfs[1]) * t + erfs[0]) * t * Math.exp(-x * x);
		return sign * y;
	}

	public static var max_points = 1.;
	public static var miss_weight = -5.5;
	public static var ts_pow = .75;
	public static var shit_weight:Float = 200;

	public static function getAcc(noteDiff:Float):Float {
		var ts:Float = PlayState.instance.playbackRate;

		var ridic:Float = 5 * ts;
		var zero:Float = 65 * Math.pow(ts, ts_pow);
		var dev:Float = 22.7 * Math.pow(ts, ts_pow);

		if(noteDiff <= ridic) return max_points;
		else if(noteDiff <= zero) return max_points * erf((zero - noteDiff) / dev);
		else if(noteDiff <= shit_weight) return (noteDiff - zero) * miss_weight / (shit_weight - zero);
		
		return miss_weight;
	}
}