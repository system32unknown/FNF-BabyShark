package objects;

/**
 * Text displayed in loading screens.
 * After a short amount of time, dots are added or removed from the text.
 * @author Sword352
 */
class LoadingText extends FlxText {
	/**
	 * Base text to be displayed.
	 */
	var _baseText:String;

	/**
	 * Number of appended dots.
	 */
	var _dots:Int = 1;

	/**
	 * Number of maxed dots.
	 */
	public var maxDots:Int = 3;

	/**
	 * Elapsed time since the last dot change.
	 */
	var _elapsedTime:Float;

	/**
	 * Caches the size of the text to avoid regenerating the bitmap when a dot is added or removed.
	 */
	public function cacheSize():Void {
		var currentText:String = text;

		var cacheTxt:String = _baseText;
		for (i in 0...maxDots) cacheTxt += ".";
		_setText(cacheTxt + "..");

		fieldWidth = textField.width;
		fieldHeight = textField.height;
		_setText(currentText);
	}

	override function update(elapsed:Float):Void {
		_elapsedTime += elapsed;
		if (_elapsedTime < .3) return;

		_dots++;

		if (_dots > maxDots) {
			_setText(_baseText);
			_dots = 1;
		} else {
			var text:String = _baseText;
			for (i in 0..._dots - 1) text += ".";
			_setText(text);
		}

		_elapsedTime = 0;
	}

	function _setText(text:String):Void {
		super.set_text(text);
	}

	override function set_text(text:String):String {
		_dots = 1;
		_baseText = text + ".";
		super.set_text(_baseText);
		return text;
	}
}