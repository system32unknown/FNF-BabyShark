package handlers;

import hscript.Interp;
import hscript.Parser;
import hscript.Expr;

#if sys
import sys.io.File;
#end

import states.*;
import game.*;
import ui.*;
import utils.*;

import flixel.*;
import flixel.custom.system.ColoredLog;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;

using StringTools;

class HscriptHandler {
    public var staticVariables:Map<String, Dynamic> = [];

    public var interp:Interp;
    public var expr:Expr;
    public var fileName:String = '';

    public function new(path:String) {
        fileName = path;

        interp = new Interp();

        var parser = new Parser();
        parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;
        interp.errorHandler = __errorHandler;
        interp.staticVariables = staticVariables;
        interp.allowStaticVariables = interp.allowPublicVariables = true;
        setVars();

        try {
            expr = parser.parseString(File.getContent(path));
        } catch(e:Error) {
            __errorHandler(e);
        } catch(e) {
            __errorHandler(new Error(ECustom(e.toString()), 0, 0, fileName, 0));
        }
    }

    public function execute():Interp {
        if (expr != null) {
            interp.execute(expr);
            return interp;
        }
        return null;
    }

    function __errorHandler(error:Error) {
        var fn = '$fileName:${error.line}: ';
        var err = error.toString();
        if (err.startsWith(fn)) err = err.substr(fn.length);

        ColoredLog.error(fn + err);
    }

    function getDefaultVariables():Map<String, Dynamic> {
        return [
            // Haxe related stuff
            "Std"               => Std,
            "Math"              => Math,
            "StringTools"       => StringTools,
            "Json"              => haxe.Json,

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
            "FlxTween"          => FlxTween,
            "FlxSound"          => flixel.system.FlxSound,
            "FlxAssets"         => flixel.system.FlxAssets,
            "FlxMath"           => flixel.math.FlxMath,
            "FlxGroup"          => flixel.group.FlxGroup,
            "FlxTypedGroup"     => flixel.group.FlxGroup.FlxTypedGroup,
            "FlxSpriteGroup"    => flixel.group.FlxSpriteGroup,
            "FlxTypeText"       => flixel.addons.text.FlxTypeText,
            "FlxBackdrop"       => flixel.addons.display.FlxBackdrop,
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
            "Boyfriend"         => Boyfriend,
            "Paths"             => Paths,
            "Conductor"         => Conductor,
            "Alphabet"          => Alphabet,

            "CoolUtil"          => CoolUtil,
            "ClientPrefs"       => ClientPrefs,
        ];
    }

    function setVars() {
        for (key => type in getDefaultVariables()) {
            interp.variables.set(key, type);
        }
    }
}