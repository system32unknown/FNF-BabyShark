package utils;

import macros.GitCommitMacro;

/**
 * Represents a semantic-style game version string.
 *
 * Format:
 * `MAJOR.MINOR.PATCH[-PRERELEASE]`
 *
 * Examples:
 * - `1.0.0`
 * - `1.2.3-beta`
 * - `2.0.0-rc1`
 *
 * This abstract allows accessing and modifying version components
 * (major, minor, patch, prerelease_id) while internally storing a String.
 *
 * Supports comparison operators (==, >, >=).
 */
abstract GameVersion(String) from String to String {
	/**
	 * Major version number.
	 */
	public var major(get, set):Int;

	/**
	 * Minor version number.
	 */
	public var minor(get, set):Int;

	/**
	 * Patch version number.
	 */
	public var patch(get, set):Int;

	/**
	 * Optional prerelease identifier.
	 *
	 * Example: `beta`, `rc1`, `alpha-2`
	 */
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

	/**
	 * Git commit hash of the current build.
	 *
	 * Generated at compile time via macro.
	 */
	public var COMMIT_HASH(get, never):String;
	function get_COMMIT_HASH():String return GitCommitMacro.commitHash;

	/**
	 * Git commit number of the current build.
	 *
	 * Generated at compile time via macro.
	 */
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