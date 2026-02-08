package funkin.utils;

import funkin.macros.GitCommitMacro;

abstract GameVersion(String) from String to String {
	public var major(get, set):Int;
	public var minor(get, set):Int;
	public var patch(get, set):Int;
	public var prerelease_id(get, set):String;

	inline function get_prerelease_id():String {
		var shit:Array<String> = this.split("-");
		shit.shift();
		return shit.join("-");
	}

	inline function set_prerelease_id(id:String):String {
		var shit:Array<String> = this.split("-");
		var prefix:String = shit.shift();
		this = prefix + "-" + id;
		return id;
	}

	inline function strip_prerelease():String {
		return this.split("-").shift();
	}

	inline function get_major():Int
		return Std.parseInt(strip_prerelease().split(".")[0]);

	inline function get_minor():Int
		return Std.parseInt(strip_prerelease().split(".")[1]);

	inline function get_patch():Int
		return Std.parseInt(strip_prerelease().split(".")[2]);

	inline function set_major(i:Int):Int {
		var s:String = Std.string(i);
		this = '$s.$minor.$patch-$prerelease_id';
		return i;
	}

	inline function set_minor(i:Int):Int {
		var s:String = Std.string(i);
		this = '$major.$s.$patch-$prerelease_id';
		return i;
	}

	inline function set_patch(i:Int):Int {
		var s:String = Std.string(i);
		this = '$major.$minor.$s-$prerelease_id';
		return i;
	}

	public var COMMIT_HASH(get, never):String;
	function get_COMMIT_HASH():String return GitCommitMacro.commitHash;
	public var COMMIT_NUM(get, never):Int;
	function get_COMMIT_NUM():Int return GitCommitMacro.commitNumber;

	// operators
	@:op(A == B)
	static function eq(A:GameVersion, B:GameVersion):Bool
		return A.major == B.major && A.minor == B.minor && A.patch == B.patch && A.prerelease_id == B.prerelease_id;

	@:op(A >= B)
	static function gte(A:GameVersion, B:GameVersion):Bool {
		if (A.major >= B.major || A.minor >= B.minor || A.patch >= B.patch) {
			return true;
		} else {
			if (A.prerelease_id.trim() == '' && B.prerelease_id.trim() != '') {
				return true;
			} else if (B.prerelease_id.trim() != '' && A.prerelease_id >= B.prerelease_id) {
				return true;
			} else return false;
		}

		return false;
	}

	@:op(A > B)
	static function gt(A:GameVersion, B:GameVersion):Bool {
		if (A.major > B.major || A.minor > B.minor || A.patch > B.patch) {
			return true;
		} else {
			if (A.prerelease_id.trim() == '' && B.prerelease_id.trim() != '') {
				return true;
			} else if (B.prerelease_id.trim() != '' && A.prerelease_id > B.prerelease_id) {
				return true;
			} else return false;
		}

		return false;
	}
}