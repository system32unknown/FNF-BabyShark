package options;

class Option {
	public var child:Alphabet;
	public var text(get, set):String;
	public var onChange:Void->Void = null; //Pressed enter (on Bool type options) or pressed/held left/right (on other types)

	public var type(get, default):String = 'bool'; //bool, int (or integer), float (or fl), percent, string (or str)
	// Bool will use checkboxes
	// Everything else will use a text
	public var scrollSpeed:Float = 50; //Only works on int/float, defines how fast it scrolls per second while holding left/right

	var variable:String = null; //Variable from ClientPrefs.hx
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

	public function new(name:String, description:String = '', variable:String, type:String = 'bool', ?options:Array<String> = null) {
		this.name = name;
		this.description = description;
		this.variable = variable;
		this.type = type;
		this.defaultValue = ClientPrefs.defaultprefs.get(variable);
		this.options = options;

		if(defaultValue == 'null variable value')
			defaultValue = switch(type) {
				case 'bool': false;
				case 'int' | 'float': 0;
				case 'percent': 1;
				case 'string':
					if(options.length > 0) options[0];
					else '';
				case 'func': '';
				default: null;
			};

		if(type == 'percent') {
			displayFormat = '%v%';
			changeValue = 0.01;
			minValue = 0;
			maxValue = 1;
			scrollSpeed = 0.5;
			decimals = 2;
		}

		try {
			if(getValue() == null)
				setValue(defaultValue);

			switch(type) {
				case 'string':
					var num:Int = options.indexOf(getValue());
					if(num > -1) {
						curOption = num;
					}
			}
		} catch(e) {}
	}

	public function change() {
		if(onChange != null) onChange();
	}

	dynamic public function getValue():Dynamic
		return ClientPrefs.getPref(variable);
	dynamic public function setValue(value:Dynamic)
		ClientPrefs.prefs.set(variable, value);

	function get_text() {
		if(child != null) return child.text;
		return null;
	}
	function set_text(newValue:String = '') {
		if(child != null) child.text = newValue;
		return null;
	}

	function get_type() {
		var newValue:String = 'bool';
		switch(type.toLowerCase().trim()) {
			case 'int' | 'float' | 'percent' | 'string' | 'func': newValue = type;
			case 'integer': newValue = 'int';
			case 'str': newValue = 'string';
			case 'fl': newValue = 'float';
		}
		type = newValue;
		return type;
	}
}