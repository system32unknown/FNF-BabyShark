package psychlua;

class TextFunctions {
    public static function implement(funk:FunkinLua) {
        var game:PlayState = PlayState.instance;

		funk.addCallback("makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float) {
			tag = tag.replace('.', '');
			LuaUtils.resetTextTag(tag);
			var leText:FlxText = new FlxText(x, y, width, text, 16);
			leText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
			leText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2);
			leText.camera = game.camHUD;
			leText.scrollFactor.set();
			game.modchartTexts.set(tag, leText);
		});

		funk.addCallback("setTextString", function(tag:String, text:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.text = text;
				return true;
			}
			FunkinLua.luaTrace("setTextString: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		funk.addCallback("setTextSize", function(tag:String, size:Int) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.size = size;
				return true;
			}
			FunkinLua.luaTrace("setTextSize: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		funk.addCallback("setTextWidth", function(tag:String, width:Float) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.fieldWidth = width;
				return true;
			}
			FunkinLua.luaTrace("setTextWidth: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		funk.addCallback("setTextBorder", function(tag:String, size:Int, color:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.borderSize = size;
				obj.borderColor = CoolUtil.colorFromString(color);
				return true;
			}
			FunkinLua.luaTrace("setTextBorder: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		funk.addCallback("setTextBorderStyle", function(tag:String, borderStyle:String = 'NONE') {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.borderStyle = switch(borderStyle.trim().toLowerCase()) {
					case 'none': NONE;
					case 'shadow': SHADOW;
					case 'outline': OUTLINE;
					case 'outline_fast': OUTLINE_FAST;
					default: NONE;
				}
			}
		});
		funk.addCallback("setTextColor", function(tag:String, color:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.color = CoolUtil.colorFromString(color);
				return true;
			}
			FunkinLua.luaTrace("setTextColor: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		funk.addCallback("setTextFont", function(tag:String, newFont:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.font = Paths.font(newFont);
				return true;
			}
			FunkinLua.luaTrace("setTextFont: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		funk.addCallback("setTextItalic", function(tag:String, italic:Bool) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.italic = italic;
				return true;
			}
			FunkinLua.luaTrace("setTextItalic: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		funk.addCallback("setTextAlignment", function(tag:String, alignment:String = 'left') {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) {
				obj.alignment = switch(alignment.trim().toLowerCase()) {
					case 'right': RIGHT;
					case 'center': CENTER;
					default: LEFT;
				}
				return true;
			}
			FunkinLua.luaTrace("setTextAlignment: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		funk.addCallback("getTextString", function(tag:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null && obj.text != null) return obj.text;
			FunkinLua.luaTrace("getTextString: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		funk.addCallback("getTextSize", function(tag:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) return obj.size;
			FunkinLua.luaTrace("getTextSize: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return -1;
		});
		funk.addCallback("getTextFont", function(tag:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) return obj.font;
			FunkinLua.luaTrace("getTextFont: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		funk.addCallback("getTextWidth", function(tag:String) {
			var obj:FlxText = LuaUtils.getTextObject(tag);
			if(obj != null) return obj.fieldWidth;
			FunkinLua.luaTrace("getTextWidth: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return 0;
		});

		funk.addCallback("addLuaText", function(tag:String) {
			if(game.modchartTexts.exists(tag))
				LuaUtils.getInstance().add(game.modchartTexts.get(tag));
		});
		funk.addCallback("removeLuaText", function(tag:String, destroy:Bool = true) {
			if(!game.modchartTexts.exists(tag)) return;

			var text:FlxText = game.modchartTexts.get(tag);
			if(destroy) text.kill();

			LuaUtils.getInstance().remove(text, true);

			if(destroy) {
				text.destroy();
				game.modchartTexts.remove(tag);
			}
		});
    }
}