package options;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import data.EkData.Keybinds;
import utils.CoolUtil;
import utils.Controls;
import utils.InputFormatter;
import ui.AttachedText;
import ui.Alphabet;

class ControlsSubState extends MusicBeatSubstate {
	private static var curSelected:Int = 1;
	private static var curAlt:Bool = false;

	private static var defaultKey:String = 'Reset to Default Keys';

	var optionShit:Array<Dynamic> = [];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var grpInputs:Array<AttachedText> = [];
	private var grpInputsAlt:Array<AttachedText> = [];

	var rebindingKey:Bool = false;
	var nextAccept:Int = 5;

	var pages:Array<Dynamic> = [];
	var curPage:Int = 0;

	public function new() {
		super();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

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
		for (i in 0...grpOptions.members.length) {
			var obj = grpOptions.members[0];
			obj.kill();
			grpOptions.remove(obj, true);
			obj.destroy();
		}

		for (text in grpInputs) {
			text.kill();
			remove(text);
		}
		grpInputs = [];

		for (text in grpInputsAlt) {
			text.kill();
			remove(text);
		}
		grpInputsAlt = [];

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
				if (grpOptions.members[curSelected].ID == 1) {
					changePage(controls.UI_LEFT_P ? -1 : 1);
				} else changeAlt();
			}

			if (controls.BACK) {
				ClientPrefs.reloadControls();
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
					if (curAlt)
						grpInputsAlt[getInputTextNum()].alpha = 0;
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
				if (curAlt) {
					if (grpInputsAlt[curSelected] != null)
						grpInputsAlt[curSelected].alpha = 1;
				} else {
					if (grpInputsAlt[curSelected] != null)
						grpInputs[curSelected].alpha = 1;
				}
				reloadTexts();
				FlxG.sound.play(Paths.sound('scrollMenu'));
				rebindingKey = false;
				bindingTime = 0;
			}
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	function getInputTextNum() {
		var num:Int = 0;
		for (i in 0...curSelected) {
			if(optionShit[i].length > 1) {
				num++;
			}
		}
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

		for (i in 0...grpInputs.length) {
			grpInputs[i].alpha = 0.6;
		}
		for (i in 0...grpInputsAlt.length) {
			grpInputsAlt[i].alpha = 0.6;
		}

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit - 1) || item.ID == 1) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
					if (item.ID != 1) {
						if(curAlt) {
							for (i in 0...grpInputsAlt.length) {
								if(grpInputsAlt[i].sprTracker == item) {
									grpInputsAlt[i].alpha = 1;
									break;
								}
							}
						} else {
							for (i in 0...grpInputs.length) {
								if(grpInputs[i].sprTracker == item) {
									grpInputs[i].alpha = 1;
									break;
								}
							}
						}
					}
				}
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changeAlt() {
		curAlt = !curAlt;
		for (i in 0...grpInputs.length) {
			if(grpInputs[i].sprTracker == grpOptions.members[curSelected]) {
				grpInputs[i].alpha = 0.6;
				if(!curAlt) {
					grpInputs[i].alpha = 1;
				}
				break;
			}
		}
		for (i in 0...grpInputsAlt.length) {
			if(grpInputsAlt[i].sprTracker == grpOptions.members[curSelected]) {
				grpInputsAlt[i].alpha = 0.6;
				if(curAlt) {
					grpInputsAlt[i].alpha = 1;
				}
				break;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	private function unselectableCheck(num:Int, ?checkDefaultKey:Bool = false):Bool {
		if(optionShit[num][0] == defaultKey) {
			return checkDefaultKey;
		}
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
		while(grpInputs.length > 0) {
			var item:AttachedText = grpInputs[0];
			item.kill();
			grpInputs.remove(item);
			item.destroy();
		}
		while(grpInputsAlt.length > 0) {
			var item:AttachedText = grpInputsAlt[0];
			item.kill();
			grpInputsAlt.remove(item);
			item.destroy();
		}

		for (i in 0...grpOptions.length) {
			if(!unselectableCheck(i, true)) {
				addBindTexts(grpOptions.members[i], i);
			}
		}

		var bullShit:Int = 0;
		for (i in 0...grpInputs.length) {
			grpInputs[i].alpha = 0.6;
		}
		for (i in 0...grpInputsAlt.length) {
			grpInputsAlt[i].alpha = 0.6;
		}

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit - 1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
					if(curAlt) {
						for (i in 0...grpInputsAlt.length) {
							if(grpInputsAlt[i].sprTracker == item) {
								grpInputsAlt[i].alpha = 1;
							}
						}
					} else {
						for (i in 0...grpInputs.length) {
							if(grpInputs[i].sprTracker == item) {
								grpInputs[i].alpha = 1;
							}
						}
					}
				}
			}
		}
	}
}