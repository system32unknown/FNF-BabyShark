package substates;

import utils.Controls;
import utils.ClientPrefs;
import utils.PlayerSettings;
import game.Conductor;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import openfl.geom.Rectangle;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;

class MusicBeatSubstate extends FlxSubState
{
	private var curStep:Int = 0;
	private var controls(get, never):Controls;

	private var cSize:Int = 10;

	inline function get_controls():Controls
		return PlayerSettings.player.controls;

	public function new()
	{
		super();
	}

	override function update(elapsed:Float)
	{
		var oldStep:Int = curStep;

		updateCurStep();

		if (oldStep != curStep && curStep > 0)
			stepHit();

		super.update(elapsed);
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.getPref('noteOffset')) - lastChange.songTime) / lastChange.stepCrochet;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}

	public function doMessage(text:String, duration:Float = 5) {
		var txt:FlxText = new FlxText(FlxG.width / 2, 10, 0, text + '\n', 16); // i hate flx text
		txt.cameras = [FlxG.camera];
		txt.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		var panel = new FlxSprite(0, 0);
		makeSelectorG(panel, Std.int(txt.width) + 15, Std.int(txt.height - 24) + 15, 0xFF000000);
		panel.cameras = [FlxG.camera];

		var panelbg:FlxSprite = new FlxSprite(5, 5);
		makeSelectorG(panelbg, Std.int(txt.width) + 5, Std.int(txt.height - 24) + 5, 0xFF302E2E);
		panelbg.cameras = [FlxG.camera];

		txt.screenCenter(X);
		panel.screenCenter(X);
		panelbg.screenCenter(X);
		txt.y = -txt.height;
		panel.y = -panel.height;
		panelbg.y = -panelbg.height;

		add(panel);
		add(panelbg);
		add(txt);

		FlxTween.tween(panel, {y: 10}, 0.5);
		FlxTween.tween(panelbg, {y: 15}, 0.5);
		FlxTween.tween(txt, {y: 20}, 0.5, {
			onComplete: function(twn:FlxTween) {
				new FlxTimer().start(duration, function(tmr:FlxTimer) {
					FlxTween.tween(panel, {y: -panel.height}, 0.5);
					FlxTween.tween(panelbg, {y: -panelbg.height - 5}, 0.5);
					FlxTween.tween(txt, {y: -txt.height - 10}, 0.5, {
						onComplete: function(twn:FlxTween) {
							remove(panel);
							remove(panelbg);
							remove(txt);
						}
					});
				});
			}
		});
	}

	function makeSelectorG(panel:FlxSprite, w, h, color:FlxColor) {
		panel.makeGraphic(w, h, color);
		panel.pixels.fillRect(new Rectangle(0, 190, panel.width, 5), 0x0);

		panel.pixels.fillRect(new Rectangle(0, 0, cSize, cSize), 0x0);														 //top left
		drawCircleCorner(panel,false, false,color);
		panel.pixels.fillRect(new Rectangle(panel.width - cSize, 0, cSize, cSize), 0x0);							 //top right
		drawCircleCorner(panel,true, false,color);
		panel.pixels.fillRect(new Rectangle(0, panel.height - cSize, cSize, cSize), 0x0);							 //bottom left
		drawCircleCorner(panel,false, true,color);
		panel.pixels.fillRect(new Rectangle(panel.width - cSize, panel.height - cSize, cSize, cSize), 0x0); //bottom right
		drawCircleCorner(panel,true, true,color);
	}

	function drawCircleCorner(panel:FlxSprite, flipX:Bool, flipY:Bool, color:FlxColor) {
		var antiX:Float = (panel.width - cSize);
		var antiY:Float = flipY ? (panel.height - 1) : 0;
		if(flipY) antiY -= 2;
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 1), Std.int(Math.abs(antiY - 8)), 10, 3), color);
		if(flipY) antiY += 1;
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 2), Std.int(Math.abs(antiY - 6)),  9, 2), color);
		if(flipY) antiY += 1;
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 3), Std.int(Math.abs(antiY - 5)),  8, 1), color);
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 4), Std.int(Math.abs(antiY - 4)),  7, 1), color);
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 5), Std.int(Math.abs(antiY - 3)),  6, 1), color);
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 6), Std.int(Math.abs(antiY - 2)),  5, 1), color);
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 8), Std.int(Math.abs(antiY - 1)),  3, 1), color);
	}
}
