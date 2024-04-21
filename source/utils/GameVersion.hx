package utils;

@:build(macros.GameBuildTime.getBuildTime())
class GameVersion {
	public var release(default, null):Int;
	public var major(default, null):Int;
	public var minor(default, null):Int;
	public var patch(default, null):String;

	public var debugVersion(get, never):String;
	function get_debugVersion():String return '$release.$major.$minor$patch (${GameVersion.buildTime})';

	public var COMMIT_HASH(get, never):String;
	function get_COMMIT_HASH():String return macros.GitCommitMacro.commitHash;
	public var COMMIT_NUM(get, never):Int;
	function get_COMMIT_NUM():Int return macros.GitCommitMacro.commitNumber;

	public function new(release:Int, major:Int, minor:Int, ?patch:String = '') {
		this.release = release;
		this.major = major;
		this.minor = minor;
		this.patch = patch;
	}

	public var version(get, never):String;
	function get_version():String return '$release.$major.$minor$patch';
}