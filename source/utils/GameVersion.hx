package utils;

import macros.GitCommitMacro;
class GameVersion {
	public var release(default, null):Int;
	public var major(default, null):Int;
	public var minor(default, null):Int;
	public var patch(default, null):String;

	public var COMMIT_HASH(get, never):String;
	function get_COMMIT_HASH():String return GitCommitMacro.commitHash;
	public var COMMIT_NUM(get, never):Int;
	function get_COMMIT_NUM():Int return GitCommitMacro.commitNumber;

	public function new(release:Int, major:Int, minor:Int, ?patch:String = '') {
		this.release = release;
		this.major = major;
		this.minor = minor;
		this.patch = patch;
	}

	public var version(get, never):String;
	function get_version():String return '$release.$major.$minor$patch';

	@:op(A==B)
	static function eq(A:GameVersion, B:GameVersion):Bool
		return A.release == B.release && A.major == B.major && A.minor == B.minor;
}