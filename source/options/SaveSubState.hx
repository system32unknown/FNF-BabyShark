package options;

using StringTools;

class SaveSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Save';
		rpcTitle = 'Save Menu'; //for Discord Rich Presence

		var option:Option = new Option('FPS Counter',
			'If unchecked, hides the FPS Counter.',
			'showFPS',
			'bool',
			true);
		addOption(option);

		super();
	}
}