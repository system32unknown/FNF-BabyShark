package options;

import flixel.addons.display.FlxBackdrop;
import flixel.input.keyboard.FlxKey;
import data.EkData.Keybinds;
import backend.InputFormatter;
import objects.AttachedText;
import objects.AttachedSprite;
class ControlsSubState extends MusicBeatSubstate {
	static var curSelected:Int = 1;
	static var curAlt:Bool = false;

	static var defaultKey:String = 'Reset to Default Keys';

	var optionShit:Array<Dynamic> = [];

	var grpOptions:FlxTypedGroup<Alphabet>;
	var grpInputs:Array<AttachedText> = [];
	var grpInputsAlt:Array<AttachedText> = [];

	var rebindingKey:Bool = false;
	var nextAccept:Int = 5;

	var pages:Array<Dynamic> = [];
	var curPage:Int = 0;

	public function new() {
		super();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff7192fd;
		bg.screenCenter();
		add(bg);

		var grid:FlxBackdrop = CoolUtil.createBackDrop(80, 80, 160, 160, true, 0x33FFFFFF, 0x0);
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);

		add(grpOptions = new FlxTypedGroup<Alphabet>());

		optionShit = Keybinds.optionShit();

		var currentPage:String = "";
		var generatedPage:Dynamic = [];
		for (i in 0...optionShit.length) {
			if (optionShit[i][0] != "" && optionShit[i].length < 2 && currentPage == "") { //It's the first page title
				generatedPage.push(optionShit[i]);
				currentPage = optionShit[i][0];
			} else if (optionShit[i][0] != "" && optionShit[i].length < 2 && currentPage != "") { // It's a new page title.
				generatedPage.push(['']);
				generatedPage.push([defaultKey]);
				pages.push(generatedPage);

				generatedPage = [];
				generatedPage.push(optionShit[i]);
				currentPage = optionShit[i][0];
			} else if (optionShit[i].length > 1) { // It's an input
				generatedPage.push(optionShit[i]);
			} else if (optionShit[i][0] == "" && optionShit[i].length < 2) { // It's blank!
				generatedPage.push(optionShit[i]);
			}
		}

		optionShit = pages[curPage];
		reloadTexts();
		changeSelection();
	}

	function reloadTexts() {
		for (_ in 0...grpOptions.members.length) {
			var obj = grpOptions.members[0];
			obj.kill();
			grpOptions.remove(obj, true);
			obj.destroy();
		}

		for (grp in [grpInputs, grpInputsAlt]) {
			for (text in grp) {
				text.kill();
				remove(text);
			}
			grp = [];
		}

		for (i in 0...optionShit.length) {
			var isCentered:Bool = false;
			var isDefaultKey:Bool = (optionShit[i][0] == defaultKey);
			if(unselectableCheck(i, true)) {
				isCentered = true;
			}

			var isFirst:Bool = i == 0;
			var text:String = optionShit[i][0];
			if (isFirst) text = '< ' + text + ' >';

			var optionText:Alphabet = new Alphabet(200, 300, text, (!isCentered || isDefaultKey));
			optionText.isMenuItem = true;
			if (isCentered) {
				optionText.screenCenter(X);
				optionText.y -= 55;
				optionText.startPosition.y -= 55;
			}
			optionText.changeX = false;
			optionText.distancePerItem.y = 60;
			optionText.targetY = i - curSelected;
			optionText.snapToPosition();
			optionText.ID = 0;
			if (isFirst) optionText.ID = 1;
			grpOptions.add(optionText);

			if (!isCentered) {
				addBindTexts(optionText, i);
				if(curSelected < 0) curSelected = i;
			}
		}
	}

	var bindingTime:Float = 0;
	var holdTime:Float = 0;
	override function update(elapsed:Float) {
		if (!rebindingKey) {
			var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

			if (controls.UI_DOWN || controls.UI_UP) {
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}
			} 

			if (controls.UI_UP_P) {
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (controls.UI_DOWN_P) {
				changeSelection(shiftMult);
				holdTime = 0;
			}
			if (controls.UI_LEFT_P || controls.UI_RIGHT_P) {
				if (grpOptions.members[curSelected].ID == 1)
					changePage(controls.UI_LEFT_P ? -1 : 1);
				else changeAlt();
			}

			if (controls.BACK) {
				ClientPrefs.reloadVolumeKeys();
				close();
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}

			if(controls.ACCEPT && nextAccept <= 0) {
				if(optionShit[curSelected][0] == defaultKey) {
					ClientPrefs.keyBinds = ClientPrefs.defaultKeys.copy();
					reloadKeys();
					reloadTexts();
					changeSelection();
					FlxG.sound.play(Paths.sound('confirmMenu'));
				} else if(!unselectableCheck(curSelected)) {
					bindingTime = 0;
					rebindingKey = true;
					if (curAlt) grpInputsAlt[getInputTextNum()].alpha = 0;
					else grpInputs[getInputTextNum()].alpha = 0;
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
			}
		} else {
			var keyPressed:Int = FlxG.keys.firstJustPressed();
			if (keyPressed > -1) {
				var keysArray:Array<FlxKey> = ClientPrefs.keyBinds.get(optionShit[curSelected][1]);
				keysArray[curAlt ? 1 : 0] = keyPressed;

				var opposite:Int = (curAlt ? 0 : 1);
				if(keysArray[opposite] == keysArray[1 - opposite]) {
					keysArray[opposite] = NONE;
				}
				ClientPrefs.keyBinds.set(optionShit[curSelected][1], keysArray);

				reloadKeys();
				FlxG.sound.play(Paths.sound('confirmMenu'));
				rebindingKey = false;
			}

			bindingTime += elapsed;
			if(bindingTime > 5) {
				if (curAltText[curSelected] != null)
					curAltText[curSelected].alpha = 1;
				reloadTexts();
				FlxG.sound.play(Paths.sound('scrollMenu'));
				rebindingKey = false;
				bindingTime = 0;
			}
		}

		if(nextAccept > 0) nextAccept--;
		super.update(elapsed);
	}

	function getInputTextNum() {
		var num:Int = 0;
		for (i in 0...curSelected)
			if(optionShit[i].length > 1) num++;
		return num;
	}
	
	function changePage(change:Int = 0) {
		curPage = FlxMath.wrap(curPage + change, 0, pages.length - 1);
		optionShit = pages[curPage];

		reloadTexts();
		changeSelection();
	}

	function changeSelection(change:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
		if ((unselectableCheck(curSelected) && grpOptions.members[curSelected].ID != 1) && change != 0) {
			changeSelection(change);
			return;
		}

		var bullShit:Int = 0;
		for (grp in [grpInputs, grpInputsAlt]) {
			for (grps in grp) grps.alpha = 0.6;
		}

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit - 1) || item.ID == 1) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
					if (item.ID != 1) {
						for (grptxt in curAltText) {
							if(grptxt.sprTracker == item) {
								grptxt.alpha = 1;
								break;
							}
						}
					}
				}
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	var curAltText:Array<AttachedText> = [];
	function changeAlt() {
		curAlt = !curAlt;
		curAltText = curAlt ? grpInputsAlt : grpInputs;
		for (grp in [grpInputs, grpInputsAlt]) {
			for (grps in grp) {
				if(grps.sprTracker == grpOptions.members[curSelected]) {
					grps.alpha = 0.6;
					if(!curAlt) grps.alpha = 1;
					break;
				}
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function unselectableCheck(num:Int, ?checkDefaultKey:Bool = false):Bool {
		if(optionShit[num][0] == defaultKey) return checkDefaultKey;
		return optionShit[num].length < 2 && optionShit[num][0] != defaultKey;
	}

	private function addBindTexts(optionText:Alphabet, num:Int) {
		var keys:Array<Dynamic> = ClientPrefs.keyBinds.get(optionShit[num][1]);
		var text1 = new AttachedText(InputFormatter.getKeyName(keys[0]), 400, -55);
		text1.setPosition(optionText.x + 400, optionText.y - 55);
		text1.sprTracker = optionText;
		grpInputs.push(text1);
		add(text1);

		var text2 = new AttachedText(InputFormatter.getKeyName(keys[1]), 650, -55);
		text2.setPosition(optionText.x + 650, optionText.y - 55);
		text2.sprTracker = optionText;
		grpInputsAlt.push(text2);
		add(text2);
	}

	function reloadKeys() {
		for (grp in [grpInputs, grpInputsAlt]) {
			while(grp.length > 0) {
				var item:AttachedText = grp[0];
				item.kill();
				grp.remove(item);
				item.destroy();
			}
		}

		for (i in 0...grpOptions.length) {
			if(!unselectableCheck(i, true)) {
				addBindTexts(grpOptions.members[i], i);
			}
		}

		var bullShit:Int = 0;
		for (grp in [grpInputs, grpInputsAlt]) {
			for (grps in grp) grps.alpha = 0.6;
		}

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit - 1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
					for (grptxt in curAltText) {
						if(grptxt.sprTracker == item) grptxt.alpha = 1;
					}
				}
			}
		}
	}
}