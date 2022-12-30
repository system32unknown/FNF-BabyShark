package options;

using StringTools;

class SaveSubState extends FuncOptionsMenu
{
	public function new()
	{
		title = 'Save';
		rpcTitle = 'Save Menu'; //for Discord Rich Presence

		var option:OptionFunc = new OptionFunc('Delete Saves', "test", function() {
			trace("hi");
		});
		addOption(option);

		super();
	}
}