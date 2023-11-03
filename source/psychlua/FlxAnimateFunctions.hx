package psychlua;

import openfl.utils.Assets;

#if (LUA_ALLOWED && flxanimate)
class FlxAnimateFunctions {
	public static function implement(funk:FunkinLua) {
		funk.set("makeFlxAnimateSprite", function(tag:String, ?x:Float = 0, ?y:Float = 0, ?loadFolder:String = null) {
			tag = tag.replace('.', '');
			var lastSprite = PlayState.instance.variables.get(tag);
			if(lastSprite != null) {
				lastSprite.kill();
				PlayState.instance.remove(lastSprite);
				lastSprite.destroy();
			}

			var mySprite:ModchartAnimateSprite = new ModchartAnimateSprite(x, y);
			if(loadFolder != null) loadAtlasCustom(mySprite, loadFolder);
			PlayState.instance.variables.set(tag, mySprite);
			mySprite.active = true;
		});

		funk.set("loadAnimateAtlas", function(tag:String, folderOrImg:Dynamic, ?spriteJson:Dynamic = null, ?animationJson:Dynamic = null) {
			var spr:FlxAnimate = PlayState.instance.variables.get(tag);
			if(spr != null) loadAtlasCustom(spr, folderOrImg, spriteJson, animationJson);
		});
		
		funk.set("addAnimationBySymbol", function(tag:String, name:String, symbol:String, ?framerate:Float = 24, ?loop:Bool = false, ?matX:Float = 0, ?matY:Float = 0) {
			var obj:Dynamic = PlayState.instance.variables.get(tag);
			if(cast (obj, FlxAnimate) == null) return false;

			obj.anim.addBySymbol(name, symbol, framerate, loop, matX, matY);
			if(obj.anim.lastPlayedAnim == null) {
				if(obj.playAnim != null) obj.playAnim(name, true); //is ModchartAnimateSprite
				else obj.animation.play(name, true);
			}
			return true;
		});

		funk.set("addAnimationBySymbolIndices", function(tag:String, name:String, symbol:String, ?indices:Any = null, ?framerate:Float = 24, ?loop:Bool = false, ?matX:Float = 0, ?matY:Float = 0) {
			var obj:Dynamic = PlayState.instance.variables.get(tag);
			if(cast (obj, FlxAnimate) == null) return false;

			if(indices == null) indices = [0];
			else if(Std.isOfType(indices, String)) {
				var strIndices:Array<String> = cast (indices, String).trim().split(',');
				var myIndices:Array<Int> = [];
				for (i in 0...strIndices.length) {
					myIndices.push(Std.parseInt(strIndices[i]));
				}
				indices = myIndices;
			}

			obj.anim.addBySymbolIndices(name, symbol, indices, framerate, loop, matX, matY);
			if(obj.anim.lastPlayedAnim == null) {
				if(obj.playAnim != null) obj.playAnim(name, true); //is ModchartAnimateSprite
				else obj.animation.play(name, true);
			}
			return true;
		});
	}

	static function loadAtlasCustom(spr:FlxAnimate, folderOrImg:Dynamic, spriteJson:Dynamic = null, animationJson:Dynamic = null) {
		var changedAnimJson = false;
		var changedAtlasJson = false;
		var changedImage = false;
		
		if(spriteJson != null) {
			changedAtlasJson = true;
			spriteJson = File.getContent(spriteJson);
		}

		if(animationJson != null) {
			changedAnimJson = true;
			animationJson = File.getContent(animationJson);
		}

		// is folder or image path
		if(Std.isOfType(folderOrImg, String)) {
			var originalPath:String = folderOrImg;
			for (i in 0...10) {
				var st:String = '$i';
				if(i == 0) st = '';

				if(!changedAtlasJson) {
					spriteJson = getContentFromFile('images/$originalPath/spritemap$st.json');
					if(spriteJson != null) {
						changedImage = true;
						changedAtlasJson = true;
						folderOrImg = Paths.image('$originalPath/spritemap$st');
						break;
					}
				} else if(Paths.fileExists('images/$originalPath/spritemap$st.png', IMAGE)) {
					changedImage = true;
					folderOrImg = Paths.image('$originalPath/spritemap$st');
					break;
				}
			}

			if(!changedImage) {
				changedImage = true;
				folderOrImg = Paths.image(originalPath);
			}

			if(!changedAnimJson) {
				changedAnimJson = true;
				animationJson = getContentFromFile('images/$originalPath/Animation.json');
			}
		}

		spr.loadAtlasEx(folderOrImg, spriteJson, animationJson);
	}

	static function getContentFromFile(path:String):String {
		var onAssets:Bool = false;
		var path:String = Paths.getPath(path, TEXT, true);
		if(FileSystem.exists(path) || (onAssets = true && Assets.exists(path, TEXT)))
			return !onAssets ? File.getContent(path) : Assets.getText(path);
		return null;
	}
}
#end