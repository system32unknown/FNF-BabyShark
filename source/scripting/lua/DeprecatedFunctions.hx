package scripting.lua;

import game.StrumNote;

//
// This is simply where i store deprecated functions for it to be more organized.
// I would suggest not messing with these, as it could break mods.
//
class DeprecatedFunctions
{
	public static function implement(funk:FunkinLua)
	{
		// DEPRECATED, DONT MESS WITH THESE SHITS, ITS JUST THERE FOR BACKWARD COMPATIBILITY
		funk.addCallback("objectPlayAnimation", function(l:FunkinLua, obj:String, name:String, forced:Bool = false, ?startFrame:Int = 0) {
			l.luaTrace("objectPlayAnimation is deprecated! Use playAnim instead", false, true);
			if(PlayState.instance.getLuaObject(obj, false) != null) {
				PlayState.instance.getLuaObject(obj, false).animation.play(name, forced, false, startFrame);
				return true;
			}

			var spr:FlxSprite = Reflect.getProperty(LuaUtils.getInstance(), obj);
			if(spr != null) {
				spr.animation.play(name, forced, false, startFrame);
				return true;
			}
			return false;
		});
		funk.addCallback("characterPlayAnim", function(l:FunkinLua, character:String, anim:String, ?forced:Bool = false) {
			l.luaTrace("characterPlayAnim is deprecated! Use playAnim instead", false, true);
			switch(character.toLowerCase()) {
				case 'dad':
					if(PlayState.instance.dad.animOffsets.exists(anim))
						PlayState.instance.dad.playAnim(anim, forced);
				case 'gf' | 'girlfriend':
					if(PlayState.instance.gf != null && PlayState.instance.gf.animOffsets.exists(anim))
						PlayState.instance.gf.playAnim(anim, forced);
				default:
					if(PlayState.instance.boyfriend.animOffsets.exists(anim))
						PlayState.instance.boyfriend.playAnim(anim, forced);
			}
		});
		funk.addCallback("luaSpriteMakeGraphic", function(l:FunkinLua, tag:String, width:Int, height:Int, color:String) {
			l.luaTrace("luaSpriteMakeGraphic is deprecated! Use makeGraphic instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

				PlayState.instance.modchartSprites.get(tag).makeGraphic(width, height, colorNum);
			}
		});
		funk.addCallback("luaSpriteAddAnimationByPrefix", function(l:FunkinLua, tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			l.luaTrace("luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var cock:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});
		funk.addCallback("luaSpriteAddAnimationByIndices", function(l:FunkinLua, tag:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			l.luaTrace("luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var strIndices:Array<String> = indices.trim().split(',');
				var die:Array<Int> = [];
				for (i in 0...strIndices.length) {
					die.push(Std.parseInt(strIndices[i]));
				}
				var pussy:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if(pussy.animation.curAnim == null) {
					pussy.animation.play(name, true);
				}
			}
		});
		funk.addCallback("luaSpritePlayAnimation", function(l:FunkinLua, tag:String, name:String, forced:Bool = false) {
			l.luaTrace("luaSpritePlayAnimation is deprecated! Use playAnim instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).animation.play(name, forced);
			}
		});
		funk.addCallback("setLuaSpriteCamera", function(l:FunkinLua, tag:String, camera:String = '') {
			l.luaTrace("setLuaSpriteCamera is deprecated! Use setObjectCamera instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}
			l.luaTrace("Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});
		funk.addCallback("setLuaSpriteScrollFactor", function(l:FunkinLua, tag:String, scrollX:Float, scrollY:Float) {
			l.luaTrace("setLuaSpriteScrollFactor is deprecated! Use setScrollFactor instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).scrollFactor.set(scrollX, scrollY);
				return true;
			}
			return false;
		});
		funk.addCallback("scaleLuaSprite", function(l:FunkinLua, tag:String, x:Float, y:Float) {
			l.luaTrace("scaleLuaSprite is deprecated! Use scaleObject instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				shit.scale.set(x, y);
				shit.updateHitbox();
				return true;
			}
			return false;
		});
		funk.addCallback("getPropertyLuaSprite", function(l:FunkinLua, tag:String, variable:String) {
			l.luaTrace("getPropertyLuaSprite is deprecated! Use getProperty instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var killMe:Array<String> = variable.split('.');
				if(killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), killMe[0]);
					for (i in 1...killMe.length - 1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length - 1]);
				}
				return Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), variable);
			}
			return null;
		});
		funk.addCallback("setPropertyLuaSprite", function(l:FunkinLua, tag:String, variable:String, value:Dynamic) {
			l.luaTrace("setPropertyLuaSprite is deprecated! Use setProperty instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var killMe:Array<String> = variable.split('.');
				if(killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), killMe[0]);
					for (i in 1...killMe.length - 1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					Reflect.setProperty(coverMeInPiss, killMe[killMe.length - 1], value);
					return true;
				}
				Reflect.setProperty(PlayState.instance.modchartSprites.get(tag), variable, value);
				return true;
			}
			l.luaTrace("setPropertyLuaSprite: Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});
		funk.addCallback("musicFadeIn", function(l:FunkinLua, duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			l.luaTrace('musicFadeIn is deprecated! Use soundFadeIn instead.', false, true);
		});
		funk.addCallback("musicFadeOut", function(l:FunkinLua, duration:Float, toValue:Float = 0) {
			FlxG.sound.music.fadeOut(duration, toValue);
			l.luaTrace('musicFadeOut is deprecated! Use soundFadeOut instead.', false, true);
		});

		funk.addCallback("doTweenX", function(l:FunkinLua, tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			l.luaTrace("doTweenX is deprecated! Use doTween instead", false, true);
			l.oldTweenFunction(tag, vars, {x: value}, duration, ease, 'doTweenX');
		});
		funk.addCallback("doTweenY", function(l:FunkinLua, tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			l.luaTrace("doTweenY is deprecated! Use doTween instead", false, true);
			l.oldTweenFunction(tag, vars, {y: value}, duration, ease, 'doTweenY');
		});
		funk.addCallback("doTweenAngle", function(l:FunkinLua, tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			l.luaTrace("doTweenAngle is deprecated! Use doTween instead", false, true);
			l.oldTweenFunction(tag, vars, {angle: value}, duration, ease, 'doTweenAngle');
		});
		funk.addCallback("doTweenAlpha", function(l:FunkinLua, tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			l.luaTrace("doTweenAlpha is deprecated! Use doTween instead", false, true);
			l.oldTweenFunction(tag, vars, {alpha: value}, duration, ease, 'doTweenAlpha');
		});
		funk.addCallback("doTweenZoom", function(l:FunkinLua, tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			l.luaTrace("doTweenZoom is deprecated! Use doTween instead", false, true);
			l.oldTweenFunction(tag, vars, {zoom: value}, duration, ease, 'doTweenZoom');
		});
		funk.addCallback("noteTweenX", function(l:FunkinLua, tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			l.luaTrace("noteTweenX is deprecated! Use noteTween instead", false, true);
			LuaUtils.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {x: value}, duration * PlayState.instance.playbackRate, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		funk.addCallback("noteTweenY", function(l:FunkinLua, tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			l.luaTrace("noteTweenY is deprecated! Use noteTween instead", false, true);
			LuaUtils.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {y: value}, duration * PlayState.instance.playbackRate, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		funk.addCallback("noteTweenAngle", function(l:FunkinLua, tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			l.luaTrace("noteTweenAngle is deprecated! Use noteTween instead", false, true);
			LuaUtils.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration * PlayState.instance.playbackRate, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		funk.addCallback("noteTweenDirection", function(l:FunkinLua, tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			l.luaTrace("noteTweenDirection is deprecated! Use noteTween instead", false, true);
			LuaUtils.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {direction: value}, duration * PlayState.instance.playbackRate, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		funk.addCallback("noteTweenAlpha", function(l:FunkinLua, tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			l.luaTrace("noteTweenAlpha is deprecated! Use noteTween instead", false, true);
			LuaUtils.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {alpha: value}, duration * PlayState.instance.playbackRate, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
	}
}