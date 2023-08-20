package psychlua;

import openfl.display.BlendMode;
import animateatlas.AtlasFrameMaker;

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

	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic, allowMaps:Bool = false):Any {
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

		if(allowMaps && isMap(instance)) {
			instance.set(variable, value);
			return value;
		}

		if(PlayState.instance.variables.exists(variable)) {
			PlayState.instance.variables.set(variable, value);
			return value;
		}
		Reflect.setProperty(instance, variable, value);
		return value;
	}

	public static function getVarInArray(instance:Dynamic, variable:String, allowMaps:Bool = false):Any {
		var splitProps:Array<String> = variable.split('[');
		if(splitProps.length > 1) {
			var target:Dynamic = null;
			if(PlayState.instance.variables.exists(splitProps[0])) {
				var retVal:Dynamic = PlayState.instance.variables.get(splitProps[0]);
				if(retVal != null) target = retVal;
			} else target = Reflect.getProperty(instance, splitProps[0]);

			for (prop in splitProps) {
				var j:Dynamic = prop.substr(0, prop.length - 1);
				target = target[j];
			}
			return target;
		}
		
		if(allowMaps && isMap(instance))
			return instance.get(variable);

		if(PlayState.instance.variables.exists(variable)) {
			var retVal:Dynamic = PlayState.instance.variables.get(variable);
			if(retVal != null) return retVal;
		}
		return Reflect.getProperty(instance, variable);
	}

	public static function isMap(variable:Dynamic)
	{
		if(variable.exists != null && variable.keyValueIterator != null) return true;
		return false;
	}

	public static function getVarInstance(variable:String, checkLuaFirst:Bool = true, checkForTextsToo:Bool = true):Dynamic {
		var ind = variable.indexOf('.');
		if (ind == -1) {
			if (PlayState.instance.variables.exists(variable)) return PlayState.instance.variables.get(variable);
			return checkLuaFirst ? getObjectDirectly(variable, checkForTextsToo) : getVarInArray(getInstance(), variable);
		}

		var obj:Dynamic = getObjectDirectly(variable.substr(0, ind), checkForTextsToo);
		while (ind != -1) {
			obj = getVarInArray(obj, variable.substring(ind + 1, (ind = variable.indexOf('.', ind + 1)) == -1 ? variable.length : ind));
		}

		return obj;
	}

	public static function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic, ?allowMaps:Bool = false) {
		var split:Array<String> = variable.split('.');
		if(split.length > 1) {
			var obj:Dynamic = Reflect.getProperty(leArray, split[0]);
			for (i in 1...split.length - 1)
				obj = Reflect.getProperty(obj, split[i]);

			leArray = obj;
			variable = split[split.length - 1];
		}
		if(allowMaps && isMap(leArray)) leArray.set(variable, value);
		else Reflect.setProperty(leArray, variable, value);
		return value;
	}
	public static function getGroupStuff(leArray:Dynamic, variable:String, ?allowMaps:Bool = false) {
		var split:Array<String> = variable.split('.');
		if(split.length > 1) {
			var obj:Dynamic = Reflect.getProperty(leArray, split[0]);
			for (i in 1...split.length - 1)
				obj = Reflect.getProperty(obj, split[i]);

			leArray = obj;
			variable = split[split.length - 1];
		}

		if(allowMaps && isMap(leArray)) return leArray.get(variable);
		return Reflect.getProperty(leArray, variable);
	}

	public static function getPropertyLoop(killMe:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool = true, ?allowMaps:Bool = false):Dynamic {
		var obj:Dynamic = getObjectDirectly(killMe[0], checkForTextsToo);
		var end = killMe.length;
		if(getProperty) end = killMe.length - 1;

		for (i in 1...end) obj = getVarInArray(obj, killMe[i]);
		return obj;
	}

	public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true):Dynamic {
		switch(objectName) {
			case 'this' | 'instance' | 'game': return PlayState.instance;
			
			default:
				var obj:Dynamic = PlayState.instance.getLuaObject(objectName, checkForTextsToo);
				if(obj == null) obj = getVarInArray(getInstance(), objectName);
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
	
	public static inline function getInstance() {
		return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}

	public static inline function getLowestCharacterGroup():FlxSpriteGroup {
		var group:FlxSpriteGroup = PlayState.instance.gfGroup;
		var pos:Int = PlayState.instance.members.indexOf(group);

		var newPos:Int = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
		if(newPos < pos) {
			group = PlayState.instance.boyfriendGroup;
			pos = newPos;
		}
		
		newPos = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
		if(newPos < pos) {
			group = PlayState.instance.dadGroup;
			pos = newPos;
		}
		return group;
	}

	public static function addAnimByIndices(obj:String, name:String, prefix:String, indices:Any = null, framerate:Int = 24, loop:Bool = false)
		{
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if(obj != null && obj.animation != null) {
				if(indices == null) indices = [];
				if(Std.isOfType(indices, String)) {
					var strIndices:Array<String> = cast (indices, String).trim().split(',');
					var myIndices:Array<Int> = [];
					for (i in 0...strIndices.length) {
						myIndices.push(Std.parseInt(strIndices[i]));
					}
					indices = myIndices;
				}
	
				obj.animation.addByIndices(name, prefix, indices, '', framerate, loop);
				if(obj.animation.curAnim == null)
					obj.animation.play(name, true);
				return true;
			}
			return false;
		}
	public static function loadFrames(spr:FlxSprite, image:String, spriteType:String) {
		spr.frames = switch(spriteType.toLowerCase().trim()) {
			case "texture" | "textureatlas" | "tex": AtlasFrameMaker.construct(image);
			case "texture_noaa" | "textureatlas_noaa" | "tex_noaa": AtlasFrameMaker.construct(image, null, true);
			case "packer" | "packeratlas" | "pac": Paths.getPackerAtlas(image);
			default: Paths.getSparrowAtlas(image);
		}
	}

	public static function resetTextTag(tag:String) {
		if(!PlayState.instance.modchartTexts.exists(tag)) return;

		var target:FlxText = PlayState.instance.modchartTexts.get(tag);
		target.kill();
		PlayState.instance.remove(target, true);
		target.destroy();
		PlayState.instance.modchartTexts.remove(tag);
	}

	public static function resetSpriteTag(tag:String) {
		if(!PlayState.instance.modchartSprites.exists(tag)) return;

		var target:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
		target.kill();
		PlayState.instance.remove(target, true);
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

	public static function typeToString(type:Int):String {
		#if LUA_ALLOWED
		switch(type) {
			case Lua.LUA_TBOOLEAN: return "boolean";
			case Lua.LUA_TNUMBER: return "number";
			case Lua.LUA_TSTRING: return "string";
			case Lua.LUA_TTABLE: return "table";
			case Lua.LUA_TFUNCTION: return "function";
		}
		if (type <= Lua.LUA_TNIL) return "nil";
		#end
		return "unknown";
	}

	public static function cameraFromString(cam:String):FlxCamera {
		return switch(cam.toLowerCase()) {
			case 'camhud' | 'hud': PlayState.instance.camHUD;
			case 'camother' | 'other': PlayState.instance.camOther;
			default: PlayState.instance.camGame;
		}
	}
}