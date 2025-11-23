#if !macro
#if DISCORD_ALLOWED
import backend.Discord;
#end

import debug.Logs;

#if AWARDS_ALLOWED
import backend.Awards;
#end

#if sys
import sys.*;
import sys.io.*;
#end

import backend.Paths;
import backend.Controls;
import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import backend.Transition;
import backend.Settings;
import backend.Conductor;
import backend.BaseStage;
import backend.Difficulty;
import backend.Mods;
import backend.Language;
import backend.EK;

import backend.ui.*; // Psych-UI

import utils.Util;
import utils.SpriteUtil;

import objects.Alphabet;
import objects.BGSprite;

import states.PlayState;
import states.LoadingState;

#if flxanimate 
import flxanimate.*;
import flxanimate.PsychFlxAnimate as FlxAnimate;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;

using StringTools;
#end