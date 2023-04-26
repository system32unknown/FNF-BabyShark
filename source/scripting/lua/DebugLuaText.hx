package scripting.lua;

import flixel.group.FlxGroup.FlxTypedGroup;

class DebugLuaText extends FlxText {
	var disableTime:Float = 6;
	public var parentGroup:FlxTypedGroup<DebugLuaText>;
	public function new(text:String, parentGroup:FlxTypedGroup<DebugLuaText>, color:FlxColor) {
		this.parentGroup = parentGroup;
		super(10, 10, 0, text, 16);
		setFormat(Paths.font("vcr.ttf"), 16, color, LEFT);
		setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1);
		scrollFactor.set();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		disableTime -= elapsed;
		if(disableTime < 0) disableTime = 0;
		if(disableTime < 1) alpha = disableTime;
	}
}