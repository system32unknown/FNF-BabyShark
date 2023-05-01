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

class AlterScript {
    public var staticVariables:Map<String, Dynamic> = [];

    var interp:Interp;
    var parser:Parser;

    public var scriptFile(default, null):String = "";
    public var script(default, null):String = "";
    public var expr:Expr;

    static var hadError:Bool = false;

    public function new(path:String, ?autoRun:Bool = true) {
        if (path != ""  && path != null) {
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
        parser.preprocesorValues = getDefaultPreprocessors();
        parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;
        parser.line = 1;

        setVars();

        if (autoRun) execute();
    }

    public function execute() {
        try {
            expr = parser.parseString(script, scriptFile);
        } catch(e:Error) {
            _errorHanding(e);
        } catch(e) {_errorHanding(new Error(ECustom(e.toString()), 0, 0, scriptFile, 0));}

        if (!hadError && interp != null) interp.execute(expr);
        else stop();
    }

    function get(key:String):Dynamic {
        return if (exists(key)) interp.variables.get(key) else null;
    }

    public function call(func:String, args:Array<Dynamic>):Dynamic {
        if (func == null || args == null || !exists(func)) return null;
        return Reflect.callMethod(this, get(func), args);
    }

    function exists(key:String):Bool {
        if (interp == null) return false;
        return interp.variables.exists(key);
    }

    public function stop()
    {
        #if HSCRIPT_ALLOWED
        interp = null;
        parser = null;
        #end
    }

    function getDefaultPreprocessors():Map<String, Bool> {
        return [
            "sys" => #if sys true #else false #end,
            "cpp" => #if cpp true #else false #end,
            "desktop" => #if desktop true #else false #end,
            "windows" => #if windows true #else false #end,
            "hl" => #if hl true #else false #end,
            "neko" => #if neko true #else false #end,
            "web" => #if web true #else false #end,
            "debug" => #if debug true #else false #end,
            "release" => #if release true #else false #end,
            "final" => #if final true #else false #end,
            "MODS_ALLOWED" => #if MODS_ALLOWED true #else false #end,
            "LUA_ALLOWED" => #if LUA_ALLOWED true #else false #end,
            "VIDEOS_ALLOWED" => #if VIDEOS_ALLOWED true #else false #end,
            "CRASH_HANDLER" => #if CRASH_HANDLER true #else false #end
        ];
    }

    function getDefaultVariables():Map<String, Dynamic> {
        return [
            // Haxe related stuff
            "Std"               => Std,
            "Sys"               => Sys,
            "Math"              => Math,
            "Date"              => Date,
            "StringTools"       => StringTools,
            "DateTools"         => DateTools,
            "Reflect"           => Reflect,
            "AlterScript"       => this,

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
            "FlxEase"           => flixel.tweens.FlxEase,
            "FlxTween"          => flixel.tweens.FlxTween,
            "FlxSound"          => flixel.system.FlxSound,
            "FlxAssets"         => flixel.system.FlxAssets,
            "FlxMath"           => flixel.math.FlxMath,
            "FlxGroup"          => flixel.group.FlxGroup,
            "FlxTypedGroup"     => flixel.group.FlxGroup.FlxTypedGroup,
            "FlxSpriteGroup"    => flixel.group.FlxSpriteGroup,
            "FlxTypeText"       => flixel.addons.text.FlxTypeText,
            "FlxText"           => flixel.text.FlxText,
            "FlxTimer"          => flixel.util.FlxTimer,
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
            "Boyfriend"         => Boyfriend,
            "Paths"             => Paths,
            "Conductor"         => Conductor,
            "Alphabet"          => Alphabet,

            "CoolUtil"          => CoolUtil,
            "ClientPrefs"       => ClientPrefs,

            "FlxTrail" => flixel.addons.effects.FlxTrail,
            "FlxBackdrop" => flixel.addons.display.FlxBackdrop,
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
        call("create", []);
    }

    function callErrBox(title:String, context:String) {
        #if hl
		var flags:haxe.EnumFlags<hl.UI.DialogFlags> = new haxe.EnumFlags<hl.UI.DialogFlags>();
		flags.set(IsError);
		hl.UI.dialog(title, context, flags);
		#else
		lime.app.Application.current.window.alert(context, title);
		#end
    }

    function _errorHanding(e:Error) {
        var fn = '$scriptFile:${e.line}: ';
        var err = e.toString();
        if (err.startsWith(fn)) err = err.substr(fn.length);

        callErrBox("Error on AlterScript", "Uncaught Error: " + fn + '\n$err');
        hadError = true;
    }
}