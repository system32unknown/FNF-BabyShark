package options;

import options.Option.OptionType;

class ModSettingsSubState extends BaseOptionsMenu {
	var save:Map<String, Dynamic> = new Map<String, Dynamic>();
	var folder:String;
	var _crashed:Bool = false;
	public function new(options:Array<Dynamic>, folder:String, name:String) {
		this.folder = folder;

		title = '';
		rpcTitle = 'Mod Settings ($name)'; //for Discord Rich Presence

		if (FlxG.save.data.modSettings == null) FlxG.save.data.modSettings = new Map<String, Dynamic>();
		else {
			var saveMap:Map<String, Dynamic> = FlxG.save.data.modSettings;
			save = saveMap[folder] != null ? saveMap[folder] : [];
		}

		try {
			for (option in options) {
				var newOption:Option = new Option(
					option.name ?? option.save,
					option.description ?? 'No description provided.',
					option.save,
					convertType(option.type),
					option.options,
					option.translation_key
				);

				switch(newOption.type) {
					case KEYBIND:
						//Defaulting and error checking
						var keyboardStr:String = option.keyboard;
						if (keyboardStr == null) keyboardStr = 'NONE';

						newOption.defaultKeys.keyboard = keyboardStr;
						if (save.get(option.save) == null) {
							newOption.keys.keyboard = newOption.defaultKeys.keyboard;
							save.set(option.save, newOption.keys);
						}

						// getting inputs and checking
						@:privateAccess {
							newOption.getValue = () -> {
								var data:Dynamic = save.get(newOption.variable);
								if (data == null) return 'NONE';
								return data.keyboard;
							};
							newOption.setValue = (value:Dynamic) -> {
								var data:Dynamic = save.get(newOption.variable);
								if (data == null) data = {keyboard: 'NONE'};
								data.keyboard = value;
								save.set(newOption.variable, data);
							};
						}

					default:
						if (option.value != null) newOption.defaultValue = option.value;
						@:privateAccess {
							newOption.getValue = () -> return save.get(newOption.variable);
							newOption.setValue = (value:Dynamic) -> save.set(newOption.variable, value);
						}
				}

				if (option.type != KEYBIND) {
					if (option.format != null) newOption.displayFormat = option.format;
					if (option.min != null) newOption.minValue = option.min;
					if (option.max != null) newOption.maxValue = option.max;
					if (option.step != null) newOption.changeValue = option.step;
	
					if (option.scroll != null) newOption.scrollSpeed = option.scroll;
					if (option.decimals != null) newOption.decimals = option.decimals;
	
					var myValue:Dynamic = null;
					if (save.get(option.save) != null) {
						myValue = save.get(option.save);
						if (newOption.type != KEYBIND) newOption.setValue(myValue);
						else newOption.setValue(myValue.keyboard);
					} else {
						myValue = newOption.getValue();
						if (myValue == null) myValue = newOption.defaultValue;
					}
	
					switch(newOption.type) {
						case STRING:
							var num:Int = newOption.options.indexOf(myValue);
							if (num > -1) newOption.curOption = num;
						default:
					}
	
					save.set(option.save, myValue);
				}
				addOption(newOption);
			}
		} catch (e:Dynamic) {
			var errorTitle:String = 'Mod name: $folder';
			var errorMsg:String = 'An error occurred: $e';
			utils.system.NativeUtil.showMessageBox(errorMsg, errorTitle);
			Logs.trace('$errorTitle - $errorMsg', ERROR);
			_crashed = true;
			close();
			return;
		}

		super();

		bg.alpha = .75;
		bg.color = FlxColor.WHITE;
		reloadCheckboxes();
	}

	function convertType(str:String):OptionType {
		return switch(str.toLowerCase().trim()) {
			case 'bool': BOOL;
			case 'int', 'integer': INT;
			case 'float', 'fl': FLOAT;
			case 'percent': PERCENT;
			case 'string', 'str': STRING;
			case 'keybind', 'key': KEYBIND;
			case 'function', 'func': FUNC;
			default:
				FlxG.log.error("Could not find option type: " + str);
				BOOL;
		}
	}

	override public function update(elapsed:Float) {
		if (_crashed) {
			close();
			return;
		}
		super.update(elapsed);
	}

	override public function close() {
		FlxG.save.data.modSettings.set(folder, save);
		FlxG.save.flush();
		super.close();
	}
}