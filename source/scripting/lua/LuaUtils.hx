package scripting.lua;

import openfl.display.BlendMode;
import animateatlas.AtlasFrameMaker;
import Type.ValueType;

import substates.GameOverSubstate;

typedef LuaTweenOptions = {
	type:FlxTweenType,
	startDelay:Float,
	onUpdate:Null<String>,
	onStart:Null<String>,
	onComplete:Null<String>,
	loopDelay:Float,
	ease:EaseFunction
}

class LuaUtils {
	public static function getLuaTween(options:Dynamic) {
		return {
			type: getTweenTypeByString(options.type),
			startDelay: options.startDelay,
			onUpdate: options.onUpdate,
			onStart: options.onStart,
			onComplete: options.onComplete,
			loopDelay: options.loopDelay,
			ease: getTweenEaseByString(options.ease)
		};
	}

	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic):Any {
		var splitProps:Array<String> = variable.split('[');
		if(splitProps.length > 1) {
			var target:Dynamic = null;
			if(PlayState.instance.variables.exists(splitProps[0])) {
				var retVal:Dynamic = PlayState.instance.variables.get(splitProps[0]);
				if(retVal != null) target = retVal;
			} else target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length) {
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				if(i >= splitProps.length - 1) //Last array
					target[j] = value;
				else target = target[j]; //Anything else
			}
			return target;
		}
			
		if(PlayState.instance.variables.exists(variable)) {
			PlayState.instance.variables.set(variable, value);
			return true;
		}

		Reflect.setProperty(instance, variable, value);
		return true;
	}
	public static function getVarInArray(instance:Dynamic, variable:String):Any {
		var splitProps:Array<String> = variable.split('[');
		if(splitProps.length > 1) {
			var target:Dynamic = null;
			if(PlayState.instance.variables.exists(splitProps[0])) {
				var retVal:Dynamic = PlayState.instance.variables.get(splitProps[0]);
				if(retVal != null) target = retVal;
			} else target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length) {
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				target = target[j];
			}
			return target;
		}

		if(PlayState.instance.variables.exists(variable)) {
			var retVal:Dynamic = PlayState.instance.variables.get(variable);
			if(retVal != null) return retVal;
		}

		return Reflect.getProperty(instance, variable);
	}
	public static function getVarInstance(variable:String, checkLuaFirst:Bool = true, checkForTextsToo:Bool = true):Dynamic {
		var ind = variable.indexOf('.');
		if (ind == -1) {
			if (PlayState.instance.variables.exists(variable)) return PlayState.instance.variables.get(variable);
			return checkLuaFirst ? getObjectDirectly(variable, checkForTextsToo) : getVarInArray(getTargetInstance(), variable);
		}

		var obj:Dynamic = getObjectDirectly(variable.substr(0, ind), checkForTextsToo);
		while (ind != -1) {
			obj = getVarInArray(obj, variable.substring(ind + 1, (ind = variable.indexOf('.', ind + 1)) == -1 ? variable.length : ind));
		}

		return obj;
	}

	public static function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length - 1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			Reflect.setProperty(coverMeInPiss, killMe[killMe.length - 1], value);
			return;
		}
		Reflect.setProperty(leArray, variable, value);
	}
	public static function getGroupStuff(leArray:Dynamic, variable:String) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length - 1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			switch(Type.typeof(coverMeInPiss)) {
				case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
					return coverMeInPiss.get(killMe[killMe.length - 1]);
				default:
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length - 1]);
			};
		}
		switch(Type.typeof(leArray)) {
			case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
				return leArray.get(variable);
			default:
				return Reflect.getProperty(leArray, variable);
		};
	}

	public static function getPropertyLoop(killMe:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool=true):Dynamic {
		var obj:Dynamic = getObjectDirectly(killMe[0], checkForTextsToo);
		var end = killMe.length;
		if(getProperty) end = killMe.length - 1;

		for (i in 1...end) {
			obj = getVarInArray(obj, killMe[i]);
		}
		return obj;
	}

	public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true):Dynamic {
		switch(objectName) {
			case 'this' | 'instance' | 'game':
				return PlayState.instance;
			
			default:
				var obj:Dynamic = PlayState.instance.getLuaObject(objectName, checkForTextsToo);
				if(obj == null) obj = getVarInArray(getTargetInstance(), objectName);
				return obj;
		}
	}

	inline public static function getTextObject(name:String):FlxText {
		return #if LUA_ALLOWED PlayState.instance.modchartTexts.exists(name) ? PlayState.instance.modchartTexts.get(name) : #end
		Reflect.getProperty(PlayState.instance, name);
	}
	
	public static function isOfTypes(value:Any, types:Array<Dynamic>) {
		for (type in types) if(Std.isOfType(value, type)) return true;
		return false;
	}
	
	public static inline function getTargetInstance() {
		return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}
	
	public static function loadFrames(spr:FlxSprite, image:String, spriteType:String) {
		switch(spriteType.toLowerCase().trim()) {
			case "texture" | "textureatlas" | "tex":
				spr.frames = AtlasFrameMaker.construct(image);
			case "texture_noaa" | "textureatlas_noaa" | "tex_noaa":
				spr.frames = AtlasFrameMaker.construct(image, null, true);
			case "packer" | "packeratlas" | "pac":
				spr.frames = Paths.getPackerAtlas(image);

			default: spr.frames = Paths.getSparrowAtlas(image);
		}
	}

	public static function resetTextTag(tag:String) {
		if(!PlayState.instance.modchartTexts.exists(tag)) return;

		var target:ModchartText = PlayState.instance.modchartTexts.get(tag);
		target.kill();
		if(target.wasAdded) {
			PlayState.instance.remove(target, true);
		}
		target.destroy();
		PlayState.instance.modchartTexts.remove(tag);
	}

	public static function resetSpriteTag(tag:String) {
		if(!PlayState.instance.modchartSprites.exists(tag)) return;

		var target:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
		target.kill();
		if(target.wasAdded) {
			PlayState.instance.remove(target, true);
		}
		target.destroy();
		PlayState.instance.modchartSprites.remove(tag);
	}

	public static function cancelTween(tag:String) {
		if(PlayState.instance.modchartTweens.exists(tag)) {
			PlayState.instance.modchartTweens.get(tag).cancel();
			PlayState.instance.modchartTweens.get(tag).destroy();
			PlayState.instance.modchartTweens.remove(tag);
		}
	}

	public static function tweenPrepare(tag:String, vars:String) {
		cancelTween(tag);
		var variables:Array<String> = vars.split('.');
		var sexyProp:Dynamic = getObjectDirectly(variables[0]);
		if(variables.length > 1) sexyProp = getVarInArray(getPropertyLoop(variables), variables[variables.length - 1]);
		return sexyProp;
	}

	public static function cancelTimer(tag:String) {
		if(PlayState.instance.modchartTimers.exists(tag)) {
			var theTimer:FlxTimer = PlayState.instance.modchartTimers.get(tag);
			theTimer.cancel();
			theTimer.destroy();
			PlayState.instance.modchartTimers.remove(tag);
		}
	}

	public static function getColorByString(?color:String = '') {
		return switch(color.toLowerCase().trim()) {
			case 'blue': FlxColor.BLUE;
			case 'brown': FlxColor.BROWN;
			case 'cyan': FlxColor.CYAN;
			case 'gray' | 'grey': FlxColor.GRAY;
			case 'green': FlxColor.GREEN;
			case 'lime': FlxColor.LIME;
			case 'magenta': FlxColor.MAGENTA;
			case 'orange': FlxColor.ORANGE;
			case 'pink': FlxColor.PINK;
			case 'purple': FlxColor.PURPLE;
			case 'red': FlxColor.RED;
			case 'transparent': FlxColor.TRANSPARENT;
			case 'white': FlxColor.WHITE;
			case 'yellow': FlxColor.YELLOW;
			default: FlxColor.BLACK;
		}
	}

	//buncho string stuffs
	public static function getTweenTypeByString(?type:String = '') {
		return switch(type.toLowerCase().trim()) {
			case 'backward': FlxTweenType.BACKWARD;
			case 'looping': FlxTweenType.LOOPING;
			case 'persist': FlxTweenType.PERSIST;
			case 'pingpong': FlxTweenType.PINGPONG;
			default: FlxTweenType.ONESHOT;
		}
	}

	public static function getTweenEaseByString(?ease:String = '') {
		return switch(ease.toLowerCase().trim()) {
			case 'backin': FlxEase.backIn;
			case 'backinout': FlxEase.backInOut;
			case 'backout': FlxEase.backOut;
			case 'bouncein': FlxEase.bounceIn;
			case 'bounceinout': FlxEase.bounceInOut;
			case 'bounceout': FlxEase.bounceOut;
			case 'circin': FlxEase.circIn;
			case 'circinout': FlxEase.circInOut;
			case 'circout': FlxEase.circOut;
			case 'cubein': FlxEase.cubeIn;
			case 'cubeinout': FlxEase.cubeInOut;
			case 'cubeout': FlxEase.cubeOut;
			case 'elasticin': FlxEase.elasticIn;
			case 'elasticinout': FlxEase.elasticInOut;
			case 'elasticout': FlxEase.elasticOut;
			case 'expoin': FlxEase.expoIn;
			case 'expoinout': FlxEase.expoInOut;
			case 'expoout': FlxEase.expoOut;
			case 'quadin': FlxEase.quadIn;
			case 'quadinout': FlxEase.quadInOut;
			case 'quadout': FlxEase.quadOut;
			case 'quartin': FlxEase.quartIn;
			case 'quartinout': FlxEase.quartInOut;
			case 'quartout': FlxEase.quartOut;
			case 'quintin': FlxEase.quintIn;
			case 'quintinout': FlxEase.quintInOut;
			case 'quintout': FlxEase.quintOut;
			case 'sinein': FlxEase.sineIn;
			case 'sineinout': FlxEase.sineInOut;
			case 'sineout': FlxEase.sineOut;
			case 'smoothstepin': FlxEase.smoothStepIn;
			case 'smoothstepinout': FlxEase.smoothStepInOut;
			case 'smoothstepout': FlxEase.smoothStepInOut;
			case 'smootherstepin': FlxEase.smootherStepIn;
			case 'smootherstepinout': FlxEase.smootherStepInOut;
			case 'smootherstepout': FlxEase.smootherStepOut;
			default: FlxEase.linear;
		}
	}

	public static function blendModeFromString(blend:String):BlendMode {
		return switch(blend.toLowerCase().trim()) {
			case 'add': ADD;
			case 'alpha': ALPHA;
			case 'darken': DARKEN;
			case 'difference': DIFFERENCE;
			case 'erase': ERASE;
			case 'hardlight': HARDLIGHT;
			case 'invert': INVERT;
			case 'layer': LAYER;
			case 'lighten': LIGHTEN;
			case 'multiply': MULTIPLY;
			case 'overlay': OVERLAY;
			case 'screen': SCREEN;
			case 'shader': SHADER;
			case 'subtract': SUBTRACT;
			default: NORMAL; 
		}
	}

	public static function cameraFromString(cam:String):FlxCamera {
		return switch(cam.toLowerCase()) {
			case 'camhud' | 'hud': PlayState.instance.camHUD;
			case 'camother' | 'other': PlayState.instance.camOther;
			default: PlayState.instance.camGame;
		}
	}

	public static function isLuaRunning(luaFile:String) {
		#if LUA_ALLOWED
		luaFile = FunkinLua.format(luaFile);

		for (luaInstance in PlayState.instance.luaArray) {
			if (luaInstance.globalScriptName == luaFile && !luaInstance.closed)
				return true;
		}
		#end
		return false;
	}
}