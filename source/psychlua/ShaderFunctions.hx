package psychlua;

#if (!flash && sys)
import openfl.filters.ShaderFilter;
import flixel.addons.display.FlxRuntimeShader;
#end

class ShaderFunctions {
	#if (!flash && MODS_ALLOWED && sys)
	static var storedFilters:Map<String, ShaderFilter> = [];
	#end

	public static function implement(funk:FunkinLua) {
		funk.addLocalCallback("initLuaShader", function(name:String, glslVersion:Int = 120) {
			if(!ClientPrefs.getPref('shaders')) return false;

			#if (!flash && MODS_ALLOWED && sys)
			return funk.initLuaShader(name, glslVersion);
			#else
			FunkinLua.luaTrace("initLuaShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		
		funk.addLocalCallback("setSpriteShader", function(obj:String, shader:String) {
			if(!ClientPrefs.getPref('shaders')) return false;

			#if (!flash && MODS_ALLOWED && sys)
			if(!funk.runtimeShaders.exists(shader) && !funk.initLuaShader(shader)) {
				FunkinLua.luaTrace('setSpriteShader: Shader $shader is missing!', false, false, FlxColor.RED);
				return false;
			}

			var leObj:FlxSprite = LuaUtils.getVarInstance(obj, true, false);
			if(leObj != null) {
				var arr:Array<String> = funk.runtimeShaders.get(shader);
				leObj.shader = new FlxRuntimeShader(arr[0], arr[1]);
				return true;
			}
			#else
			FunkinLua.luaTrace("setSpriteShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
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

		funk.addLocalCallback("addShaderToCam", function(cam:String, shader:String, ?index:String) {
			if (!ClientPrefs.getPref('shaders')) return false;

			if (index == null || index.length < 1)
			    index = shader;

			#if (!flash && MODS_ALLOWED && sys)
			if (!funk.runtimeShaders.exists(shader) && !funk.initLuaShader(shader)) {
			    FunkinLua.luaTrace('addShaderToCam: Shader $shader is missing!', false, false, FlxColor.RED);
			    return false;
			}

            var arr:Array<String> = funk.runtimeShaders.get(shader);
            var camera = getCam(cam);
            @:privateAccess {
                if (camera._filters == null)
                    camera._filters = [];
				
                var filter = new ShaderFilter(new FlxRuntimeShader(arr[0], arr[1]));
                storedFilters.set(index, filter);
                camera._filters.push(filter);
            }
            return true;
			#else
            FunkinLua.luaTrace("addShaderToCam: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});

        funk.addLocalCallback("removeCamShader", function(cam:String, shader:String) {
            #if (!flash && MODS_ALLOWED && sys)
            var camera = getCam(cam);
            @:privateAccess {
                if (!storedFilters.exists(shader)) {
                    FunkinLua.luaTrace('removeCamShader: $shader does not exist!', false, false, FlxColor.YELLOW);
                    return false;
                }

                if (camera._filters == null) {
                    FunkinLua.luaTrace('removeCamShader: camera $cam does not have any shaders!', false, false, FlxColor.YELLOW);
                    return false;
                }

                camera._filters.remove(storedFilters.get(shader));
                storedFilters.remove(shader);
                return true;
            }
            #else
            FunkinLua.luaTrace('removeCamShader: Platform unsupported for Runtime Shaders!', false, false, FlxColor.RED);
            #end
            return false;
        });

        funk.addLocalCallback("clearCamShaders", function(cam:String) getCam(cam).setFilters([]));

		funk.addCallback("getShaderBool", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getBool(prop) : null;
			#else
			FunkinLua.luaTrace("getShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		funk.addCallback("getShaderBoolArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getBoolArray(prop) : null;
			#else
			FunkinLua.luaTrace("getShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		funk.addCallback("getShaderInt", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getInt(prop) : null;
			#else
			FunkinLua.luaTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		funk.addCallback("getShaderIntArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getIntArray(prop) : null;
			#else
			FunkinLua.luaTrace("getShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		funk.addCallback("getShaderFloat", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getFloat(prop) : null;
			#else
			FunkinLua.luaTrace("getShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		funk.addCallback("getShaderFloatArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader != null ? shader.getFloatArray(prop) : null;
			#else
			FunkinLua.luaTrace("getShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
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
			FunkinLua.luaTrace("setShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
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
			FunkinLua.luaTrace("setShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
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
			FunkinLua.luaTrace("setShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
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
			FunkinLua.luaTrace("setShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
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
			return false;
			#else
			FunkinLua.luaTrace("setShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		funk.addCallback("setShaderFloatArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setFloatArray(prop, values);
				return true;
			}
			return false;
			#else
			FunkinLua.luaTrace("setShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
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
			FunkinLua.luaTrace("setShaderSampler2D: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
    }

	public static function getShader(obj:String):FlxRuntimeShader {
		if (storedFilters.exists(obj))
		    return cast(storedFilters[obj].shader, FlxRuntimeShader);

		var leObj:FlxSprite = LuaUtils.getVarInstance(obj, true, false);
		if (leObj != null) return cast leObj.shader;
		return null;
	}

	public static function getCam(obj:String):Dynamic {
		if (obj.toLowerCase().trim() == "global")
 			return FlxG.game;
 		return LuaUtils.cameraFromString(obj);
	}
}