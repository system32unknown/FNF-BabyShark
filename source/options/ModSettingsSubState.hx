package options;

import flixel.input.keyboard.FlxKey;
import objects.Character;

class ModSettingsSubState extends BaseOptionsMenu {
	var save:Map<String, Dynamic> = new Map<String, Dynamic>();
	var folder:String;
	var _crashed:Bool = false;
	public function new(options:Array<Dynamic>, folder:String, name:String) {
		this.folder = folder;

		title = '';
		rpcTitle = 'Mod Settings ($name)'; //for Discord Rich Presence

		if(FlxG.save.data.modSettings == null) FlxG.save.data.modSettings = new Map<String, Dynamic>();
		else {
			var saveMap:Map<String, Dynamic> = FlxG.save.data.modSettings;
			save = saveMap[folder] != null ? saveMap[folder] : [];
		}

		try {
			for (option in options) {
				var newOption = new Option(
					option.name != null ? option.name : option.save,
					option.description != null ? option.description : 'No description provided.',
					option.save,
					option.type,
					option.options
				);

				switch(newOption.type) {
					case 'keybind':
						//Defaulting and error checking
						var keyboardStr:String = option.keyboard;
						if(keyboardStr == null) keyboardStr = 'NONE';

						newOption.defaultKeys.keyboard = keyboardStr;
						if(save.get(option.save) == null) {
							newOption.keys.keyboard = newOption.defaultKeys.keyboard;
							save.set(option.save, newOption.keys);
						}

						// getting inputs and checking
						var keyboardKey:FlxKey = cast FlxKey.fromString(keyboardStr);

						@:privateAccess {
							newOption.getValue = function() {
								var data = save.get(newOption.variable);
								if(data == null) return 'NONE';
								return data.keyboard;
							};
							newOption.setValue = function(value:Dynamic) {
								var data = save.get(newOption.variable);
								if(data == null) data = {keyboard: 'NONE'};
								data.keyboard = value;
								save.set(newOption.variable, data);
							};
						}

					default:
						if(option.value != null)
							newOption.defaultValue = option.value;

						@:privateAccess {
							newOption.getValue = () -> return save.get(newOption.variable);
							newOption.setValue = (value:Dynamic) -> save.set(newOption.variable, value);
						}
				}

				if(option.type != 'keybind') {
					if(option.format != null) newOption.displayFormat = option.format;
					if(option.min != null) newOption.minValue = option.min;
					if(option.max != null) newOption.maxValue = option.max;
					if(option.step != null) newOption.changeValue = option.step;
	
					if(option.scroll != null) newOption.scrollSpeed = option.scroll;
					if(option.decimals != null) newOption.decimals = option.decimals;
	
					var myValue:Dynamic = null;
					if(save.get(option.save) != null) {
						myValue = save.get(option.save);
						if(newOption.type != 'keybind') newOption.setValue(myValue);
						else newOption.setValue(myValue.keyboard);
					} else {
						myValue = newOption.getValue();
						if(myValue == null) myValue = newOption.defaultValue;
					}
	
					switch(newOption.type) {
						case 'string':
							var num:Int = newOption.options.indexOf(myValue);
							if(num > -1) newOption.curOption = num;
					}
	
					save.set(option.save, myValue);
				}
				addOption(newOption);
			}
		} catch(e:Dynamic) {
			var errorTitle = 'Mod name: $folder';
			var errorMsg = 'An error occurred: $e';
			#if windows
			lime.app.Application.current.window.alert(errorMsg, errorTitle);
			#end
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

	override public function update(elapsed:Float) {
		if(_crashed) {
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