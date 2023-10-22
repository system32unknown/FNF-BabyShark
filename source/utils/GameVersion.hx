package utils;

class GameVersion {
	public var release(default, null):Int;
	public var major(default, null):Int;
	public var minor(default, null):Int;
	public var patch(default, null):String;
	public var version(get, never):String;

	public var COMMIT_HASH(get, never):String;
	public function get_COMMIT_HASH():String return macros.GitCommitMacro.commitHash;
	public var COMMIT_NUM(get, never):Int;
	public function get_COMMIT_NUM():Int return macros.GitCommitMacro.commitNumber;

	public function new(release:Int, major:Int, minor:Int, ?patch:String = '') {
		this.release = release;
		this.major = major;
		this.minor = minor;
		this.patch = patch;
	}

	function get_version():String
		return '$release.$major.$minor$patch';
}