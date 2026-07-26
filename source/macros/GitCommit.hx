package macros;

#if !LIME_DISPLAY
import sys.io.Process;
import haxe.macro.Context;
import haxe.macro.Expr;
#end

@:nullSafety
class GitCommit {
	/**
	 * Get the SHA1 hash of the current Git commit.
	 */
	public static var commitHash(get, null):Null<String>;

	/**
	 * Returns the current commit branch.
	 */
	public static var commitBranch(get, null):Null<String>;

	// GETTERS
	static inline function get_commitHash():Null<String> return __getCommitHash();
	static inline function get_commitBranch():Null<String> return __getCommitBranch();

	static macro function __getCommitHash():ExprOf<String> {
		if (Context.defined('display')) return macro '';

		var proc:Process = new Process('git', ['rev-parse', 'HEAD']);

		var pos:Position = Context.currentPos();
		if (proc.exitCode() != 0) Context.warning('Could not determine current git commit; is this a proper Git repository?', pos);

		var commitHash:String = proc.stdout.readLine();
		var commitHashSplice:String = commitHash.substr(0, 7);

		proc.close();

		return macro $v{commitHashSplice};
	}

	static macro function __getCommitBranch():ExprOf<String> {
		if (Context.defined('display')) return macro '';

		var pos:Position = Context.currentPos();
		var proc:Process = new Process('git', ['rev-parse', '--abbrev-ref', 'HEAD']);

		if (proc.exitCode() != 0) Context.warning('Could not determine current git commit; is this a proper Git repository?', pos);

		var branchName:String = proc.stdout.readLine();
		proc.close();

		return macro $v{branchName};
	}
}
