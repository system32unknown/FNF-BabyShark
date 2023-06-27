package scripting.haxe;

import hscript.*;
import hscript.Expr.Error;

#if sys
import sys.io.File;
import sys.FileSystem;
#else import lime.utils.Assets; #end

import game.*;
import ui.*;
import utils.*;
import flixel.*;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import states.PlayState; // fucking flixel

class AlterScript implements IFlxDestroyable {
    public var staticVariables:Map<String, Dynamic> = [];

    var interp:Interp;
    var parser:Parser;

    public var scriptFile(default, null):String = "";
    public var script(default, null):String = "";

    public var loaded:Bool = false;

    public function new(path:String) {
        if (path != "" && path != null) {
            #if sys
            if (FileSystem.exists(path))
                script = File.getContent(path);
            else script = path;
            #else script = Assets.getText(path); #end

            scriptFile = path;
        }

        interp = new Interp();
        interp.allowStaticVariables = interp.allowPublicVariables = true;
        interp.staticVariables = staticVariables;
        interp.errorHandler = _errorHanding;

        parser = new Parser();
        parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;
        parser.preprocesorValues = getDefaultPreprocessors();

        setVars();

        if (path != null) try {
            interp.execute(getExprFromStr(script));
            trace("haxe file loaded successfully: " + path);
            loaded = true;
        } catch (e:Dynamic) trace('$e');
    }

    public function getExprFromStr(code:String) {
        var expr:Expr = null;
        try {
            expr = parser.parseString(code, scriptFile);
        } catch(e:Error) {
            _errorHanding(e);
        } catch(e) _errorHanding(new Error(ECustom(e.toString()), 0, 0, scriptFile, parser.line));
        return expr;
    }

    public function set(k:String, v:Dynamic):Void {
        if (interp != null) interp.variables.set(k, v);
    }
    function get(key:String):Dynamic {
        return if (exists(key)) interp.variables.get(key) else null;
    }

    public function call(func:String, ?args:Array<Any>):Dynamic {
        if (func == null || !exists(func)) return null;
        if (args == null) args = [];
        return Reflect.callMethod(null, get(func), args);
    }

    function exists(key:String):Bool {
        if (interp == null) return false;
        return interp.variables.exists(key);
    }

    public function destroy() {
        #if HSCRIPT_ALLOWED
        interp = null;
        parser = null;
        loaded = false;
        #end
    }

    function getDefaultPreprocessors():Map<String, Dynamic> {
        var defines = macro.DefinesMacro.defines;
        defines.set("version", lime.app.Application.current.meta.get('version'));
        defines.set("sys", #if sys true #else false #end);
        defines.set("cpp", #if cpp true #else false #end);
        defines.set("desktop", #if desktop true #else false #end);
        defines.set("windows", #if windows true #else false #end);
        defines.set("hl", #if hl true #else false #end);
        defines.set("neko", #if neko true #else false #end);
        defines.set("debug", #if debug true #else false #end);
        defines.set("release", #if release true #else false #end);
        defines.set("final", #if final true #else false #end);
        defines.set("MODS_ALLOWED", #if MODS_ALLOWED true #else false #end);
        defines.set("LUA_ALLOWED", #if LUA_ALLOWED true #else false #end);
        defines.set("VIDEOS_ALLOWED", #if VIDEOS_ALLOWED true #else false #end);
        return defines;
    }

    function getDefaultVariables():Map<String, Dynamic> {
        return [
            // Haxe related stuff
            "Std"               => Std,
            "Sys"               => Sys,
            "Math"              => Math,
            "Date"              => Date,
            "StringTools"       => StringTools,
            "Reflect"           => Reflect,
            "Xml"               => Xml,

            "Json"              => haxe.Json,
            "File"              => File,
            "FileSystem"        => FileSystem,

            // OpenFL & Lime related stuff
            "Assets"            => openfl.utils.Assets,
            "Application"       => lime.app.Application,
            "window"            => lime.app.Application.current.window,

            // Flixel related stuff
            "FlxG"              => FlxG,
            "FlxSprite"         => FlxSprite,
            "FlxBasic"          => FlxBasic,
            "FlxCamera"         => FlxCamera,
            "state"             => FlxG.state,
            "FlxEase"           => FlxEase,
            "FlxTween"          => FlxTween,
            "FlxSound"          => flixel.sound.FlxSound,
            "FlxAssets"         => flixel.system.FlxAssets,
            "FlxMath"           => FlxMath,
            "FlxGroup"          => flixel.group.FlxGroup,
            "FlxTypedGroup"     => FlxTypedGroup,
            "FlxSpriteGroup"    => FlxSpriteGroup,
            "FlxTypeText"       => flixel.addons.text.FlxTypeText,
            "FlxText"           => FlxText,
            "FlxTimer"          => FlxTimer,
            "FlxPoint"          => CoolUtil.getMacroAbstractClass("flixel.math.FlxPoint"),
            "FlxAxes"           => CoolUtil.getMacroAbstractClass("flixel.util.FlxAxes"),
            "FlxColor"          => CoolUtil.getMacroAbstractClass("flixel.util.FlxColor"),
            "FlxKey"            => CoolUtil.getMacroAbstractClass("flixel.input.keyboard.FlxKey"),

            // Engine related stuff
            "PlayState"         => PlayState,
            "game"              => PlayState.instance,
            "Note"              => Note,
            "NoteSplash"        => NoteSplash,
            "HealthIcon"        => HealthIcon,
            "StrumLine"         => StrumNote,
            "Character"         => Character,
            "Paths"             => Paths,
            "Conductor"         => Conductor,
            "Alphabet"          => Alphabet,

            "CoolUtil"          => CoolUtil,
            "ClientPrefs"       => ClientPrefs,

            "DeltaTrail" => DeltaTrail,
        ];
    }

    function setVars() {
        for (key => type in getDefaultVariables()) {
            interp.variables.set(key, type);
        }
        set("trace", Reflect.makeVarArgs((args) -> {
            var v:String = Std.string(args.shift());
            for (a in args) v += ", " + Std.string(a);
            trace(v);
        }));
		set('setVar', function(name:String, value:Dynamic) {
			PlayState.instance.variables.set(name, value);
		});
		set('getVar', function(name:String) {
			var result:Dynamic = null;
			if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
			return result;
		});
		set('removeVar', function(name:String) {
			if(PlayState.instance.variables.exists(name)) {
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});
        call("create");
    }

    function _errorHanding(e:Error) {
        var fn = '$scriptFile:${e.line}: ';
        var err = e.toString();
        if (err.startsWith(fn)) err = err.substr(fn.length);
        trace('Error on AlterScript: $err');
        CoolUtil.callErrBox("Error on AlterScript", "Uncaught Error: " + fn + '\n$err');
    }
}