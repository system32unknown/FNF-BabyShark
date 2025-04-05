package options;

typedef Keybind = {
	keyboard:String
}

enum OptionType {
	// Bool will use checkboxes
	// Everything else will use a text
	BOOL;
	INT;
	FLOAT;
	PERCENT;
	STRING;
	KEYBIND;
	FUNC;
}

class Option {
	public var child:Alphabet;
	public var text(get, set):String;
	public dynamic function onChange() {} // Pressed enter (on Bool type options) or pressed/held left/right (on other types)
	public var type:OptionType = BOOL;

	public var scrollSpeed:Float = 50; //Only works on int/float, defines how fast it scrolls per second while holding left/right
	public var variable(default, null):String = null; //Variable from Settings.hx
	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0; //Don't change this
	public var options:Array<String> = null; //Only used in string type
	public var changeValue:Dynamic = 1; //Only used in int/float/percent type, how much is changed when you PRESS
	public var minValue:Dynamic = null; //Only used in int/float/percent type
	public var maxValue:Dynamic = null; //Only used in int/float/percent type
	public var decimals:Int = 1; //Only used in float/percent type

	public var displayFormat:String = '%v'; //How String/Float/Percent/Int values are shown, %v = Current value, %d = Default value
	public var description:String = '';
	public var name:String = 'Unknown';

	public var defaultKeys:Keybind = null; //Only used in keybind type
	public var keys:Keybind = null; //Only used in keybind type

	public function new(name:String, description:String = '', variable:String, type:OptionType = BOOL, ?options:Array<String> = null, ?translation:String = null) {
		_name = name;
		_translationKey = translation ?? _name;
		this.name = Language.getPhrase('setting_$_translationKey', name);
		this.description = Language.getPhrase('description_$_translationKey', description);
		this.variable = variable;
		this.type = type;
		this.options = options;

		if (this.type != KEYBIND) this.defaultValue = Reflect.getProperty(Settings.default_data, variable);
		switch (type) {
			case BOOL:
				if (defaultValue == null) defaultValue = false;
			case INT, FLOAT:
				if (defaultValue == null) defaultValue = 0;
			case PERCENT:
				if (defaultValue == null) defaultValue = 1;
				displayFormat = '%v%';
				changeValue = .01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = .5;
				decimals = 2;
			case STRING:
				if (options.length > 0) defaultValue = options[0];
				if (defaultValue == null) defaultValue = '';
			case FUNC: if (defaultValue == null) defaultValue = '';

			case KEYBIND:
				defaultValue = '';
				defaultKeys = {keyboard: 'NONE'};
				keys = {keyboard: 'NONE'};
		}

		try {
			if (getValue() == null) setValue(defaultValue);

			switch (type) {
				case STRING:
					var num:Int = options.indexOf(getValue());
					if (num > -1) curOption = num;
				default:
			}
		} catch (e:Dynamic) {}
	}

	public function change() {
		onChange();
	}

	dynamic public function getValue():Dynamic {
		var value:Dynamic = Reflect.getProperty(Settings.data, variable);
		if (type == KEYBIND) return value.keyboard;
		return value;
	}

	dynamic public function setValue(value:Dynamic) {
		if (type == KEYBIND) {
			var keys:Dynamic = Reflect.getProperty(Settings.data, variable);
			keys.keyboard = value;
			return;
		}
		Reflect.setProperty(Settings.data, variable, value);
	}

	var _name:String = null;
	var _text:String = null;
	var _translationKey:String = null;
	function get_text():String return _text;

	function set_text(newValue:String = ''):String {
		if (child != null) {
			_text = newValue;
			child.text = Language.getPhrase('setting_$_translationKey-${getValue()}', _text);
			return _text;
		}
		return null;
	}
}