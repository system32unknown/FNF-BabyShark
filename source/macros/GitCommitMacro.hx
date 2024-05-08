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

	/**
	 * Returns the current commit branch
	 */
	public static var commitBranch(get, null):String;

	// GETTERS
	static inline function get_commitNumber() return getGitCommitNumber();
	static inline function get_commitHash() return getGitCommitHash();
	static inline function get_commitBranch() return getGitBranch();

	/**
	 * Get the SHA1 hash of the current Git commit.
	 */
	static macro function getGitCommitHash() {
		#if !display
		// Get the current line number.
		var pos:Position = Context.currentPos();

		var process:Process = new Process('git', ['rev-parse', 'HEAD']);
		if (process.exitCode() != 0)
			Context.info('[WARN] Could not determine current git commit; is this a proper Git repository?', pos);

		// read the output of the process
		return macro $v{process.stdout.readLine().substr(0, 7)};
		#else
		return macro $v{""};
		#end
	}

	/**
	 * Get the Number of the current Git commit.
	 */
	static macro function getGitCommitNumber() {
		#if !display
		// Get the current line number.
		var pos:Position = Context.currentPos();

		var process:Process = new Process('git', ['rev-parse', 'HEAD', '--count']);
		if (process.exitCode() != 0)
			Context.info('[WARN] Could not determine current git commit; is this a proper Git repository?', pos);

		return macro $v{Std.parseInt(process.stdout.readLine())};
		#else
		return macro $v{0};
		#end
	}

	/**
	 * Get the branch name of the current Git commit.
	 */
	static macro function getGitBranch() {
		#if !display
		// Get the current line number.
		var pos = Context.currentPos();
		var branchProcess:Process = new Process('git', ['rev-parse', '--abbrev-ref', 'HEAD']);

		if (branchProcess.exitCode() != 0)
			Context.info('[WARN] Could not determine current git commit; is this a proper Git repository?', pos);

		return macro $v{branchProcess.stdout.readLine()};
		#else
		return macro $v{""};
		#end
	}
}
