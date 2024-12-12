package macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class FlxModMacro {
    /**
    * A macro to be called targeting the `FlxBasic` class.
    * @return An array of fields that the class contains.
    */
    public static macro function buildFlxBasic():Array<Field> {
        #if macro
        // The FlxBasic class. We can add new properties to this class.
        // The fields of the FlxClass.
        var fields:Array<Field> = Context.getBuildFields();

        // Here, we add the zIndex attribute to all FlxBasic objects.
        // This has no functional code tied to it, but it can be used as a target value
        // for the FlxTypedGroup.sort method, to rearrange the objects in the scene.
        fields.push({
            name: "zIndex", // Field name.
            pos: Context.currentPos(), // The field's position in code.
            access: [APublic], // Access level
            kind: FVar(macro:Int, macro $v{0}), // Variable type and default value
        });

        return fields;
        #else
        return [];
        #end
    }
}