package psychlua;

class SoundFunctions {
    public static function implement(funk:FunkinLua) {
        var game:PlayState = PlayState.instance;
		funk.set("playMusic", (sound:String, volume:Float = 1, loop:Bool = false) -> FlxG.sound.playMusic(Paths.music(sound), volume, loop));
		funk.set("playSound", function(sound:String, volume:Float = 1, ?tag:String = null, ?loop:Bool = false) {
			if(tag != null && tag.length > 0) {
				var originalTag:String = tag;
				tag = LuaUtils.formatVariable('sound_$tag');
				var variables:Map<String, Dynamic> = MusicBeatState.getVariables();
				var oldSnd:FlxSound = variables.get(tag);
				if(oldSnd != null) {
					oldSnd.stop();
					oldSnd.destroy();
				}
	
				variables.set(tag, FlxG.sound.play(Paths.sound(sound), volume, loop, null, true, () -> {
					if(!loop) variables.remove(tag);
					if(game != null) game.callOnLuas('onSoundFinished', [originalTag]);
				}));
				return tag;
			}
			FlxG.sound.play(Paths.sound(sound), volume);
			return null;
		});
		funk.set("stopSound", function(tag:String) {
			if(tag == null || tag.length < 1) {
				if (FlxG.sound.music != null) FlxG.sound.music.stop();
			} else {
				tag = LuaUtils.formatVariable('sound_$tag');
				var variables:Map<String, Dynamic> = MusicBeatState.getVariables();
				var snd:FlxSound = variables.get(tag);
				if(snd != null) {
					snd.stop();
					variables.remove(tag);
				}
			}
		});
		funk.set("pauseSound", (tag:String) -> {
			if(tag == null || tag.length < 1) {
				if (FlxG.sound.music != null) FlxG.sound.music.stop();
			} else {
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if(snd != null) snd.pause();
			}
		});
		funk.set("resumeSound", (tag:String) -> {
			if(tag == null || tag.length < 1) {
				if (FlxG.sound.music != null) FlxG.sound.music.stop();
			} else {
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if(snd != null) snd.play();
			}
		});
		funk.set("soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			if(tag == null || tag.length < 1) {
				if (FlxG.sound.music != null) FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			} else {
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if(snd != null) snd.fadeIn(duration, fromValue, toValue);
			}
		});
		funk.set("soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0) {
			if(tag == null || tag.length < 1) {
				if (FlxG.sound.music != null) FlxG.sound.music.fadeIn(duration, toValue);
			} else {
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if(snd != null) snd.fadeOut(duration, toValue);
			}
		});
		funk.set("soundFadeCancel", function(tag:String) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null && FlxG.sound.music.fadeTween != null) FlxG.sound.music.fadeTween.cancel();
			} else {
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if(snd != null && snd.fadeTween != null) snd.fadeTween.cancel();
			}
		});
		funk.set("getSoundVolume", function(tag:String) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null) return FlxG.sound.music.volume;
			} else {
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if(snd != null) return snd.volume;
			}
			return 0;
		});
		funk.set("setSoundVolume", function(tag:String, value:Float) {
			if(tag == null || tag.length < 1) {
				tag = LuaUtils.formatVariable('sound_$tag');
				if(FlxG.sound.music != null) {
					FlxG.sound.music.volume = value;
					return;
				}
			} else {
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if(snd != null) snd.volume = value;
			}
		});
		funk.set("getSoundTime", function(tag:String) {
			if(tag == null || tag.length < 1) return FlxG.sound.music != null ? FlxG.sound.music.time : 0;
			tag = LuaUtils.formatVariable('sound_$tag');
			var snd:FlxSound = MusicBeatState.getVariables().get(tag);
			return snd != null ? snd.time : 0;
		});
		funk.set("setSoundTime", function(tag:String, value:Float) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null) {
					FlxG.sound.music.time = value;
					return;
				}
			} else {
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if(snd != null) snd.time = value;
			}
		});
		funk.set("getSoundPitch", function(tag:String) {
			#if FLX_PITCH
			tag = LuaUtils.formatVariable('sound_$tag');
			var snd:FlxSound = MusicBeatState.getVariables().get(tag);
			return snd != null ? snd.pitch : 0;
			#else
			luaTrace("getSoundPitch: Sound Pitch is not supported on this platform!", false, false, FlxColor.RED);
			return 1;
			#end
		});
		funk.set("setSoundPitch", function(tag:String, value:Float, doPause:Bool = false) {
			#if FLX_PITCH
			tag = LuaUtils.formatVariable('sound_$tag');
			var snd:FlxSound = MusicBeatState.getVariables().get(tag);
			if(snd != null) {
				var wasResumed:Bool = snd.playing;
				if (doPause) snd.pause();
				snd.pitch = value;
				if (doPause && wasResumed) snd.play();
			}

			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null) {
					var wasResumed:Bool = FlxG.sound.music.playing;
					if (doPause) FlxG.sound.music.pause();
					FlxG.sound.music.pitch = value;
					if (doPause && wasResumed) FlxG.sound.music.play();
					return;
				}
			} else {
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if(snd != null) {
					var wasResumed:Bool = snd.playing;
					if (doPause) snd.pause();
					snd.pitch = value;
					if (doPause && wasResumed) snd.play();
				}
			}
			#else
			luaTrace("setSoundPitch: Sound Pitch is not supported on this platform!", false, false, FlxColor.RED);
			#end
		});
    }
}