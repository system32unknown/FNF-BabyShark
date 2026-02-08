package funkin.states.stages;

class BambiFarm extends BaseStage {
	override function create() {
		var variousMode:String = 'day';
		if (PlayState.curStage.endsWith('-night')) variousMode = 'night';
		else if (PlayState.curStage.endsWith('-sunset')) variousMode = 'sunset';

		add(new BGSprite('skys/$variousMode', -600, -200, .6, .6));

		var flatgrass:BGSprite = new BGSprite('farm/gm_flatgrass', 350, 75, .65, .65);
		flatgrass.setGraphicSize(Std.int(flatgrass.width * .34));
		flatgrass.updateHitbox();
		add(flatgrass);

		var hills:BGSprite;
		add(hills = new BGSprite('farm/orangey hills', -173, 100, .65, .65));

		var farmHouse:BGSprite = new BGSprite('farm/funfarmhouse', 100, 125, .7, .7);
		farmHouse.setGraphicSize(Std.int(farmHouse.width * .9));
		farmHouse.updateHitbox();
		add(farmHouse);

		var grassLand:BGSprite;
		add(grassLand = new BGSprite('farm/grass lands', -600, 500));

		var cornFence:BGSprite;
		add(cornFence = new BGSprite('farm/cornFence', -400, 200));

		var cornFence2:BGSprite;
		add(cornFence2 = new BGSprite('farm/cornFence2', 1100, 200));

		var cornBag:BGSprite;
		add(cornBag = new BGSprite('farm/cornbag', 1200, 550));

		var sign:BGSprite;
		add(sign = new BGSprite('farm/sign', 0, 350));

		var variantColor:FlxColor = getBackgroundColor(variousMode);
		flatgrass.color = variantColor;
		hills.color = variantColor;
		farmHouse.color = variantColor;
		grassLand.color = variantColor;
		cornFence.color = variantColor;
		cornFence2.color = variantColor;
		cornBag.color = variantColor;
		sign.color = variantColor;
	}

	function getBackgroundColor(type:String):FlxColor {
		return switch (type) {
			case 'night': 0xFF878787;
			case 'sunset': FlxColor.fromRGB(255, 143, 178);
			default: FlxColor.WHITE;
		}
	}
}