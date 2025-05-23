package macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class ReflectMacro {
	macro public static function generateReflectionLike(totalArgs:Int, funcName:String, argsName:String):Expr {
		#if macro
		totalArgs++;

		var funcCalls:Array<Expr> = [];
		for (i in 0...totalArgs) {
			var args:Array<Expr> = [for (d in 0...i) macro $i{argsName}[$v{d}]];
			funcCalls.push(macro $i{funcName}($a{args}));
		}

		return {
			pos: Context.currentPos(),
			expr: ESwitch(macro($i{argsName}.length), [
				for (i in 0...totalArgs) {
					values: [macro $v{i}],
					expr: funcCalls[i],
					guard: null,
				}
			], macro throw "Too many arguments")
		};
		#end
	}
}
