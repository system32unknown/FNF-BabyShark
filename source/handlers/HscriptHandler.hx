package handlers;

import hscript.Interp;

import states.*;
import substates.*;
import game.*;
import ui.*;
import utils.*;

import flixel.*;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.addons.display.FlxBackdrop;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class HscriptHandler {
    public static function getDefaultVariables():Map<String, Dynamic> {
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
            "FlxTween"          => flixel.tweens.FlxTween,
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
            "PlayState"          => PlayState,
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

    public static function setVars(interp:Interp) {
        for (key => type in getDefaultVariables()) {
            interp.variables.set(key, type);
        }

        return interp;
    }
}