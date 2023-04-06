package utils;

class GameVersion {
	public var release(default, null):Int;
	public var major(default, null):Int;
	public var minor(default, null):Int;
	public var patch(default, null):String;
	public var version(get, never):String;

	public function new(Release:Int, Major:Int, Minor:Int, ?Patch:String = '') {
		release = Release;
		major = Major;
		minor = Minor;
		patch = Patch;
	}

	function get_version():String
		return '$release.$major.$minor$patch';
}