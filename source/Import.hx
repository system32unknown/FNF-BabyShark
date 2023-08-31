#if !macro
#if LUA_ALLOWED
import llua.*;
import llua.Lua;
#end

#if discord_rpc import backend.Discord; #end
import backend.Paths;
import backend.Controls;
import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import backend.CustomFadeTransition;
import backend.ClientPrefs;
import backend.Conductor;
import backend.BaseStage;
import backend.Difficulty;
import backend.Logs;
#if MODS_ALLOWED import backend.Mods; #end
import utils.CoolUtil;
import utils.SpriteUtil;

import objects.Alphabet;
import objects.BGSprite;

import states.PlayState;
import states.LoadingState;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
#end

using StringTools;