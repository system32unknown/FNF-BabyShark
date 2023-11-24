package macros;

#if macro
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class MacroFunctions {
    public static macro function nameOf(e:Expr):Expr {
        Context.typeExpr(e);
        return switch (e.expr) {
            case EConst(CIdent(s)): macro $v{s};
            default: Context.error("nameOf requires an indentifier as argument", Context.currentPos());
        }
    }
    public static macro function validateJson(path:String) {
        if (FileSystem.exists(path)) {
            var content = File.getContent(path);
            try { haxe.Json.parse(content);
            } catch (error:String) {
                // create position inside the json, FlashDevelop handles this very nice.
                var position = Std.parseInt(error.split("position").pop());
                var pos = Context.makePosition({
                    min:position,
                    max:position + 1,
                    file:path
                });
                Context.error(path + " is not valid Json. " + error, pos);
            }
        } else Context.warning(path + " does not exist", Context.currentPos());
        return macro null;
      }
}