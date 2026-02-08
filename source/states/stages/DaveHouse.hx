package states.stages;

class DaveHouse extends BaseStage {
	override function create() {
		var variousMode:String = 'day';
		if (PlayState.curStage.endsWith('-night')) variousMode = 'night';
		else if (PlayState.curStage.endsWith('-sunset')) variousMode = 'sunset';

		var assetType:String = (variousMode == 'day' || variousMode == 'sunset' ? '' : 'night/');

		add(new BGSprite('skys/$variousMode', -600, -300, .6, .6));

		var hills:BGSprite;
		add(hills = new BGSprite('house/${assetType}hills', -834, -159, .7, .7));

		var grassbg:BGSprite;
		add(grassbg = new BGSprite('house/${assetType}grass bg', -1205, 580));

		var gate:BGSprite;
		add(gate = new BGSprite('house/${assetType}gate', -755, 250));

		var grass:BGSprite;
		add(grass = new BGSprite('house/${assetType}grass', -832, 505));

		var variantColor:FlxColor = getBackgroundColor(variousMode);
		if (variousMode != 'night') {
			hills.color = variantColor;
			grassbg.color = variantColor;
			gate.color = variantColor;
			grass.color = variantColor;
		}
	}

	function getBackgroundColor(type:String):FlxColor {
		return switch (type) {
			case 'night': 0xFF878787;
			case 'sunset': FlxColor.fromRGB(255, 143, 178);
			default: FlxColor.WHITE;
		}
	}
}