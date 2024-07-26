package psychlua;

import objects.VideoSprite;
import substates.GameOverSubstate;
import flixel.FlxState;

class VideoFunctions {
	public static function implement(funk:FunkinLua) {
		funk.set("makeVideoSprite", function(tag:String, video:String, ?x:Float = 0, ?y:Float = 0, ?loop:Dynamic = false) {
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);
			var leVideo:VideoSprite = new VideoSprite(Paths.video(video), true, false, loop, false);
			leVideo.cameras = [PlayState.instance.camGame];
			leVideo.scrollFactor.set(1, 1);
			leVideo.setPosition(x, y);
			MusicBeatState.getVariables().set(tag, leVideo);
		});
		funk.set("setVideoSize", function(tag:String, x:Int, y:Int = 0, updateHitbox:Bool = true) {
			var obj:VideoSprite = MusicBeatState.getVariables().get(tag);
			if(obj != null) {
				if(!obj.isPlaying) {
					obj.videoSprite.bitmap.onFormatSetup.add(() -> {
						obj.videoSprite.setGraphicSize(x, y);
						if(updateHitbox) obj.videoSprite.updateHitbox();
					});
					return;
				}
				obj.videoSprite.setGraphicSize(x, y);
				if(updateHitbox) obj.videoSprite.updateHitbox();
				return;
			}

			var poop:VideoSprite = LuaUtils.getVarInstance(tag);
			if(poop != null) {
				if(!poop.isPlaying) {
					poop.videoSprite.bitmap.onFormatSetup.add(() -> {
						poop.videoSprite.setGraphicSize(x, y);
						if(updateHitbox) poop.videoSprite.updateHitbox();
					});
					return;
				}
				poop.videoSprite.setGraphicSize(x, y);
				if(updateHitbox) poop.videoSprite.updateHitbox();
				return;
			}
			FunkinLua.luaTrace('setVideoSize: Couldnt find video: ' + obj, false, false, FlxColor.RED);
		});
		funk.set("addLuaVideo", function(tag:String, front:Bool = false) {
			var myVideo:VideoSprite = MusicBeatState.getVariables().get(tag);
			if(myVideo == null) return false;

			var instance:FlxState = LuaUtils.getInstance();
			if(front) instance.add(myVideo);
			else {
				if(PlayState.instance == null || !PlayState.instance.isDead)
					instance.insert(instance.members.indexOf(LuaUtils.getLowestCharacterGroup()), myVideo);
				else GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), myVideo);
			}
			return true;
		});
		funk.set("removeLuaVideo", function(tag:String, destroy:Bool = true, ?group:String = null) {
			var obj:VideoSprite = LuaUtils.getObjectDirectly(tag);
			if(obj == null || obj.destroy == null) return;

			var groupObj:Dynamic = null;
			if(group == null) groupObj = LuaUtils.getInstance();
			else groupObj = LuaUtils.getObjectDirectly(group);

			groupObj.remove(obj, true);
			if(destroy) {
				MusicBeatState.getVariables().remove(tag);
				obj.destroy();
			}
		});

		funk.set("playVideo", function(tag:String) {
			var obj:VideoSprite = MusicBeatState.getVariables().get(tag);
			if(obj != null) {
				if(!obj.isPlaying) obj.play();
				return;
			}

			var poop:VideoSprite = LuaUtils.getVarInstance(tag);
			if(poop != null) {
				if(!poop.isPlaying) poop.play();
				return;
			}
			FunkinLua.luaTrace('playVideo: Couldnt find video: ' + tag, false, false, FlxColor.RED);
		});
		funk.set("resumeVideo", function(tag:String) {
			var obj:VideoSprite = MusicBeatState.getVariables().get(tag);
			if(obj != null) {
				if(obj.isPlaying && obj.isPaused) obj.resume();
				return;
			}

			var poop:VideoSprite = LuaUtils.getVarInstance(tag);
			if(poop != null) {
				if(poop.isPlaying && poop.isPaused) poop.resume();
				return;
			}
			FunkinLua.luaTrace('resumeVideo: Couldnt find video: ' + tag, false, false, FlxColor.RED);
		});
		funk.set("pauseVideo", function(tag:String) {
			var obj:VideoSprite = MusicBeatState.getVariables().get(tag);
			if(obj != null) {
				if(obj.isPlaying && !obj.isPaused) obj.pause();
				return;
			}

			var poop:VideoSprite = LuaUtils.getVarInstance(tag);
			if(poop != null) {
				if(poop.isPlaying && !poop.isPaused) poop.pause();
				return;
			}
			FunkinLua.luaTrace('pauseVideo: Couldnt find video: ' + tag, false, false, FlxColor.RED);
		});

		funk.set("luaVideoExists", function(tag:String) {
			var obj:VideoSprite = MusicBeatState.getVariables().get(tag);
			return (obj != null && Std.isOfType(obj, VideoSprite));
		});
	}
}