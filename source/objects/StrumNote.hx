package objects;

import shaders.ColorSwap;

class StrumNote extends FlxSprite {
	var colorSwap:ColorSwap;

	public var resetAnim:Float = 0;
	var noteData:Int = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;
	public var player:Int;
	public var animationArray:Array<String> = ['', ''];
	
	public var texture(default, set):String = null;
	function set_texture(value:String):String {
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
		animationArray[1] = Note.keysShit.get(PlayState.mania).get('letters')[leData];

		var skin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		else skin = Note.defaultNoteSkin;

		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

		texture = skin; //Load texture and anims
		scrollFactor.set();
	}

	public function reloadNote() {
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		var pxDV:Int = Note.pixelNotesDivisionValue;

		if(PlayState.isPixelStage) {
			loadGraphic(Paths.image('pixelUI/$texture'));
			width /= pxDV;
			height /= 5;
			loadGraphic(Paths.image('pixelUI/$texture'), true, Math.floor(width), Math.floor(height));
			antialiasing = false;
			var daFrames:Array<Int> = Note.keysShit.get(PlayState.mania).get('pixelAnimIndex');

			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			updateHitbox();
			antialiasing = false;
			animation.add('static', [daFrames[noteData]]);
			animation.add('pressed', [daFrames[noteData] + pxDV, daFrames[noteData] + (pxDV * 2)], 12, false);
			animation.add('confirm', [daFrames[noteData] + (pxDV * 3), daFrames[noteData] + (pxDV * 4)], 24, false);
		} else {
			frames = Paths.getSparrowAtlas(texture);
			antialiasing = ClientPrefs.getPref('Antialiasing');
			setGraphicSize(Std.int(width * EK.scales[PlayState.mania]));
	
			animation.addByPrefix('static', 'arrow${animationArray[0]}');
			animation.addByPrefix('pressed', '${animationArray[1]} press', 24, false);
			animation.addByPrefix('confirm', '${animationArray[1]} confirm', 24, false);
		}
		updateHitbox();

		if(lastAnim != null) playAnim(lastAnim, true);
	}

	public function postAddedToGroup() {
		playAnim('static');

		x += (Note.swagWidth * EK.scales[PlayState.mania]) * noteData;
		x += EK.offsetX[PlayState.mania];
		x -= (EK.restPosition[PlayState.mania]) * noteData;

		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
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
		if(animation.curAnim != null) {
			centerOffsets();
			centerOrigin();
		}
		var arrowHSV:Array<Array<Int>> = ClientPrefs.getPref('arrowHSV');
		var arrowIndex:Int = Std.int(Note.keysShit.get(PlayState.mania).get('pixelAnimIndex')[noteData] % EK.keys(PlayState.mania));
		if(animation.curAnim == null || animation.curAnim.name == 'static')
			colorSwap.setHSB(0, 0, 0);
		else {
			if (noteData > -1 && noteData < arrowHSV.length)
				colorSwap.setHSB(arrowHSV[arrowIndex][0] / 360, arrowHSV[arrowIndex][1] / 100, arrowHSV[arrowIndex][2] / 100);

			if (!PlayState.isPixelStage) return;
			if(animation.curAnim.name == 'confirm') centerOrigin();
		}
	}

	override function destroy() {
		shader = null;
		colorSwap = null;
		super.destroy();
	}
}
