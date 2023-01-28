package options;

import ui.Alphabet;

class OptionFunc
{
	private var child:Alphabet;
	public var text(get, set):String;

	public var funcs:Void->Void = null;

	public var description:String = '';
	public var name:String = 'Unknown';

	public function new(name:String, description:String = '', funcs:Void->Void)
	{
		this.name = name;
		this.description = description;
		this.funcs = funcs;
	}

	public function setChild(child:Alphabet)
	{
		this.child = child;
	}

	private function get_text()
	{
		if(child != null) {
			return child.text;
		}
		return null;
	}
	private function set_text(newValue:String = '')
	{
		if(child != null) {
			child.text = newValue;
		}
		return null;
	}
}