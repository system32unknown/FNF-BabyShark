#if !macro
#if discord_rpc
import utils.DiscordClient;
#end
import utils.ClientPrefs;
import states.MusicBeatState;
import states.PlayState;
import substates.MusicBeatSubstate;
import data.api.FunkinInternet;
import Paths;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
#end

using StringTools;