package options;

import flixel.input.keyboard.FlxKey;

import objects.AttachedText;
import objects.CheckboxThingie;
import backend.InputFormatter;

class BaseOptionsMenu extends MusicBeatSubstate
{
	var curOption:Option = null;
	var curSelected:Int = 0;
	var optionsArray:Array<Option>;

	var grpOptions:FlxTypedGroup<Alphabet>;
	var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	var grpTexts:FlxTypedGroup<AttachedText>;

	var descBox:FlxSprite;
	var descText:FlxText;

	public var title:String;
	public var rpcTitle:String;

	public var bg:FlxSprite;
	public function new() {
		super();

		if(title == null) title = 'Options';
		if(rpcTitle == null) rpcTitle = 'Options Menu';
		
		#if DISCORD_ALLOWED DiscordClient.changePresence(rpcTitle); #end
		
		bg = new FlxSprite(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		grpTexts = new FlxTypedGroup<AttachedText>();
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
		add(checkboxGroup);

		descBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		var titleText:Alphabet = new Alphabet(75, 45, title);
		titleText.setScale(0.6);
		titleText.alpha = 0.4;
		add(titleText);

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		for (i in 0...optionsArray.length) {
			var optionText:Alphabet = new Alphabet(290, 260, optionsArray[i].name, optionsArray[i].type == 'func');
			optionText.isMenuItem = true;
			optionText.x += 300;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (optionsArray[i].type == 'bool') {
				var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, Std.string(optionsArray[i].getValue()) == 'true');
				checkbox.sprTracker = optionText;
				checkbox.ID = i;
				checkboxGroup.add(checkbox);
			} else if (optionsArray[i].type != 'func') {
				optionText.x -= 80;
				optionText.startPosition.x -= 80;
				var valueText:AttachedText = new AttachedText('' + optionsArray[i].getValue(), optionText.width + 60);
				valueText.sprTracker = optionText;
				valueText.copyAlpha = true;
				valueText.ID = i;
				grpTexts.add(valueText);
				optionsArray[i].child = valueText;
			}
			updateTextFrom(optionsArray[i]);
		}

		changeSelection();
		reloadCheckboxes();
	}

	public function addOption(option:Option) {
		if(optionsArray == null || optionsArray.length < 1) optionsArray = [];
		optionsArray.push(option);
		return option;
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;

	var bindingKey:Bool = false;
	var holdingEsc:Float = 0;
	var bindingBlack:FlxSprite;
	var bindingText:Alphabet;
	var bindingText2:Alphabet;
	override function update(elapsed:Float) {
		super.update(elapsed);

		if(bindingKey) {
			bindingKeyUpdate(elapsed);
			return;
		}

		if (controls.UI_UP_P || controls.UI_DOWN_P) changeSelection(controls.UI_UP_P ? -1 : 1);

		if (controls.BACK) {
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if(nextAccept <= 0) {
			var usesCheckbox = true;
			if(curOption.type != 'bool' && curOption.type != 'func') {
				usesCheckbox = false;
			}

			if(usesCheckbox) {
				if(controls.ACCEPT) {
					FlxG.sound.play(Paths.sound((curOption.type == 'func' ? 'confirmMenu' : 'scrollMenu')));
					if (curOption.type == 'bool') curOption.setValue((curOption.getValue() == true) ? false : true);
					curOption.change();
					reloadCheckboxes();
				}
			} else {
				if(curOption.type == 'keybind') {
					if(controls.ACCEPT) {
						bindingBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
						bindingBlack.scale.set(FlxG.width, FlxG.height);
						bindingBlack.updateHitbox();
						bindingBlack.alpha = 0;
						FlxTween.tween(bindingBlack, {alpha: 0.6}, 0.35, {ease: FlxEase.linear});
						add(bindingBlack);

						bindingText = new Alphabet(FlxG.width / 2, 160, "Rebinding " + curOption.name, false);
						bindingText.alignment = CENTERED;
						add(bindingText);

						bindingText2 = new Alphabet(FlxG.width / 2, 340, "Hold ESC to Cancel\nHold Backspace to Delete");
						bindingText2.alignment = CENTERED;
						add(bindingText2);

						bindingKey = true;
						holdingEsc = 0;
						ClientPrefs.toggleVolumeKeys(false);
						FlxG.sound.play(Paths.sound('scrollMenu'));
					}
				} else if(controls.UI_LEFT || controls.UI_RIGHT) {
					var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
					if(holdTime > 0.5 || pressed) {
						if(pressed) {
							var add:Dynamic = null;
							if(curOption.type != 'string')
								add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;

							switch(curOption.type) {
								case 'int' | 'float' | 'percent':
									holdValue = curOption.getValue() + add;
									if(holdValue < curOption.minValue) holdValue = curOption.minValue;
									else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

									switch(curOption.type) {
										case 'int':
											holdValue = Math.round(holdValue);
											curOption.setValue(holdValue);

										case 'float' | 'percent':
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											curOption.setValue(holdValue);
									}

								case 'string':
									var num:Int = curOption.curOption; //lol
									if(controls.UI_LEFT_P) --num;
									else num++;

									if (num < 0) num = curOption.options.length - 1;
									else if (num >= curOption.options.length) num = 0;

									curOption.curOption = num;
									curOption.setValue(curOption.options[num]); //lol
							}
							updateTextFrom(curOption);
							curOption.change();
							FlxG.sound.play(Paths.sound('scrollMenu'));
						} else if(curOption.type != 'string') {
							holdValue += curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);
							if (holdValue < curOption.minValue) holdValue = curOption.minValue;
							else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

							switch(curOption.type) {
								case 'int': curOption.setValue(Math.round(holdValue));
								case 'float' | 'percent': curOption.setValue(FlxMath.roundDecimal(holdValue, curOption.decimals));
							}
							updateTextFrom(curOption);
							curOption.change();
						}
					}

					if(curOption.type != 'string') holdTime += elapsed;
				} else if (controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					if(holdTime > .5) FlxG.sound.play(Paths.sound('scrollMenu'));
					holdTime = 0;
				}
			}

			if(controls.RESET) {
				var leOption:Option = optionsArray[curSelected];
				if(leOption.type != 'keybind') {
					leOption.setValue(leOption.defaultValue);
					if(leOption.type != 'bool') {
						if(leOption.type == 'string') leOption.curOption = leOption.options.indexOf(leOption.getValue());
						updateTextFrom(leOption);
					}
				} else {
					leOption.setValue(leOption.defaultKeys.keyboard);
					updateBind(leOption);
				}
				leOption.change();
				FlxG.sound.play(Paths.sound('cancelMenu'));
				reloadCheckboxes();
			}
		}

		if (nextAccept > 0) nextAccept--;
	}

	function bindingKeyUpdate(elapsed:Float) {
		if(FlxG.keys.pressed.ESCAPE) {
			holdingEsc += elapsed;
			if(holdingEsc > 0.5) {
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}
		} else if (FlxG.keys.pressed.BACKSPACE) {
			holdingEsc += elapsed;
			if(holdingEsc > 0.5) {
				curOption.keys.keyboard = NONE;
				updateBind(InputFormatter.getKeyName(NONE));
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}
		} else {
			holdingEsc = 0;
			var changed:Bool = false;
			if(FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY) {
				var keyPressed:FlxKey = cast (FlxG.keys.firstJustPressed(), FlxKey);
				var keyReleased:FlxKey = cast (FlxG.keys.firstJustReleased(), FlxKey);

				if(keyPressed != NONE && keyPressed != ESCAPE && keyPressed != BACKSPACE) {
					changed = true;
					curOption.keys.keyboard = keyPressed;
				} else if(keyReleased != NONE && (keyReleased == ESCAPE || keyReleased == BACKSPACE)) {
					changed = true;
					curOption.keys.keyboard = keyReleased;
				}
			}

			if(changed) {
				var key:String = null;
				if(curOption.keys.keyboard == null) curOption.keys.keyboard = 'NONE';
				curOption.setValue(curOption.keys.keyboard);
				key = InputFormatter.getKeyName(FlxKey.fromString(curOption.keys.keyboard));
				updateBind(key);
				FlxG.sound.play(Paths.sound('confirmMenu'));
				closeBinding();
			}
		}
	}

	final MAX_KEYBIND_WIDTH = 320;
	function updateBind(?text:String = null, ?option:Option = null) {
		if(option == null) option = curOption;
		if(text == null) {
			text = option.getValue();
			if(text == null) text = 'NONE';
			text = InputFormatter.getKeyName(FlxKey.fromString(text));
		}

		var bind:AttachedText = cast option.child;
		var attach:AttachedText = new AttachedText(text, bind.textoffset.x);
		attach.sprTracker = bind.sprTracker;
		attach.copyAlpha = true;
		attach.ID = bind.ID;
		attach.scaleX = Math.min(1, MAX_KEYBIND_WIDTH / attach.width);
		attach.setPosition(bind.x, bind.y);

		option.child = attach;
		grpTexts.insert(grpTexts.members.indexOf(bind), attach);
		grpTexts.remove(bind);
		bind.destroy();
	}

	function closeBinding() {
		bindingKey = false;
		bindingBlack.destroy();
		remove(bindingBlack);

		bindingText.destroy();
		remove(bindingText);

		bindingText2.destroy();
		remove(bindingText2);
		ClientPrefs.toggleVolumeKeys(true);
	}

	function updateTextFrom(option:Option) {
		if(option.type == 'keybind') {
			updateBind(option);
			return;
		}

		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if(option.type == 'percent') val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', Std.string(val)).replace('%d', Std.string(def));
	}
	
	function changeSelection(change:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + change, 0, optionsArray.length - 1);

		var descString:String = "";
		var checkIfEmpty:Bool = optionsArray[curSelected].description != "";
		if (checkIfEmpty) descString = optionsArray[curSelected].description;
		descBox.visible = checkIfEmpty;
		descText.text = descString;
		descText.screenCenter(Y).y += 270;

		for (num => item in grpOptions.members) {
			item.targetY = num - curSelected;

			item.alpha = 0.6;
			if (item.targetY == 0) item.alpha = 1;
		}
		for (text in grpTexts) {
			text.alpha = 0.6;
			if(text.ID == curSelected) text.alpha = 1;
		}

		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();

		curOption = optionsArray[curSelected]; //shorter lol
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function reloadCheckboxes() {
		for (checkbox in checkboxGroup)
			checkbox.daValue = Std.string(optionsArray[checkbox.ID].getValue()) == 'true';
	}
}