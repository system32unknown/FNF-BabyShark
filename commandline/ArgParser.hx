package;

using StringTools;

class ArgParser {
	public static function parse(args:Array<String>, ?renameMap:Map<String, String> = null):ArgParser {
		return new ArgParser(args, renameMap);
	}

	private function new(args:Array<String>, ?renameMap:Map<String, String>) {
		if (renameMap == null) renameMap = new Map();
		function rename(name:String):Null<String> {
			return renameMap.exists(name) ? renameMap.get(name) : name;
		}
		this.args = args;

		this.options = new Map();
		final copy:Array<String> = args.copy();
		var i:Int = 0;
		while(copy.length > 0) {
			var arg = copy.shift();
			// this parses the -NAME=VALUE
			if (arg.startsWith("-")) {
				var key:String = arg.substr(1);
				final isLongKey:Bool = key.startsWith("-");
				if (isLongKey) key = key.substr(1);

				final split:Array<String> = key.split("=");
				var longName:Null<String> = split.shift();
				if (!isLongKey) {
					// Allow -ABC to be parsed as -A -B -C
					// Values will only work for the last one
					while(longName.length > 1) {
						var name:Null<String> = rename(longName.charAt(0));
						options.set(name, null);
						longName = longName.substr(1);
					}

					longName = longName.charAt(0);
					// Parse the last option with value support
				}

				final name:Null<String> = rename(longName);
				final value:Null<Null<String>> = (split.length > 0) ? split.join("=") : null;
				options.set(name, value);

				args.splice(i, 1);
				i--;
			}

			i++;
		}
	}

	/**
	 * Options are arguments that start with a "-", if they are followed by an "=" they are a key/value pair.
	 * otherwise they are stored as a key with an null value.
	**/
	public var options(default, null):Map<String, String>;
	public var args(default, null):Array<String>;

	public var length(get, never):Int;
	inline function get_length():Int {
		return args.length;
	}

	public function get(index:Int):String {
		return args[index];
	}

	public function existsOption(name:String):Bool {
		return options.exists(name);
	}

	public function getOption(name:String):String {
		return options.get(name);
	}
}