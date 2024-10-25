package options;

import objects.CheckboxThingie;
import objects.AttachedText;
import options.Option.OptionType;

class GameplayChangersSubstate extends FlxSubState {
	var curSelected:Int = 0;
	var optionsArray:Array<Dynamic> = [];

	var grpOptions:FlxTypedGroup<Alphabet>;
	var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	var grpTexts:FlxTypedGroup<AttachedText>;

	var curOption(get, never):GameplayOption;
	function get_curOption() return optionsArray[curSelected]; //shorter lol

	function getOptions() {
		var goption:GameplayOption = new GameplayOption('Scroll Type', 'scrolltype', STRING, 'multiplicative', ["multiplicative", "constant"]);
		optionsArray.push(goption);

		var option:GameplayOption = new GameplayOption('Scroll Speed', 'scrollspeed', FLOAT, 1);
		option.scrollSpeed = 2.0;
		option.minValue = 0.35;
		option.changeValue = 0.05;
		option.decimals = 2;
		if (goption.getValue() != "constant") {
			option.displayFormat = '%vX';
			option.maxValue = 3;
		} else {
			option.displayFormat = "%v";
			option.maxValue = 6;
		}
		optionsArray.push(option);

		#if FLX_PITCH
		var option:GameplayOption = new GameplayOption('Playback Rate', 'songspeed', FLOAT, 1);
		option.scrollSpeed = 1;
		option.minValue = 0.5;
		option.maxValue = 3.0;
		option.changeValue = 0.05;
		option.displayFormat = '%vX';
		option.decimals = 2;
		optionsArray.push(option);
		#end

		var option:GameplayOption = new GameplayOption('Health Gain Multiplier', 'healthgain', FLOAT, 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Health Loss Multiplier', 'healthloss', FLOAT, 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0.5;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		optionsArray.push(new GameplayOption('Instakill on Miss', 'instakill', BOOL, false));
		optionsArray.push(new GameplayOption('Practice Mode', 'practice', BOOL, false));
		optionsArray.push(new GameplayOption('Botplay', 'botplay', BOOL, false));
	}

	public function getOptionByName(name:String):GameplayOption {
		for(i in optionsArray) {
			var opt:GameplayOption = i;
			if (opt.name == name) return opt;
		}
		return null;
	}

	public function new() {
		super();
		
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		// avoids lagspikes while scrolling through menus!
		add(grpOptions = new FlxTypedGroup<Alphabet>());
		add(grpTexts = new FlxTypedGroup<AttachedText>());
		add(checkboxGroup = new FlxTypedGroup<CheckboxThingie>());
		
		getOptions();

		for (i => option in optionsArray) {
			var optionText:Alphabet = new Alphabet(150, 360, option.name);
			optionText.isMenuItem = true;
			optionText.setScale(.8);
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (option.type == BOOL) {
				optionText.x += 60;
				optionText.startPosition.x += 60;
				optionText.snapToPosition();
				var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, optionsArray[i].getValue() == true);
				checkbox.sprTracker = optionText;
				checkbox.sprOffset.x -= 20;
				checkbox.sprOffset.y = -52;
				checkbox.ID = i;
				checkboxGroup.add(checkbox);
			} else {
				optionText.snapToPosition();
				var valueText:AttachedText = new AttachedText(Std.string(option.getValue()), optionText.width + 40, 0, BOLD, 0.8);
				valueText.sprTracker = optionText;
				valueText.copyAlpha = true;
				valueText.ID = i;
				grpTexts.add(valueText);
				optionsArray[i].setChild(valueText);
			}
			updateTextFrom(option);
		}

		changeSelection();
		reloadCheckboxes();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;
	override function update(elapsed:Float) {
		final justPressedDown:Bool = Controls.justPressed('ui_down');
		if (justPressedDown || Controls.justPressed('ui_up')) changeSelection(justPressedDown ? 1 : -1);

		if (Controls.justPressed('back')) {
			close();
			ClientPrefs.save();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if(nextAccept <= 0) {
			var usesCheckbox:Bool = curOption.type == BOOL;
			if(usesCheckbox) {
				if(Controls.justPressed('accept')) {
					FlxG.sound.play(Paths.sound('scrollMenu'));
					curOption.setValue((curOption.getValue() == true) ? false : true);
					curOption.change();
					reloadCheckboxes();
				}
			} else {
				final leftJustPressed:Bool = Controls.justPressed('ui_left');
				if (leftJustPressed || Controls.justPressed('ui_right')) {
					final leftPressed:Bool = Controls.pressed('ui_left');
					var pressed:Bool = leftPressed || Controls.pressed('ui_right');
					if (holdTime > 0.5 || pressed) {
						if (pressed) {
							var add:Dynamic = null;
							if(curOption.type != STRING)
								add = leftJustPressed ? -curOption.changeValue : curOption.changeValue;

							switch(curOption.type) {
								case INT, FLOAT, PERCENT:
									holdValue = curOption.getValue() + add;
									if(holdValue < curOption.minValue) holdValue = curOption.minValue;
									else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

									switch(curOption.type) {
										case INT:
											holdValue = Math.round(holdValue);
											curOption.setValue(holdValue);

										case FLOAT, PERCENT:
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											curOption.setValue(holdValue);
										default:
									}

								case STRING:
									var num:Int = curOption.curOption; //lol
									if (leftPressed) num--;
									else num++;

									if(num < 0) num = curOption.options.length - 1;
									else if(num >= curOption.options.length) num = 0;

									curOption.curOption = num;
									curOption.setValue(curOption.options[num]); //lol
									
									if (curOption.name == "Scroll Type") {
										var oOption:GameplayOption = getOptionByName("Scroll Speed");
										if (oOption != null) {
											if (curOption.getValue() == "constant") {
												oOption.displayFormat = "%v";
												oOption.maxValue = 6;
											} else {
												oOption.displayFormat = "%vX";
												oOption.maxValue = 3;
												if(oOption.getValue() > 3) oOption.setValue(3);
											}
											updateTextFrom(oOption);
										}
									}
								default:
							}
							updateTextFrom(curOption);
							curOption.change();
							FlxG.sound.play(Paths.sound('scrollMenu'));
						} else if (curOption.type != STRING) {
							holdValue = Math.max(curOption.minValue, Math.min(curOption.maxValue, holdValue + curOption.scrollSpeed * elapsed * (leftJustPressed ? -1 : 1)));
							switch(curOption.type) {
								case INT: curOption.setValue(Math.round(holdValue));	
								case FLOAT, PERCENT: curOption.setValue(FlxMath.roundDecimal(FlxMath.bound(holdValue + curOption.changeValue - (holdValue % curOption.changeValue), curOption.minValue, curOption.maxValue), curOption.decimals));
								default:
							}
							updateTextFrom(curOption);
							curOption.change();
						}
					}

					if (curOption.type != STRING) holdTime += elapsed;
				} else if (Controls.released('ui_left') || Controls.released('ui_right')) clearHold();
			}

			if (Controls.justPressed('reset')) {
				for (i in 0...optionsArray.length) {
					var leOption:GameplayOption = optionsArray[i];
					leOption.setValue(leOption.defaultValue);
					if(leOption.type != BOOL) {
						if(leOption.type == STRING) leOption.curOption = leOption.options.indexOf(leOption.getValue());
						updateTextFrom(leOption);
					}

					if(leOption.name == 'Scroll Speed') {
						leOption.displayFormat = "%vX";
						leOption.maxValue = 3;
						if(leOption.getValue() > 3) leOption.setValue(3);
						updateTextFrom(leOption);
					}
					leOption.change();
				}
				FlxG.sound.play(Paths.sound('cancelMenu'));
				reloadCheckboxes();
			}
		}

		if(nextAccept > 0) nextAccept--;
		super.update(elapsed);
	}

	function updateTextFrom(option:GameplayOption) {
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if(option.type == PERCENT) val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', Std.string(val)).replace('%d', Std.string(def));
	}

	function clearHold() {
		if(holdTime > .5) FlxG.sound.play(Paths.sound('scrollMenu'));
		holdTime = 0;
	}
	
	function changeSelection(change:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + change, 0, optionsArray.length - 1);
		for (num => item in grpOptions.members) {
			item.targetY = num - curSelected;
			item.alpha = 0.6;
			if (item.targetY == 0) item.alpha = 1;
		}
		for (text in grpTexts) {
			text.alpha = 0.6;
			if(text.ID == curSelected) text.alpha = 1;
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function reloadCheckboxes() {
		for (checkbox in checkboxGroup)
			checkbox.daValue = (optionsArray[checkbox.ID].getValue() == true);
	}
}

class GameplayOption {
	var child:Alphabet;
	public var text(get, set):String;
	public var onChange:Void->Void = null; //Pressed enter (on Bool type options) or pressed/held left/right (on other types)
	public var type:OptionType = BOOL;

	public var scrollSpeed:Float = 50; //Only works on int/float, defines how fast it scrolls per second while holding left/right

	var variable:String = null; //Variable from ClientPrefs.hx's gameplaySettings
	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0; //Don't change this
	public var options:Array<String> = null; //Only used in string type
	public var changeValue:Dynamic = 1; //Only used in int/float/percent type, how much is changed when you PRESS
	public var minValue:Dynamic = null; //Only used in int/float/percent type
	public var maxValue:Dynamic = null; //Only used in int/float/percent type
	public var decimals:Int = 1; //Only used in float/percent type

	public var displayFormat:String = '%v'; //How String/Float/Percent/Int values are shown, %v = Current value, %d = Default value
	public var name:String = 'Unknown';

	public function new(name:String, variable:String, type:OptionType, defaultValue:Dynamic = 'null variable value', ?options:Array<String> = null) {
		_name = name;
		this.name = Language.getPhrase('setting_$name', name);
		this.variable = variable;
		this.type = type;
		this.defaultValue = defaultValue;
		this.options = options;

		if(defaultValue == 'null variable value') {
			switch(type) {
				case BOOL: defaultValue = false;
				case INT, FLOAT: defaultValue = 0;
				case PERCENT: defaultValue = 1;
				case STRING:
					defaultValue = '';
					if(options.length > 0) defaultValue = options[0];

				default:
			}
		}

		if(getValue() == null) setValue(defaultValue);

		switch(type) {
			case STRING:
				var num:Int = options.indexOf(getValue());
				if(num > -1) curOption = num;

			case PERCENT:
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;

			default:
		}
	}

	public function change() {
		if(onChange != null) onChange();
	}

	public function getValue():Dynamic return ClientPrefs.data.gameplaySettings.get(variable);
	public function setValue(value:Dynamic) ClientPrefs.data.gameplaySettings.set(variable, value);

	public function setChild(child:Alphabet)
		this.child = child;

	var _name:String = null;
	var _text:String = null;
	function get_text() return _text;
	function set_text(newValue:String = '') {
		if(child != null) {
			_text = newValue;
			child.text = Language.getPhrase('setting_$_name-$_text', _text);
			return _text;
		}
		return null;
	}
}