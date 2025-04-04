package psychlua;

#if (!flash && sys)
import openfl.filters.ShaderFilter;
import flixel.addons.display.FlxRuntimeShader;
#end

class ShaderFunctions {
	#if (!flash && sys)
	static var storedFilters:Map<String, ShaderFilter> = [];
	#end

	public static function implement(funk:FunkinLua) {
		funk.addLocalCallback("initLuaShader", function(name:String) {
			if (!Settings.data.shaders) return false;

			#if (!flash && sys)
			return funk.initLuaShader(name);
			#else
			FunkinLua.luaTrace("initLuaShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});

		funk.addLocalCallback("setSpriteShader", function(obj:String, shader:String) {
			if (!Settings.data.shaders) return false;

			#if (!flash && sys)
			if (!funk.runtimeShaders.exists(shader) && !funk.initLuaShader(shader)) {
				FunkinLua.luaTrace('setSpriteShader: Shader $shader is missing!', false, false, FlxColor.RED);
				return false;
			}

			var leObj:FlxSprite = LuaUtils.getObjectLoop(obj);
			if (leObj != null) {
				var arr:Array<String> = funk.runtimeShaders.get(shader);
				leObj.shader = new shaders.ErrorHandledShader.ErrorHandledRuntimeShader(shader, arr[0], arr[1]);
				return true;
			}
			#else
			FunkinLua.luaTrace("setSpriteShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		funk.set("removeSpriteShader", function(obj:String) {
			var leObj:FlxSprite = LuaUtils.getObjectLoop(obj);
			if (leObj != null) {
				leObj.shader = null;
				return true;
			}
			return false;
		});

		funk.addLocalCallback("addShaderToCam", function(cam:String, shader:String, ?index:String) {
			if (!Settings.data.shaders) return false;
			if (index == null || index.length < 1) index = shader;

			#if (!flash && sys)
			if (!funk.runtimeShaders.exists(shader) && !funk.initLuaShader(shader)) {
				FunkinLua.luaTrace('addShaderToCam: Shader $shader is missing!', false, false, FlxColor.RED);
				return false;
			}

			var arr:Array<String> = funk.runtimeShaders.get(shader);
			var camera:Dynamic = getCam(cam);
			camera.filters ??= [];

			var filter:ShaderFilter = new ShaderFilter(new FlxRuntimeShader(arr[0], arr[1]));
			storedFilters.set(index, filter);
			trace("Stored Shaders:" + Std.string(storedFilters));
			camera.filters.push(filter);
			return true;
			#else
			FunkinLua.luaTrace("addShaderToCam: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});

		funk.addLocalCallback("removeCamShader", function(cam:String, shader:String) {
			#if (!flash && sys)
			var camera:Dynamic = getCam(cam);
			if (!storedFilters.exists(shader)) {
				FunkinLua.luaTrace('removeCamShader: $shader does not exist!', false, false, FlxColor.YELLOW);
				return false;
			}

			if (camera.filters == null) {
				FunkinLua.luaTrace('removeCamShader: camera $cam does not have any shaders!', false, false, FlxColor.YELLOW);
				return false;
			}

			camera.filters.remove(storedFilters.get(shader));
			storedFilters.remove(shader);
			return true;
			#else
			FunkinLua.luaTrace('removeCamShader: Platform unsupported for Runtime Shaders!', false, false, FlxColor.RED);
			#end
			return false;
		});

		funk.addLocalCallback("clearCamShaders", (cam:String) -> getCam(cam).filters = []);

		funk.set("getShaderBool", function(obj:String, prop:String) {
			#if (!flash && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader?.getBool(prop);
			#else
			FunkinLua.luaTrace("getShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		funk.set("getShaderBoolArray", function(obj:String, prop:String) {
			#if (!flash && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader?.getBoolArray(prop);
			#else
			FunkinLua.luaTrace("getShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		funk.set("getShaderInt", function(obj:String, prop:String) {
			#if (!flash && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader?.getInt(prop);
			#else
			FunkinLua.luaTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		funk.set("getShaderIntArray", function(obj:String, prop:String) {
			#if (!flash && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader?.getIntArray(prop);
			#else
			FunkinLua.luaTrace("getShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		funk.set("getShaderFloat", function(obj:String, prop:String) {
			#if (!flash && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader?.getFloat(prop);
			#else
			FunkinLua.luaTrace("getShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		funk.set("getShaderFloatArray", function(obj:String, prop:String) {
			#if (!flash && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			return shader?.getFloatArray(prop);
			#else
			FunkinLua.luaTrace("getShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});

		funk.set("setShaderBool", function(obj:String, prop:String, value:Bool) {
			#if (!flash && sys)
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
		funk.set("setShaderBoolArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && sys)
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
		funk.set("setShaderInt", function(obj:String, prop:String, value:Int) {
			#if (!flash && sys)
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
		funk.set("setShaderIntArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && sys)
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
		funk.set("setShaderFloat", function(obj:String, prop:String, value:Float) {
			#if (!flash && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setFloat(prop, value);
				return true;
			}
			#else
			FunkinLua.luaTrace("setShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		funk.set("setShaderFloatArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				shader.setFloatArray(prop, values);
				return true;
			}
			#else
			FunkinLua.luaTrace("setShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});

		funk.set("setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String) {
			#if (!flash && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader != null) {
				var value:flixel.graphics.FlxGraphic = Paths.image(bitmapdataPath);
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
		if (storedFilters.exists(obj)) return cast(storedFilters[obj].shader, FlxRuntimeShader);

		var target:FlxSprite = LuaUtils.getObjectLoop(obj);
		if (target == null) {
			FunkinLua.luaTrace('Error on getting shader: Object $obj not found', false, false, FlxColor.RED);
			return null;
		}
		return cast(target.shader, FlxRuntimeShader);
	}

	public static function getCam(obj:String):Dynamic {
		if (obj.toLowerCase().trim() == "global") return FlxG.game;
		return LuaUtils.cameraFromString(obj);
	}
}