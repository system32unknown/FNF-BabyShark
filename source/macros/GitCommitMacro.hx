package macros;

#if macro
import sys.io.Process;
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class GitCommitMacro {
	/**
	 * Returns the current commit number
	 */
	public static var commitNumber(get, null):Int;
	/**
	 * Returns the current commit hash
	 */
	public static var commitHash(get, null):String;

	// GETTERS
	static inline function get_commitNumber():Int return __getCommitNumber();
	static inline function get_commitHash():String return __getCommitHash();

	// INTERNAL MACROS
	static macro function __getCommitHash() {
		#if !display
		var pos:Position = Context.currentPos();
		try {
			var proc:Process = new Process('git', ['rev-parse', '--short', 'HEAD']);
			if (proc.exitCode() != 0) Context.warning('Could not determine current git commit; is this a proper Git repository?', pos);
			return macro $v{proc.stdout.readLine()};
		} catch (e) Context.error(e.toString(), pos);
		#end
		return macro $v{"-"};
	}
	static macro function __getCommitNumber() {
		#if !display
		var pos:Position = Context.currentPos();
		try {
			var proc:Process = new Process('git', ['rev-list', 'HEAD', '--count']);
			if (proc.exitCode() != 0) Context.warning('Could not determine current git commit; is this a proper Git repository?', pos);
			return macro $v{Std.parseInt(proc.stdout.readLine())};
		} catch (e) Context.error(e.toString(), pos);
		#end
		return macro $v{0};
	}
}