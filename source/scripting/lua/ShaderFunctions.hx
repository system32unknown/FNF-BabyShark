package scripting.lua;

#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end

class ShaderFunctions {
	public static function implement(funk:FunkinLua) {
		funk.addLocalCallback("initLuaShader", function(name:String, glslVersion:Int = 120) {
			if(!ClientPrefs.getPref('shaders')) return false;

			#if (!flash && MODS_ALLOWED && sys)
			return funk.initLuaShader(name, glslVersion);
			#else
			funk.luaTrace("initLuaShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		
		funk.addLocalCallback("setSpriteShader", function(obj:String, shader:String) {
			if(!ClientPrefs.getPref('shaders')) return false;

			#if (!flash && MODS_ALLOWED && sys)
			if(!funk.runtimeShaders.exists(shader) && !funk.initLuaShader(shader)) {
				funk.luaTrace('setSpriteShader: Shader $shader is missing!', false, false, FlxColor.RED);
				return false;
			}

			var leObj:FlxSprite = LuaUtils.getVarInstance(obj, true, false);
			if(leObj != null) {
				var arr:Array<String> = funk.runtimeShaders.get(shader);
				leObj.shader = new FlxRuntimeShader(arr[0], arr[1]);
				return true;
			}
			#else
			funk.luaTrace("setSpriteShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		funk.addCallback("removeSpriteShader", function(obj:String) {
			var leObj:FlxSprite = LuaUtils.getVarInstance(obj, true, false);
			if (leObj != null) {
				leObj.shader = null;
				return true;
			}
			return false;
		});

		funk.addCallback("getShaderBool", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getBool(prop) : null;
			#else
			funk.luaTrace("getShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		funk.addCallback("getShaderBoolArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getBoolArray(prop) : null;
			#else
			funk.luaTrace("getShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		funk.addCallback("getShaderInt", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getInt(prop) : null;
			#else
			funk.luaTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		funk.addCallback("getShaderIntArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getIntArray(prop) : null;
			#else
			funk.luaTrace("getShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		funk.addCallback("getShaderFloat", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getFloat(prop) : null;
			#else
			funk.luaTrace("getShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		funk.addCallback("getShaderFloatArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getFloatArray(prop) : null;
			#else
			funk.luaTrace("getShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});

		funk.addCallback("setShaderBool", function(obj:String, prop:String, value:Bool) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setBool(prop, value);
				return true;
			}
			#else
			funk.luaTrace("setShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});
		funk.addCallback("setShaderBoolArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setBoolArray(prop, values);
				return true;
			}
			#else
			funk.luaTrace("setShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});
		funk.addCallback("setShaderInt", function(obj:String, prop:String, value:Int) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setInt(prop, value);
				return true;
			}
			#else
			funk.luaTrace("setShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});
		funk.addCallback("setShaderIntArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setIntArray(prop, values);
				return true;
			}
			#else
			funk.luaTrace("setShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});
		funk.addCallback("setShaderFloat", function(obj:String, prop:String, value:Float) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setFloat(prop, value);
				return true;
			}
			#else
			funk.luaTrace("setShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});
		funk.addCallback("setShaderFloatArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setFloatArray(prop, values);
				return true;
			}
			#else
			funk.luaTrace("setShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});

		funk.addCallback("setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				var value = Paths.image(bitmapdataPath);
				if (value == null || value.bitmap == null) return false;

				shader.setSampler2D(prop, value.bitmap);
				return true;
			}
			#else
			funk.luaTrace("setShaderSampler2D: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});
    }

	public static function getShader(obj:String):FlxRuntimeShader {
		var leObj:FlxSprite = LuaUtils.getVarInstance(obj, true, false);
		if (leObj != null) return cast leObj.shader;
		return null;
	}
}