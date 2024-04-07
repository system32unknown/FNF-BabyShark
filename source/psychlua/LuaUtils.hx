package psychlua;

import objects.Bar;
import flixel.util.FlxAxes;
import openfl.display.BlendMode;

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
	public static var Function_Stop:Dynamic = "##PSYCHLUA_FUNCTIONSTOP";
	public static var Function_Continue:Dynamic = "##PSYCHLUA_FUNCTIONCONTINUE";
	public static var Function_StopLua:Dynamic = "##PSYCHLUA_FUNCTIONSTOPLUA";
	public static var Function_StopHScript:Dynamic = "##PSYCHLUA_FUNCTIONSTOPHSCRIPT";
	public static var Function_StopAll:Dynamic = "##PSYCHLUA_FUNCTIONSTOPALL";

	public static function getLuaTween(options:Dynamic):LuaTweenOptions {
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

			for (i in 1...splitProps.length) {
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				target = target[j];
			}
			return target;
		}
		
		if(allowMaps && isMap(instance)) return instance.get(variable);

		if(PlayState.instance.variables.exists(variable)) {
			var retVal:Dynamic = PlayState.instance.variables.get(variable);
			if(retVal != null) return retVal;
		}
		return Reflect.getProperty(instance, variable);
	}

	public static function getModSetting(saveTag:String, ?modName:String = null) {
		#if MODS_ALLOWED
		if(FlxG.save.data.modSettings == null) FlxG.save.data.modSettings = new Map<String, Dynamic>();

		var settings:Map<String, Dynamic> = FlxG.save.data.modSettings.get(modName);
		var path:String = Paths.mods('$modName/data/settings.json');
		if(FileSystem.exists(path)) {
			if(settings == null || !settings.exists(saveTag)) {
				if(settings == null) settings = new Map<String, Dynamic>();
				var data:String = File.getContent(path);
				try {
					var parsedJson:Dynamic = tjson.TJSON.parse(data);
					for (i in 0...parsedJson.length) {
						var sub:Dynamic = parsedJson[i];
						if(sub != null && sub.save != null && !settings.exists(sub.save)) {
							if(sub.type != 'keybind' && sub.type != 'key') {
								if(sub.value != null) settings.set(sub.save, sub.value);
							} else settings.set(sub.save, {keyboard: (sub.keyboard != null ? sub.keyboard : 'NONE')});
						}
					}
					FlxG.save.data.modSettings.set(modName, settings);
				} catch(e:Dynamic) {
					var errorTitle:String = 'Mod name: ' + Mods.currentModDirectory;
					var errorMsg:String = 'An error occurred: $e';
					#if windows
					lime.app.Application.current.window.alert(errorMsg, errorTitle);
					#end
					Logs.trace('$errorTitle - $errorMsg', ERROR);
				}
			}
		} else {
			FlxG.save.data.modSettings.remove(modName);
			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			PlayState.instance.addTextToDebug('getModSetting: $path could not be found!', FlxColor.RED);
			#else
			FlxG.log.warn('getModSetting: $path could not be found!');
			#end
			return null;
		}

		if(settings.exists(saveTag)) return settings.get(saveTag);
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		PlayState.instance.addTextToDebug('getModSetting: "$saveTag" could not be found inside $modName\'s settings!', FlxColor.RED);
		#else
		FlxG.log.warn('getModSetting: "$saveTag" could not be found inside $modName\'s settings!');
		#end
		#end
		return null;
	}

	public static function isMap(variable:Dynamic) {
		return (variable.exists != null && variable.keyValueIterator != null);
	}

	public static function getVarInstance(variable:String, checkLuaFirst:Bool = true, checkForTextsToo:Bool = true):Dynamic {
		var ind:Int = variable.indexOf('.');
		if (ind == -1) {
			if (PlayState.instance.variables.exists(variable)) return PlayState.instance.variables.get(variable);
			return checkLuaFirst ? getObjectDirectly(variable, checkForTextsToo) : getVarInArray(getInstance(), variable);
		}

		var obj:Dynamic = getObjectDirectly(variable.substr(0, ind), checkForTextsToo);
		while (ind != -1) obj = getVarInArray(obj, variable.substring(ind + 1, (ind = variable.indexOf('.', ind + 1)) == -1 ? variable.length : ind));
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

	public static function getPropertyLoop(split:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool = true, ?allowMaps:Bool = false):Dynamic {
		var obj:Dynamic = getObjectDirectly(split[0], checkForTextsToo);
		for (i in 1...(getProperty ? split.length - 1 : split.length)) obj = getVarInArray(obj, split[i], allowMaps);
		return obj;
	}

	public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true, ?allowMaps:Bool = false):Dynamic {
		switch(objectName) {
			case 'this' | 'instance' | 'game': return PlayState.instance;
			
			default:
				var obj:Dynamic = PlayState.instance.getLuaObject(objectName, checkForTextsToo);
				if(obj == null) obj = getVarInArray(getInstance(), objectName, allowMaps);
				return obj;
		}
	}

	inline public static function getTextObject(name:String):FlxText {
		return #if LUA_ALLOWED PlayState.instance.modchartTexts.exists(name) ? PlayState.instance.modchartTexts.get(name) : #end Reflect.getProperty(PlayState.instance, name);
	}
	
	public static inline function getInstance():flixel.FlxState {
		return PlayState.instance.isDead ? substates.GameOverSubstate.instance : PlayState.instance;
	}

	static final _lePoint:FlxPoint = FlxPoint.get();

	inline public static function getMousePoint(camera:String, axis:String):Float {
		FlxG.mouse.getScreenPosition(cameraFromString(camera), _lePoint);
		return (axis == 'y' ? _lePoint.y : _lePoint.x);
	}

	inline public static function getPoint(leVar:String, type:String, axis:String, ?camera:String):Float {
		var obj:FlxSprite = getVarInstance(leVar);
		if (obj != null) {
			switch(type) {
				case 'graphic': obj.getGraphicMidpoint(_lePoint);
				case 'screen': obj.getScreenPosition(_lePoint, cameraFromString(camera));
				default: obj.getMidpoint(_lePoint);
			}
			return (axis == 'y' ? _lePoint.y : _lePoint.x);
		}
		return 0;
	}

	public static function setBarColors(bar:Bar, color1:String, color2:String) {
		final left_color:Null<FlxColor> = (color1 != null && color1 != '' ? CoolUtil.colorFromString(color1) : null);
		final right_color:Null<FlxColor> = (color2 != null && color2 != '' ? CoolUtil.colorFromString(color2) : null);
		bar.setColors(left_color, right_color);
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

	public static function addAnimByIndices(obj:String, name:String, prefix:String, indices:Any = null, framerate:Int = 24, loop:Bool = false) {
		var obj:FlxSprite = cast getObjectDirectly(obj, false);
		if(obj != null && obj.animation != null) {
			if(indices == null) indices = [0];
			else if(Std.isOfType(indices, String)) indices = flixel.util.FlxStringUtil.toIntArray(cast indices);

			obj.animation.addByIndices(name, prefix, indices, '', framerate, loop);
			if(obj.animation.curAnim == null) {
				var dyn:Dynamic = cast obj;
				if(dyn.playAnim != null) dyn.playAnim(name, true);
				else dyn.animation.play(name, true);
			}
			return true;
		}
		return false;
	}
	public static function loadFrames(spr:FlxSprite, image:String, spriteType:String) {
		spr.frames = switch(spriteType.toLowerCase().trim()) {
			case 'aseprite' | 'jsoni8': Paths.getAsepriteAtlas(image);
			case "packer" | "packeratlas" | "pac": Paths.getPackerAtlas(image);
			default: Paths.getSparrowAtlas(image);
		}
	}

	public static function resetTextTag(tag:String) {
		#if LUA_ALLOWED
		if(!PlayState.instance.modchartTexts.exists(tag)) return;

		var target:FlxText = PlayState.instance.modchartTexts.get(tag);
		target.kill();
		PlayState.instance.remove(target, true);
		target.destroy();
		PlayState.instance.modchartTexts.remove(tag);
		#end
	}

	public static function resetSpriteTag(tag:String) {
		#if LUA_ALLOWED
		if(!PlayState.instance.modchartSprites.exists(tag)) return;

		var target:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
		target.kill();
		PlayState.instance.remove(target, true);
		target.destroy();
		PlayState.instance.modchartSprites.remove(tag);
		#end
	}

	public static function cancelTween(tag:String) {
		#if LUA_ALLOWED
		if(PlayState.instance.modchartTweens.exists(tag)) {
			PlayState.instance.modchartTweens.get(tag).cancel();
			PlayState.instance.modchartTweens.get(tag).destroy();
			PlayState.instance.modchartTweens.remove(tag);
		}
		#end
	}

	public static function tweenPrepare(tag:String, vars:String) {
		cancelTween(tag);
		final variables:Array<String> = vars.split('.');
		return if (variables.length > 1)
			getVarInArray(getPropertyLoop(variables), variables[variables.length - 1]);
		else getObjectDirectly(variables[0]);
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
	inline public static function getTweenTypeByString(?type:String = ''):FlxTweenType {
		return switch(type.toLowerCase().trim()) {
			case 'backward': FlxTweenType.BACKWARD;
			case 'looping' | 'loop': FlxTweenType.LOOPING;
			case 'persist': FlxTweenType.PERSIST;
			case 'pingpong': FlxTweenType.PINGPONG;
			default: FlxTweenType.ONESHOT;
		}
	}

	inline public static function getTweenEaseByString(?ease:String = '') {
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
			case 'smoothstepout': FlxEase.smoothStepOut;
			case 'smootherstepin': FlxEase.smootherStepIn;
			case 'smootherstepinout': FlxEase.smootherStepInOut;
			case 'smootherstepout': FlxEase.smootherStepOut;
			default: FlxEase.linear;
		}
	}

	inline public static function blendModeFromString(blend:String):BlendMode
		return cast(blend.toLowerCase().trim():BlendMode);

	inline public static function axesFromString(axe:String):flixel.util.FlxAxes {
		try {return FlxAxes.fromString(axe);}
		catch(e) {
			Logs.trace('axesFromString: invalid axes: $axe!', ERROR);
			return FlxAxes.XY;
		}
	}

	inline public static function typeToString(type:Int):String {
		#if LUA_ALLOWED
		return switch(type) {
			case Lua.LUA_TBOOLEAN: "boolean";
			case Lua.LUA_TNUMBER: "number";
			case Lua.LUA_TSTRING: "string";
			case Lua.LUA_TTABLE: "table";
			case Lua.LUA_TFUNCTION: "function";
			default: (type <= Lua.LUA_TNIL ? "nil" : "unknown");
		}
		#else
		return "unknown";
		#end
	}

	public static function cameraFromString(cam:String):FlxCamera {
		switch(cam.toLowerCase()) {
			case 'camgame' | 'game': return PlayState.instance.camGame;
			case 'camhud' | 'hud': return PlayState.instance.camHUD;
			case 'camother' | 'other': return PlayState.instance.camOther;
		}
		var camera:Dynamic = PlayState.instance.variables.get(cam);
		if (camera == null || !Std.isOfType(camera, FlxCamera)) camera = PlayState.instance.camGame;
		return camera;
	}

	public static function setTextBorderFromString(text:FlxText, border:String) {
		text.borderStyle = switch(border.toLowerCase().trim()) {
			case 'shadow': SHADOW;
			case 'outline': OUTLINE;
			case 'outline_fast', 'outlinefast': OUTLINE_FAST;
			default: NONE;
		}
	}

	inline public static function getBuildTarget():String
		return Sys.systemName().toLowerCase();
}