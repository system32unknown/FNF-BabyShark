package objects;

import shaders.ColorSwap;

class StrumNote extends FlxSprite
{
	private var colorSwap:ColorSwap;

	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;
	
	public var animationArray:Array<String> = ['static', 'pressed', 'confirm'];
	public var static_anim(default, set):String = "static";
	public var pressed_anim(default, set):String = "pressed"; // in case you would use this on lua
	public var confirm_anim(default, set):String = "confirm";

	function set_static_anim(value:String):String {
		if (!PlayState.isPixelStage) {
			animation.addByPrefix('static', value);
			animationArray[0] = value;
			if (animation.curAnim != null && animation.curAnim.name == 'static') {
				playAnim('static');
			}
		}
		return value;
	}

	function set_pressed_anim(value:String):String {
		if (!PlayState.isPixelStage) {
			animation.addByPrefix('pressed', value);
			animationArray[1] = value;
			if (animation.curAnim != null && animation.curAnim.name == 'pressed') {
				playAnim('pressed');
			}
		}
		return value;
	}

	function set_confirm_anim(value:String):String {
		if (!PlayState.isPixelStage) {
			animation.addByPrefix('confirm', value);
			animationArray[2] = value;
			if (animation.curAnim != null && animation.curAnim.name == 'confirm') {
				playAnim('confirm');
			}
		}
		return value;
	}

	public var player:Int;
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public function new(x:Float, y:Float, leData:Int, player:Int) {
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;
		noteData = leData;
		this.player = player;
		this.noteData = leData;
		super(x, y);

		animationArray[0] = Note.keysShit.get(PlayState.mania).get('strumAnims')[leData];
		animationArray[1] = animationArray[2] = Note.keysShit.get(PlayState.mania).get('letters')[leData];

		var skin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		else skin = Note.defaultNoteSkin;

		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

		texture = skin; //Load texture and anims
		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		var pxDV:Int = Note.pixelNotesDivisionValue;

		if(PlayState.isPixelStage) {
			loadGraphic(Paths.image('pixelUI/' + texture));
			width /= pxDV;
			height /= 5;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));
			antialiasing = false;
			var daFrames:Array<Int> = Note.keysShit.get(PlayState.mania).get('pixelAnimIndex');

			setGraphicSize(Std.int(width * PlayState.daPixelZoom * Note.pixelScales[PlayState.mania]));
			updateHitbox();
			antialiasing = false;
			animation.add('static', [daFrames[noteData]]);
			animation.add('pressed', [daFrames[noteData] + pxDV, daFrames[noteData] + (pxDV * 2)], 12, false);
			animation.add('confirm', [daFrames[noteData] + (pxDV * 3), daFrames[noteData] + (pxDV * 4)], 24, false);
		} else {
			frames = Paths.getSparrowAtlas(texture);
			antialiasing = ClientPrefs.getPref('Antialiasing');
			setGraphicSize(Std.int(width * Note.scales[PlayState.mania]));
	
			animation.addByPrefix('static', 'arrow' + animationArray[0]);
			animation.addByPrefix('pressed', animationArray[1] + ' press', 24, false);
			animation.addByPrefix('confirm', animationArray[2] + ' confirm', 24, false);
		}
		updateHitbox();

		if(lastAnim != null) {
			playAnim(lastAnim, true);
		}
	}

	public function postAddedToGroup() {
		playAnim('static');

		switch (PlayState.mania) {
			case 0 | 1 | 2: x += width * noteData;
			case 3: x += (Note.swagWidth * noteData);
			default: x += ((width - Note.lessX[PlayState.mania]) * noteData);
		}

		x += Note.xtra[PlayState.mania];

		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
		x -= Note.posRest[PlayState.mania];
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		var arrowHSV:Array<Array<Int>> = ClientPrefs.getPref('arrowHSV');
		var arrowIndex:Int = Std.int(Note.keysShit.get(PlayState.mania).get('pixelAnimIndex')[noteData] % Note.ammo[PlayState.mania]);
		if(animation.curAnim == null || animation.curAnim.name == 'static') {
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		} else {
			if (noteData > -1 && noteData < arrowHSV.length) {
				colorSwap.hue = arrowHSV[arrowIndex][0] / 360;
				colorSwap.saturation = arrowHSV[arrowIndex][1] / 100;
				colorSwap.brightness = arrowHSV[arrowIndex][2] / 100;
			}

			if (!PlayState.isPixelStage) return;
			if(animation.curAnim.name == 'confirm') {
				centerOrigin();
			}
		}
	}

	override function destroy() {
		shader = null;
		colorSwap = null;
		super.destroy();
	}
}