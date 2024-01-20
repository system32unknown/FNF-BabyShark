package options;

import objects.Note;
import shaders.ColorSwap;

class NotesSubState extends MusicBeatSubstate
{
	static var curSelected:Int = 0;
	static var typeSelected:Int = 0;
	var grpNumbers:FlxTypedGroup<Alphabet>;
	var grpNotes:FlxTypedGroup<FlxSprite>;
	var shaderArray:Array<ColorSwap> = [];
	var curValue:Float = 0;
	var holdTime:Float = 0;
	var scrollHoldTime:Float = 0;
	var nextAccept:Int = 5;

	var blackBG:FlxSprite;
	var hsbText:Alphabet;

	var posX = 230;
	var arrowHSV:Array<Array<Int>> = ClientPrefs.getPref('arrowHSV');
	public function new() {
		super();
		
		var bg:FlxSprite = new FlxSprite(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.getPref('Antialiasing');
		add(bg);
		
		var grid:flixel.addons.display.FlxBackdrop = CoolUtil.createBackDrop(80, 80, 160, 160, true, 0x33FFFFFF, 0x0);
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);

		blackBG = new FlxSprite(posX - 25).makeGraphic(1140, 200, FlxColor.BLACK);
		blackBG.alpha = 0.4;
		add(blackBG);

		grpNotes = new FlxTypedGroup<FlxSprite>();
		add(grpNotes);
		grpNumbers = new FlxTypedGroup<Alphabet>();
		add(grpNumbers);

		for (i in 0...arrowHSV.length) {
			var yPos:Float = (165 * i) + 35;
			for (j in 0...3) {
				var optionText:Alphabet = new Alphabet(posX + (225 * j) + 250, yPos + 60, Std.string(arrowHSV[i][j]), true);
				optionText.ID = i;
				grpNumbers.add(optionText);
			}

			var note:FlxSprite = new FlxSprite(posX, yPos);
			note.frames = Paths.getSparrowAtlas(Note.defaultNoteSkin);
			note.animation.addByPrefix('idle', EK.gfxLetter[i] + '0');
			note.animation.play('idle');
			note.antialiasing = ClientPrefs.getPref('Antialiasing');
			note.ID = i;
			grpNotes.add(note);

			var newShader:ColorSwap = new ColorSwap();
			note.shader = newShader.shader;
			newShader.setHSB(arrowHSV[i][0] / 360, arrowHSV[i][1] / 100, arrowHSV[i][2] / 100);
			shaderArray.push(newShader);
		}

		hsbText = new Alphabet(posX + 720, 0, "Hue    Saturation  Brightness", false);
		hsbText.setScale(.6, .6);
		add(hsbText);

		changeSelection();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	var changingNote:Bool = false;
	override function update(elapsed:Float) {
		var rownum = 0;
		var lerpVal:Float = Math.exp(-elapsed * 9.6);
		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			var scaledY = FlxMath.remapToRange(item.ID, 0, 1, 0, 1.3);
			item.y = FlxMath.lerp((scaledY * 165) + 270 + 60, item.y, lerpVal);
			item.x = FlxMath.lerp((item.ID * 20) + 90 + posX + (225 * rownum + 250), item.x, lerpVal);
			rownum++;
			if (rownum == 3) rownum = 0;
		}
		for (i in 0...grpNotes.length) {
			var item = grpNotes.members[i];
			var scaledY = FlxMath.remapToRange(item.ID, 0, 1, 0, 1.3);
			item.y = FlxMath.lerp((scaledY * 165) + 270, item.y, lerpVal);
			item.x = FlxMath.lerp((item.ID * 20) + 90, item.x, lerpVal);
			if (i == curSelected) {
				hsbText.y = item.y - 70;
				blackBG.setPosition(item.x - 20, item.y - 20);
			}
		}

		if(changingNote) {
			if(holdTime < 0.5) {
				if(controls.UI_LEFT_P) {
					updateValue(-1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.UI_RIGHT_P) {
					updateValue(1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.RESET) {
					resetValue(curSelected, typeSelected);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					holdTime = 0;
				} else if(controls.UI_LEFT || controls.UI_RIGHT) {
					holdTime += elapsed;
				}
			} else {
				var add:Float = 90;
				switch(typeSelected) {
					case 1 | 2: add = 50;
				}
				if(controls.UI_LEFT) {
					updateValue(elapsed * -add);
				} else if(controls.UI_RIGHT) {
					updateValue(elapsed * add);
				}
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					FlxG.sound.play(Paths.sound('scrollMenu'));
					holdTime = 0;
				}
			}
		} else {
			var shiftMult:Int = 1;
			if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

			if (controls.UI_UP_P || controls.UI_DOWN_P) {
				scrollHoldTime = 0;
				changeSelection(controls.UI_UP_P ? -shiftMult : shiftMult);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_LEFT_P || controls.UI_RIGHT_P) {
				changeType(controls.UI_LEFT_P ? -1 : 1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if(controls.UI_DOWN || controls.UI_UP) {
				var checkLastHold:Int = Math.floor((scrollHoldTime - 0.5) * 10);
				scrollHoldTime += elapsed;
				var checkNewHold:Int = Math.floor((scrollHoldTime - 0.5) * 10);

				if(scrollHoldTime > 0.5 && checkNewHold - checkLastHold > 0) {
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}
			}
			if(controls.RESET) {
				for (i in 0...3) resetValue(curSelected, i);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.ACCEPT && nextAccept <= 0) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changingNote = true;
				holdTime = 0;
				for (i in 0...grpNumbers.length) {
					var item = grpNumbers.members[i];
					item.alpha = 0;
					if ((curSelected * 3) + typeSelected == i) {
						item.alpha = 1;
					}
				}
				for (i in 0...grpNotes.length) {
					var item = grpNotes.members[i];
					item.alpha = 0;
					if (curSelected == i) {
						item.alpha = 1;
					}
				}
				super.update(elapsed);
				return;
			}
		}

		if (controls.BACK || (changingNote && controls.ACCEPT)) {
			FlxG.mouse.visible = false;
			if(!changingNote) close();
			else changeSelection();
			changingNote = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if(nextAccept > 0) nextAccept--;
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + change, 0, arrowHSV.length - 1);
		curValue = arrowHSV[curSelected][typeSelected];
		updateValue();

		var bullshit = 0;
		var rownum = 0;
		var bullshit2 = 0;
		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * 3) + typeSelected == i) {
				item.alpha = 1;
			}
			item.ID = bullshit - curSelected;
			rownum++;
			if (rownum == 3) {
				rownum = 0;
				bullshit++;
			}
		}
		for (i in 0...grpNotes.length) {
			var item = grpNotes.members[i];
			item.alpha = 0.6;
			item.scale.set(0.75, 0.75);
			if (curSelected == i) {
				item.alpha = 1;
				item.scale.set(1, 1);
				hsbText.y = item.y - 70;
				blackBG.y = item.y - 20;
			}
			item.ID = bullshit2 - curSelected;
			bullshit2++;
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changeType(change:Int = 0) {
		typeSelected = FlxMath.wrap(typeSelected + change, 0, 2);
		curValue = arrowHSV[curSelected][typeSelected];
		updateValue();

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * 3) + typeSelected == i) {
				item.alpha = 1;
			}
		}
	}

	function resetValue(selected:Int, type:Int) {
		curValue = 0;
		arrowHSV[selected][type] = 0;
		switch(type) {
			case 0: shaderArray[selected].hue = 0;
			case 1: shaderArray[selected].saturation = 0;
			case 2: shaderArray[selected].brightness = 0;
		}

		var item = grpNumbers.members[(selected * 3) + type];
		item.text = '0';

		var add = (40 * (item.letters.length - 1)) / 2;
		for (letter in item.letters) {
			letter.offset.x += add;
		}
	}
	function updateValue(change:Float = 0) {
		curValue += change;
		var roundedValue:Int = Math.round(curValue);
		var max:Float = 180;
		switch(typeSelected) {
			case 1 | 2: max = 100;
		}

		if(roundedValue < -max) {
			curValue = -max;
		} else if(roundedValue > max) {
			curValue = max;
		}
		roundedValue = Math.round(curValue);
		arrowHSV[curSelected][typeSelected] = roundedValue;

		switch(typeSelected) {
			case 0: shaderArray[curSelected].hue = roundedValue / 360;
			case 1: shaderArray[curSelected].saturation = roundedValue / 100;
			case 2: shaderArray[curSelected].brightness = roundedValue / 100;
		}

		var item = grpNumbers.members[(curSelected * 3) + typeSelected];
		item.text = Std.string(roundedValue);

		var add = (40 * (item.letters.length - 1)) / 2;
		for (letter in item.letters) {
			letter.offset.x += add;
			if(roundedValue < 0) letter.offset.x += 10;
		}
	}
}