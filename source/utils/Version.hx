package utils;

import haxe.macro.Expr;
import haxe.macro.Context;
import sys.io.Process;

using StringTools;

class Version {
    public static macro function getGitCommitHash():Expr.ExprOf<String> {
        var process = new Process('git', ['rev-parse', 'HEAD']);
        if (process.exitCode() != 0) {
            var message = process.stderr.readAll().toString();
            Context.error("Cannot execute `git rev-parse HEAD`. " + message, Context.currentPos());
        }

        var parsed_version:String = process.stdout.readLine();
        return macro $v{parsed_version.substring(0, 7)};
    }
}