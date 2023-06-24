package scripting.haxe;

import hscript.*;
import hscript.Expr.Error;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

import game.*;
import ui.*;
import utils.*;
import flixel.*;
import states.PlayState; // fucking flixel

class AlterScript {
    public var staticVariables:Map<String, Dynamic> = [];

    var interp:Interp;
    var parser:Parser;

    public var scriptFile(default, null):String = "";
    public var script(default, null):String = "";
    public var expr:Expr;

    static var hadError:Bool = false;

    public function new(path:String) {
        if (path != "" && path != null) {
            if (FileSystem.exists(path))
                script = File.getContent(path);
            else script = path;

            scriptFile = path;
        }

        if (hadError) {
            script = 'trace("Replaced script to continue gameplay");';
            hadError = false;
        }

        interp = new Interp();
        interp.allowStaticVariables = interp.allowPublicVariables = true;
        interp.staticVariables = staticVariables;
        interp.errorHandler = _errorHanding;

        parser = new Parser();
        parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;
        parser.preprocesorValues = getDefaultPreprocessors();

        setVars();
        execute();
    }

    public function execute() {
        try {
            if (script != null && script.trim() != "")
                expr = parser.parseString(script, scriptFile);
        } catch(e:Error) {
            _errorHanding(e);
        } catch(e) _errorHanding(new Error(ECustom(e.toString()), 0, 0, scriptFile, 0));

        if (!hadError && interp != null) interp.execute(expr);
        else stop();
    }

    function get(key:String):Dynamic {
        return if (exists(key)) interp.variables.get(key) else null;
    }

    public function call(func:String, ?args:Array<Any>):Dynamic {
        if (func == null || !exists(func)) return null;
        if (args == null) args = [];
        return Reflect.callMethod(this, get(func), args);
    }

    function exists(key:String):Bool {
        if (interp == null) return false;
        return interp.variables.exists(key);
    }

    public function stop() {
        #if HSCRIPT_ALLOWED
        interp = null;
        parser = null;
        PlayState.instance.scriptArray.remove(this);
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
        interp.variables.set("trace", Reflect.makeVarArgs((args) -> {
            var v:String = Std.string(args.shift());
            for (a in args) v += ", " + Std.string(a);
            trace(v);
        }));
        call("create");
    }

    function _errorHanding(e:Error) {
        var fn = '$scriptFile:${e.line}: ';
        var err = e.toString();
        if (err.startsWith(fn)) err = err.substr(fn.length);
        trace('Error on AlterScript: $err');
        CoolUtil.callErrBox("Error on AlterScript", "Uncaught Error: " + fn + '\n$err');
        hadError = true;
        stop();
    }
}