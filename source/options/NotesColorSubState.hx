package options;

import flixel.input.keyboard.FlxKey;
import lime.system.Clipboard;
import objects.StrumNote;
import objects.Note;

import shaders.RGBPalette;

class NotesColorSubState extends FlxSubState {
	var onModeColumn:Bool = true;
	var curSelectedMode:Int = 0;
	var curSelectedNote:Int = 0;
	var onPixel:Bool = false;
	var dataArray:Array<Array<FlxColor>>;

	var hexTypeLine:FlxSprite;
	var hexTypeNum:Int = -1;
	var hexTypeVisibleTimer:Float = 0;

	var copyButton:FlxSprite;
	var pasteButton:FlxSprite;

	var colorGradient:FlxSprite;
	var colorGradientSelector:FlxSprite;
	var colorPalette:FlxSprite;
	var colorWheel:FlxSprite;
	var colorWheelSelector:FlxSprite;

	var alphabetR:Alphabet;
	var alphabetG:Alphabet;
	var alphabetB:Alphabet;
	var alphabetHex:Alphabet;

	var modeBG:FlxSprite;
	var notesBG:FlxSprite;

	// controller support
	var tipTxt:FlxText;

	public function new() {
		super();
		
		#if DISCORD_ALLOWED DiscordClient.changePresence("Note Colors Menu"); #end
		
		onPixel = PlayState.isPixelStage;
		var bg:FlxSprite = new FlxSprite(Paths.image('menuDesat'));
		bg.color = 0xFFEA71FD;
		bg.gameCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		var grid:flixel.addons.display.FlxBackdrop = CoolUtil.createBackDrop(80, 80, 160, 160, true, 0x33FFFFFF, 0x0);
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);

		modeBG = new FlxSprite(215, 85).makeGraphic(315, 115, FlxColor.BLACK);
		modeBG.visible = false;
		modeBG.alpha = 0.4;
		add(modeBG);

		notesBG = new FlxSprite(10, 190).makeGraphic(700, 100, FlxColor.BLACK);
		notesBG.visible = false;
		notesBG.alpha = 0.4;
		add(notesBG);

		add(modeNotes = new FlxTypedGroup<FlxSprite>());
		add(myNotes = new FlxTypedGroup<StrumNote>());

		var bg:FlxSprite = new FlxSprite(720).makeGraphic(FlxG.width - 720, FlxG.height, FlxColor.BLACK);
		bg.alpha = .25;
		add(bg);
		var bg:FlxSprite = new FlxSprite(750, 160).makeGraphic(FlxG.width - 780, 540, FlxColor.BLACK);
		bg.alpha = .25;
		add(bg);
		
		var text:Alphabet = new Alphabet(50, 86, 'CTRL', NORMAL);
		text.alignment = CENTER;
		text.updateScale(.4, .4);
		add(text);

		copyButton = new FlxSprite(760, 50, Paths.image('noteColorMenu/copy'));
		copyButton.alpha = 0.6;
		add(copyButton);

		pasteButton = new FlxSprite(1180, 50, Paths.image('noteColorMenu/paste'));
		pasteButton.alpha = 0.6;
		add(pasteButton);

		colorGradient = flixel.util.FlxGradient.createGradientFlxSprite(60, 360, [FlxColor.WHITE, FlxColor.BLACK]);
		colorGradient.setPosition(780, 200);
		add(colorGradient);

		colorGradientSelector = new FlxSprite(770, 200).makeGraphic(80, 10);
		colorGradientSelector.offset.y = 5;
		add(colorGradientSelector);

		colorPalette = new FlxSprite(820, 580, Paths.image('noteColorMenu/palette'));
		colorPalette.scale.set(20, 20);
		colorPalette.updateHitbox();
		colorPalette.antialiasing = false;
		add(colorPalette);
		
		colorWheel = new FlxSprite(860, 200, Paths.image('noteColorMenu/colorWheel'));
		colorWheel.setGraphicSize(360, 360);
		colorWheel.updateHitbox();
		add(colorWheel);

		colorWheelSelector = new flixel.addons.display.shapes.FlxShapeCircle(0, 0, 8, {thickness: 0}, FlxColor.WHITE);
		colorWheelSelector.offset.set(8, 8);
		colorWheelSelector.alpha = 0.6;
		add(colorWheelSelector);

		var txtX:Float = 980;
		var txtY:Float = 90;

		add(alphabetR = makeColorAlphabet(txtX - 100, txtY));
		add(alphabetG = makeColorAlphabet(txtX, txtY));
		add(alphabetB = makeColorAlphabet(txtX + 100, txtY));
		add(alphabetHex = makeColorAlphabet(txtX, txtY - 55));
		hexTypeLine = new FlxSprite(0, 20).makeGraphic(5, 62);
		hexTypeLine.visible = false;
		add(hexTypeLine);

		spawnNotes();
		updateNotes(true);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);

		var tipX:Int = 20;
		var tipY:Int = 660;
		var tip:FlxText = new FlxText(tipX, tipY, 0, Language.getPhrase('note_colors_tip', 'Press RESET to Reset the selected Note Part.'), 16);
		tip.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		tip.borderSize = 2;
		add(tip);

		tipTxt = new FlxText(tipX, tipY + 24, 0, '', 16);
		tipTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		tipTxt.borderSize = 2;
		add(tipTxt);
		tipTxt.text = Language.getPhrase('note_colors_hold_tip', 'Hold {1} + Press RESET key to fully reset the selected Note.', [Language.getPhrase('note_colors_shift', 'Shift')]);
		
		FlxG.mouse.visible = true;
	}

	var _storedColor:FlxColor;
	var holdingOnObj:FlxSprite;
	var allowedTypeKeys:Map<FlxKey, String> = [
		ZERO => '0', ONE => '1', TWO => '2', THREE => '3', FOUR => '4', FIVE => '5', SIX => '6', SEVEN => '7', EIGHT => '8', NINE => '9',
		NUMPADZERO => '0', NUMPADONE => '1', NUMPADTWO => '2', NUMPADTHREE => '3', NUMPADFOUR => '4', NUMPADFIVE => '5', NUMPADSIX => '6',
		NUMPADSEVEN => '7', NUMPADEIGHT => '8', NUMPADNINE => '9', A => 'A', B => 'B', C => 'C', D => 'D', E => 'E', F => 'F'];

	override function update(elapsed:Float) {
		if (Controls.justPressed('back')) {
			FlxG.mouse.visible = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
			return;
		}

		super.update(elapsed);

		if (FlxG.keys.justPressed.CONTROL) {
			onPixel = !onPixel;
			spawnNotes();
			updateNotes(true);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		}

		if (hexTypeNum > -1) {
			var keyPressed:FlxKey = cast (FlxG.keys.firstJustPressed(), FlxKey);
			hexTypeVisibleTimer += elapsed;
			var changed:Bool = false;
			if (changed = FlxG.keys.justPressed.LEFT)
				hexTypeNum--;
			else if (changed = FlxG.keys.justPressed.RIGHT)
				hexTypeNum++;
			else if (allowedTypeKeys.exists(keyPressed)) {
				var curColor:String = alphabetHex.text;
				var newColor:String = curColor.substring(0, hexTypeNum) + allowedTypeKeys.get(keyPressed) + curColor.substring(hexTypeNum + 1);

				var colorHex:FlxColor = FlxColor.fromString('#' + newColor);
				setShaderColor(colorHex);
				_storedColor = getShaderColor();
				updateColors();
				
				// move you to next letter
				hexTypeNum++;
				changed = true;
			} else if (FlxG.keys.justPressed.ENTER) hexTypeNum = -1;
			
			var end:Bool = false;
			if (changed) {
				if (hexTypeNum > 5) { //Typed last letter
					hexTypeNum = -1;
					end = true;
					hexTypeLine.visible = false;
				} else {
					if (hexTypeNum < 0) hexTypeNum = 0;
					else if (hexTypeNum > 5) hexTypeNum = 5;
					centerHexTypeLine();
					hexTypeLine.visible = true;
				}
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
			if (!end) hexTypeLine.visible = Math.floor(hexTypeVisibleTimer * 2) % 2 == 0;
		} else {
			var add:Int = 0;
			if (Controls.justPressed('ui_left')) add = -1;
			else if (Controls.justPressed('ui_right')) add = 1;

			if (Controls.justPressed('ui_up') || Controls.justPressed('ui_down')) {
				onModeColumn = !onModeColumn;
				modeBG.visible = onModeColumn;
				notesBG.visible = !onModeColumn;
			}
	
			if (add != 0) {
				if (onModeColumn) changeSelectionMode(add);
				else changeSelectionNote(add);
			}
			hexTypeLine.visible = false;
		}

		// Copy/Paste buttons
		var generalMoved:Bool = FlxG.mouse.justMoved;
		var generalPressed:Bool = FlxG.mouse.justPressed;
		if (generalMoved) {
			copyButton.alpha = .6;
			pasteButton.alpha = .6;
		}

		if (pointerOverlaps(copyButton)) {
			copyButton.alpha = 1;
			if (generalPressed) {
				Clipboard.text = getShaderColor().toHexString(false, false);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
				trace('copied: ' + Clipboard.text);
			}
			hexTypeNum = -1;
		} else if (pointerOverlaps(pasteButton)) {
			pasteButton.alpha = 1;
			if (generalPressed) {
				var formattedText:String = Clipboard.text.trim().toUpperCase().replace('#', '').replace('0x', '');
				var newColor:Null<FlxColor> = FlxColor.fromString('#' + formattedText);
				if (newColor != null && formattedText.length == 6) {
					setShaderColor(newColor);
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					_storedColor = getShaderColor();
					updateColors();
				} else FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			}
			hexTypeNum = -1;
		}

		// Click
		if (generalPressed) {
			hexTypeNum = -1;
			if (pointerOverlaps(modeNotes)) {
				modeNotes.forEachAlive((note:FlxSprite) -> {
					if (curSelectedMode != note.ID && pointerOverlaps(note)) {
						modeBG.visible = notesBG.visible = false;
						curSelectedMode = note.ID;
						onModeColumn = true;
						updateNotes();
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					}
				});
			} else if (pointerOverlaps(myNotes)) {
				myNotes.forEachAlive((note:StrumNote) -> {
					if (curSelectedNote != note.ID && pointerOverlaps(note)) {
						modeBG.visible = notesBG.visible = false;
						curSelectedNote = note.ID;
						onModeColumn = false;
						bigNote.rgbShader.parent = Note.globalRgbShaders[note.ID];
						bigNote.shader = Note.globalRgbShaders[note.ID].shader;
						updateNotes();
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					}
				});
			} else if (pointerOverlaps(colorWheel)) {
				_storedColor = getShaderColor();
				holdingOnObj = colorWheel;
			} else if (pointerOverlaps(colorGradient)) {
				_storedColor = getShaderColor();
				holdingOnObj = colorGradient;
			} else if (pointerOverlaps(colorPalette)) {
				setShaderColor(colorPalette.pixels.getPixel32(Std.int((pointerX() - colorPalette.x) / colorPalette.scale.x), Std.int((pointerY() - colorPalette.y) / colorPalette.scale.y)));
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
				updateColors();
			} else if (pointerOverlaps(skinNote)) {
				onPixel = !onPixel;
				spawnNotes();
				updateNotes(true);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			} else if (pointerY() >= hexTypeLine.y && pointerY() < hexTypeLine.y + hexTypeLine.height && Math.abs(pointerX() - 1000) <= 84) {
				hexTypeNum = 0;
				for (letter in alphabetHex.members[0].members) {
					if (letter.x - letter.offset.x + letter.width <= pointerX()) hexTypeNum++;
					else break;
				}
				if (hexTypeNum > 5) hexTypeNum = 5;
				hexTypeLine.visible = true;
				centerHexTypeLine();
			} else holdingOnObj = null;
		}
		// holding
		if (holdingOnObj != null) {
			if (FlxG.mouse.justReleased) {
				holdingOnObj = null;
				_storedColor = getShaderColor();
				updateColors();
				FlxG.sound.play(Paths.sound('scrollMenu'), .6);
			} else if (generalMoved || generalPressed) {
				if (holdingOnObj == colorGradient) {
					var newBrightness:Float = 1 - FlxMath.bound((pointerY() - colorGradient.y) / colorGradient.height, 0, 1);
					_storedColor.alpha = 1;
					if (_storedColor.brightness == 0) //prevent bug
						setShaderColor(FlxColor.fromRGBFloat(newBrightness, newBrightness, newBrightness));
					else setShaderColor(FlxColor.fromHSB(_storedColor.hue, _storedColor.saturation, newBrightness));
					updateColors(_storedColor);
				} else if (holdingOnObj == colorWheel) {
					var center:FlxPoint = FlxPoint.get(colorWheel.x + colorWheel.width / 2, colorWheel.y + colorWheel.height / 2);
					var mouse:FlxPoint = pointerFlxPoint();
					var hue:Float = FlxMath.wrap(FlxMath.wrap(Std.int(mouse.degreesTo(center)), 0, 360) - 90, 0, 360);
					var sat:Float = FlxMath.bound(mouse.dist(center) / colorWheel.width * 2, 0, 1);
					if (sat != 0) setShaderColor(FlxColor.fromHSB(hue, sat, _storedColor.brightness));
					else setShaderColor(FlxColor.fromRGBFloat(_storedColor.brightness, _storedColor.brightness, _storedColor.brightness));
					updateColors();
				}
			} 
		} else if (Controls.justPressed('reset') && hexTypeNum < 0) {
			var chosenRGB:Array<Array<FlxColor>> = (!onPixel ? ClientPrefs.defaultData.arrowRGBExtra : ClientPrefs.defaultData.arrowRGBPixelExtra);
			if (FlxG.keys.pressed.SHIFT) {
				for (i in 0...3) {
					var strumRGB:RGBShaderReference = myNotes.members[curSelectedNote].rgbShader;
					var color:FlxColor = chosenRGB[curSelectedNote][i];
					switch(i) {
						case 0: getShader().r = strumRGB.r = color;
						case 1: getShader().g = strumRGB.g = color;
						case 2: getShader().b = strumRGB.b = color;
					}
					dataArray[curSelectedNote][i] = color;
				}
			}
			setShaderColor(chosenRGB[curSelectedNote][curSelectedMode]);
			FlxG.sound.play(Paths.sound('cancelMenu'), .6);
			updateColors();
		}
	}

	function pointerOverlaps(obj:Dynamic):Bool return FlxG.mouse.overlaps(obj);
	function pointerX():Float return FlxG.mouse.x;
	function pointerY():Float return FlxG.mouse.y;
	function pointerFlxPoint():FlxPoint return FlxG.mouse.getViewPosition();

	function centerHexTypeLine() {
		if (hexTypeNum > 0) {
			var letter:AlphabetGlyph = alphabetHex.members[0].members[hexTypeNum - 1];
			hexTypeLine.x = letter.x - letter.offset.x + letter.width;
		} else {
			var letter:AlphabetGlyph = alphabetHex.members[0].members[0];
			hexTypeLine.x = letter.x - letter.offset.x;
		}
		hexTypeLine.x += hexTypeLine.width;
		hexTypeVisibleTimer = 0;
	}

	function changeSelectionMode(change:Int = 0) {
		curSelectedMode += change;
		if (curSelectedMode < 0) curSelectedMode = 2;
		if (curSelectedMode >= 3) curSelectedMode = 0;

		modeBG.visible = true;
		notesBG.visible = false;
		updateNotes();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
	function changeSelectionNote(change:Int = 0) {
		curSelectedNote += change;
		if (curSelectedNote < 0) curSelectedNote = dataArray.length - 1;
		if (curSelectedNote >= dataArray.length) curSelectedNote = 0;
		
		modeBG.visible = false;
		notesBG.visible = true;
		bigNote.rgbShader.parent = Note.globalRgbShaders[curSelectedNote];
		bigNote.shader = Note.globalRgbShaders[curSelectedNote].shader;
		updateNotes();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	// alphabets
	function makeColorAlphabet(x:Float = 0, y:Float = 0):Alphabet {
		var text:Alphabet = new Alphabet(x, y);
		text.alignment = CENTER;
		text.updateScale(.6, .6);
		add(text);
		return text;
	}

	// notes sprites functions
	var skinNote:FlxSprite;
	var modeNotes:FlxTypedGroup<FlxSprite>;
	var myNotes:FlxTypedGroup<StrumNote>;
	var bigNote:Note;
	public function spawnNotes() {
		dataArray = !onPixel ? ClientPrefs.data.arrowRGBExtra : ClientPrefs.data.arrowRGBPixelExtra;
		if (onPixel) PlayState.stageUI = "pixel";

		// clear groups
		modeNotes.forEachAlive((note:FlxSprite) -> {
			note.kill();
			note.destroy();
		});
		myNotes.forEachAlive((note:StrumNote) -> {
			note.kill();
			note.destroy();
		});
		modeNotes.clear();
		myNotes.clear();

		if (skinNote != null) {
			remove(skinNote);
			skinNote.destroy();
		}
		if (bigNote != null) {
			remove(bigNote);
			bigNote.destroy();
		}

		// respawn stuff
		var res:Int = onPixel ? 160 : 17;
		skinNote = new FlxSprite(48, 24).loadGraphic(Paths.image('noteColorMenu/' + (onPixel ? 'note' : 'notePixel')), true, res, res);
		skinNote.antialiasing = ClientPrefs.data.antialiasing;
		skinNote.setGraphicSize(68);
		skinNote.updateHitbox();
		skinNote.animation.add('anim', [0], 24, true);
		skinNote.animation.play('anim', true);
		if (!onPixel) skinNote.antialiasing = false;
		add(skinNote);

		var res:Int = !onPixel ? 160 : 17;
		for (i in 0...3) {
			var newNote:FlxSprite = new FlxSprite(230 + (100 * i), 100).loadGraphic(Paths.image('noteColorMenu/' + (!onPixel ? 'note' : 'notePixel')), true, res, res);
			newNote.antialiasing = ClientPrefs.data.antialiasing;
			newNote.setGraphicSize(85);
			newNote.updateHitbox();
			newNote.animation.add('anim', [i], 24, true);
			newNote.animation.play('anim', true);
			newNote.ID = i;
			if (onPixel) newNote.antialiasing = false;
			modeNotes.add(newNote);
		}

		Note.globalRgbShaders = [];
		for (i in 0...dataArray.length) {
			Note.initializeGlobalRGBShader(i);
			var newNote:StrumNote = new StrumNote(20 + (680 / dataArray.length * i), 200, i, 0);
			newNote.useRGBShader = true;
			newNote.setGraphicSize(80);
			newNote.updateHitbox();
			newNote.ID = i;
			myNotes.add(newNote);
		}

		bigNote = new Note().recycleNote(Note.DEFAULT_CAST);
		bigNote.inEditor = true;
		bigNote.setPosition(250, 325);
		bigNote.setGraphicSize(250);
		bigNote.updateHitbox();
		bigNote.rgbShader.parent = Note.globalRgbShaders[curSelectedNote];
		bigNote.shader = Note.globalRgbShaders[curSelectedNote].shader;
		for (i in 0...EK.colArray.length) {
			if (!onPixel) {
				bigNote.animation.addByPrefix('note$i', EK.colArrayAlt[i] + '0', 24, true);
				bigNote.animation.addByPrefix('note$i', EK.colArray[i] + '0', 24, true);
			} else bigNote.animation.add('note$i', [i + 9], 24, true);
		}
		insert(members.indexOf(myNotes) + 1, bigNote);
		_storedColor = getShaderColor();
		PlayState.stageUI = "normal";
	}

	function updateNotes(?instant:Bool = false) {
		for (note in modeNotes)
			note.alpha = (curSelectedMode == note.ID) ? 1 : 0.6;

		for (note in myNotes) {
			var newAnim:String = curSelectedNote == note.ID ? 'confirm' : 'pressed';
			note.alpha = (curSelectedNote == note.ID) ? 1 : 0.6;
			if (note.animation.curAnim == null || note.animation.curAnim.name != newAnim) note.playAnim(newAnim, true);
			if (instant) note.animation.curAnim.finish();
		}
		bigNote.animation.play('note$curSelectedNote', true);
		updateColors();
		fixColors();
	}

	function updateColors(specific:Null<FlxColor> = null) {
		var color:FlxColor = getShaderColor();
		var wheelColor:FlxColor = specific ?? getShaderColor();
		alphabetR.text = Std.string(color.red);
		alphabetG.text = Std.string(color.green);
		alphabetB.text = Std.string(color.blue);
		alphabetHex.text = color.toHexString(false, false);
		alphabetHex.color = color;

		colorWheel.color = FlxColor.fromHSB(0, 0, color.brightness);
		colorWheelSelector.setPosition(colorWheel.x + colorWheel.width / 2, colorWheel.y + colorWheel.height / 2);
		if (wheelColor.brightness != 0) {
			var hueWrap:Float = wheelColor.hue * Math.PI / 180;
			colorWheelSelector.x += Math.sin(hueWrap) * colorWheel.width / 2 * wheelColor.saturation;
			colorWheelSelector.y -= Math.cos(hueWrap) * colorWheel.height / 2 * wheelColor.saturation;
		}
		colorGradientSelector.y = colorGradient.y + colorGradient.height * (1 - color.brightness);

		var strumRGB:RGBShaderReference = myNotes.members[curSelectedNote].rgbShader;
		switch(curSelectedMode) {
			case 0: getShader().r = strumRGB.r = color;
			case 1: getShader().g = strumRGB.g = color;
			case 2: getShader().b = strumRGB.b = color;
		}
	}

	function fixColors() {
		var chosenRGB:Array<Array<FlxColor>> = (!onPixel ? ClientPrefs.defaultData.arrowRGBExtra : ClientPrefs.defaultData.arrowRGBPixelExtra);
		for (i in 0...3) {
			var strumRGB:RGBShaderReference = myNotes.members[curSelectedNote].rgbShader;
			var color:FlxColor = chosenRGB[curSelectedNote][i];
			switch(i) {
				case 0: getShader().r = strumRGB.r = color;
				case 1: getShader().g = strumRGB.g = color;
				case 2: getShader().b = strumRGB.b = color;
			}
			dataArray[curSelectedNote][i] = color;
		}
		setShaderColor(chosenRGB[curSelectedNote][curSelectedMode]);
		updateColors();
	}

	function setShaderColor(value:FlxColor) dataArray[curSelectedNote][curSelectedMode] = value;
	function getShaderColor():FlxColor return dataArray[curSelectedNote][curSelectedMode];
	function getShader():RGBPalette return Note.globalRgbShaders[curSelectedNote];

	override function destroy() {
		backend.NoteLoader.dispose();
		Note.globalRgbShaders = [];
		super.destroy();
	}
}