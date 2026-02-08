#if !macro
#if DISCORD_ALLOWED
import funkin.backend.Discord;
#end

import funkin.debug.Logs;

#if AWARDS_ALLOWED
import funkin.backend.Awards;
#end

#if sys
import sys.*;
import sys.io.*;
#end

import animate.FlxAnimate;

import funkin.backend.Paths;
import funkin.backend.Controls;
import funkin.backend.MusicBeatState;
import funkin.backend.MusicBeatSubstate;
import funkin.backend.Transition;
import funkin.backend.Settings;
import funkin.backend.Conductor;
import funkin.backend.BaseStage;
import funkin.backend.Difficulty;
import funkin.backend.Mods;
import funkin.backend.Language;
import funkin.backend.EK;

import funkin.backend.ui.*; // Psych-UI

import funkin.utils.Util;
import funkin.utils.SpriteUtil;

import funkin.objects.Alphabet;
import funkin.objects.BGSprite;

import funkin.states.PlayState;
import funkin.states.LoadingState;

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