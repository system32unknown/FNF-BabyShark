package psychlua;

import objects.Bar;
import flixel.util.FlxAxes;
import openfl.display.BlendMode;
import data.StageData;

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
	public static var Function_Stop:String = "##PSYCHLUA_FUNCTIONSTOP";
	public static var Function_Continue:String = "##PSYCHLUA_FUNCTIONCONTINUE";
	public static var Function_StopLua:String = "##PSYCHLUA_FUNCTIONSTOPLUA";
	public static var Function_StopHScript:String = "##PSYCHLUA_FUNCTIONSTOPHSCRIPT";
	public static var Function_StopAll:String = "##PSYCHLUA_FUNCTIONSTOPALL";

	public static function getLuaTween(options:Dynamic):LuaTweenOptions {
		return (options != null) ? {
			type: getTweenTypeByString(options.type),
			startDelay: options.startDelay,
			onUpdate: options.onUpdate,
			onStart: options.onStart,
			onComplete: options.onComplete,
			loopDelay: options.loopDelay,
			ease: getTweenEaseByString(options.ease)
		} : null;
	}

	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic, allowMaps:Bool = false):Any {
		var splitProps:Array<String> = variable.split('[');
		if (splitProps.length > 1) {
			var target:Dynamic = null;
			if (MusicBeatState.getVariables().exists(splitProps[0])) {
				var retVal:Dynamic = MusicBeatState.getVariables().get(splitProps[0]);
				if (retVal != null) target = retVal;
			} else target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length) {
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				if (i >= splitProps.length - 1) target[j] = value; // Last array
				else target = target[j]; // Anything else
			}
			return target;
		}

		if (allowMaps && isMap(instance)) {
			instance.set(variable, value);
			return value;
		}

		if (instance is MusicBeatState && MusicBeatState.getVariables().exists(variable)) {
			MusicBeatState.getVariables().set(variable, value);
			return value;
		}
		Reflect.setProperty(instance, variable, value);
		return value;
	}

	public static function getVarInArray(instance:Dynamic, variable:String, allowMaps:Bool = false):Any {
		var splitProps:Array<String> = variable.split('[');
		if (splitProps.length > 1) {
			var target:Dynamic = null;
			if (MusicBeatState.getVariables().exists(splitProps[0])) {
				var retVal:Dynamic = MusicBeatState.getVariables().get(splitProps[0]);
				if (retVal != null) target = retVal;
			} else target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length) {
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				target = target[j];
			}
			return target;
		}

		if (allowMaps && isMap(instance)) return instance.get(variable);

		if (instance is MusicBeatState && MusicBeatState.getVariables().exists(variable)) {
			var retVal:Dynamic = MusicBeatState.getVariables().get(variable);
			if (retVal != null) return retVal;
		}
		return Reflect.getProperty(instance, variable);
	}

	public static function getModSetting(saveTag:String, ?modName:String = null):Dynamic {
		#if MODS_ALLOWED
		if (FlxG.save.data.modSettings == null) FlxG.save.data.modSettings = new Map<String, Dynamic>();

		var settings:Map<String, Dynamic> = FlxG.save.data.modSettings.get(modName);
		var path:String = Paths.mods('$modName/data/settings.json');
		if (FileSystem.exists(path)) {
			if (settings == null || !settings.exists(saveTag)) {
				if (settings == null) settings = new Map<String, Dynamic>();
				try {
					var parsedJson:Dynamic = tjson.TJSON.parse(File.getContent(path));
					for (i in 0...parsedJson.length) {
						var sub:Dynamic = parsedJson[i];
						if (sub != null && sub.save != null && !settings.exists(sub.save)) {
							if (sub.type != 'keybind' && sub.type != 'key' && sub.value != null) settings.set(sub.save, sub.value);
							else settings.set(sub.save, {keyboard: (sub.keyboard ?? 'NONE')});
						}
					}
					FlxG.save.data.modSettings.set(modName, settings);
				} catch (e:Dynamic) {
					var errorTitle:String = 'Mod name: ' + Mods.currentModDirectory;
					var errorMsg:String = 'An error occurred: $e';
					utils.system.NativeUtil.showMessageBox(errorMsg, errorTitle);
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

		if (settings.exists(saveTag)) return settings.get(saveTag);
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		PlayState.instance.addTextToDebug('getModSetting: "$saveTag" could not be found inside $modName\'s settings!', FlxColor.RED);
		#else
		FlxG.log.warn('getModSetting: "$saveTag" could not be found inside $modName\'s settings!');
		#end
		#end
		return null;
	}

	public static function isMap(variable:Dynamic):Bool {
		return (variable.exists != null && variable.keyValueIterator != null);
	}

	public static function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic, ?allowMaps:Bool = false):Dynamic {
		var split:Array<String> = variable.split('.');
		if (split.length > 1) {
			var obj:Dynamic = Reflect.getProperty(leArray, split[0]);
			for (i in 1...split.length - 1) obj = Reflect.getProperty(obj, split[i]);

			leArray = obj;
			variable = split[split.length - 1];
		}
		if (allowMaps && isMap(leArray)) leArray.set(variable, value);
		else Reflect.setProperty(leArray, variable, value);
		return value;
	}

	public static function getGroupStuff(leArray:Dynamic, variable:String, ?allowMaps:Bool = false):Dynamic {
		var split:Array<String> = variable.split('.');
		if (split.length > 1) {
			var obj:Dynamic = Reflect.getProperty(leArray, split[0]);
			for (i in 1...split.length - 1) obj = Reflect.getProperty(obj, split[i]);

			leArray = obj;
			variable = split[split.length - 1];
		}

		if (allowMaps && isMap(leArray)) return leArray.get(variable);
		return Reflect.getProperty(leArray, variable);
	}

	public static function getObjectLoop(objectName:String, ?allowMaps:Bool = false):Dynamic {
		var split:Array<String> = objectName.split('.');
		return split.length > 1 ? getVarInArray(getPropertyLoop(split, true, allowMaps), split[split.length - 1], allowMaps) : getObjectDirectly(objectName);
	}

	public static function getPropertyLoop(split:Array<String>, ?getProperty:Bool = true, ?allowMaps:Bool = false):Dynamic {
		var obj:Dynamic = getObjectDirectly(split[0]);
		for (i in 1...(getProperty ? split.length - 1 : split.length)) obj = getVarInArray(obj, split[i], allowMaps);
		return obj;
	}

	public static function getObjectDirectly(objectName:String, ?allowMaps:Bool = false):Dynamic {
		switch (objectName) {
			case 'this' | 'instance' | 'game': return PlayState.instance;

			default:
				var obj:Dynamic = MusicBeatState.getVariables().get(objectName);
				if (obj == null) obj = getVarInArray(getTargetInstance(), objectName, allowMaps);
				return obj;
		}
	}

	public static function isOfTypes(value:Any, types:Array<Dynamic>):Bool {
		for (type in types) if (Std.isOfType(value, type)) return true;
		return false;
	}

	public static function isLuaSupported(value:Any):Bool {
		return (value == null || isOfTypes(value, [Bool, Int, Float, String, Array]) || Type.typeof(value) == Type.ValueType.TObject);
	}

	public static inline function getTargetInstance():flixel.FlxState {
		if (PlayState.instance != null) return PlayState.instance.isDead ? substates.GameOverSubstate.instance : PlayState.instance;
		return MusicBeatState.getState();
	}

	static final _lePoint:FlxPoint = FlxPoint.get();

	inline public static function getMousePoint(camera:String, axis:String):Float {
		FlxG.mouse.getViewPosition(cameraFromString(camera), _lePoint);
		return (axis == 'y' ? _lePoint.y : _lePoint.x);
	}

	inline public static function getPoint(leVar:String, type:String, axis:String, ?camera:String):Float {
		var obj:FlxSprite = LuaUtils.getObjectLoop(leVar);
		if (obj != null) {
			switch (type) {
				case 'graphic': obj.getGraphicMidpoint(_lePoint);
				case 'screen': obj.getScreenPosition(_lePoint, cameraFromString(camera));
				default: obj.getMidpoint(_lePoint);
			}
			return (axis == 'y' ? _lePoint.y : _lePoint.x);
		}
		return 0;
	}

	public static function setBarColors(bar:Bar, color1:String, color2:String) {
		final left_color:Null<FlxColor> = (color1 != null && color1 != '' ? Util.colorFromString(color1) : null);
		final right_color:Null<FlxColor> = (color2 != null && color2 != '' ? Util.colorFromString(color2) : null);
		bar.setColors(left_color, right_color);
	}

	public static inline function getLowestCharacterGroup():FlxSpriteGroup {
		var stageData:StageFile = StageData.getStageFile(PlayState.SONG.stage);
		var group:FlxSpriteGroup = (stageData.hide_girlfriend ? PlayState.instance.boyfriendGroup : PlayState.instance.gfGroup);
		var pos:Int = PlayState.instance.members.indexOf(group);

		var newPos:Int = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
		if (newPos < pos) {
			group = PlayState.instance.boyfriendGroup;
			pos = newPos;
		}

		newPos = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
		if (newPos < pos) {
			group = PlayState.instance.dadGroup;
			pos = newPos;
		}
		return group;
	}

	public static function addAnimByIndices(obj:String, name:String, prefix:String, indices:Any = null, framerate:Float = 24, loop:Bool = false):Bool {
		var obj:FlxSprite = cast getObjectDirectly(obj, false);
		if (obj != null && obj.animation != null) {
			if (indices == null) indices = [0];
			else if (Std.isOfType(indices, String)) indices = flixel.util.FlxStringUtil.toIntArray(cast indices);

			if (prefix != null) obj.animation.addByIndices(name, prefix, indices, '', framerate, loop);
			else obj.animation.add(name, indices, framerate, loop);
			if (obj.animation.curAnim == null) {
				var dyn:Dynamic = cast obj;
				if (dyn.playAnim != null) dyn.playAnim(name, true);
				else dyn.animation.play(name, true);
			}
			return true;
		}
		return false;
	}

	public static function loadFrames(spr:FlxSprite, image:String, spriteType:String):Void {
		spr.frames = switch (spriteType.toLowerCase().replace(' ', '')) {
			case 'aseprite', 'ase', 'json', 'jsoni8': Paths.getAsepriteAtlas(image);
			case "packer", 'packeratlas', 'pac': Paths.getPackerAtlas(image);
			case 'sparrow', 'sparrowatlas', 'sparrowv2': Paths.getSparrowAtlas(image);
			default: Paths.getAtlas(image);
		}
	}

	public static function destroyObject(tag:String):Void {
		var variables:Map<String, Dynamic> = MusicBeatState.getVariables();
		var obj:FlxSprite = variables.get(tag);
		if (obj == null || obj.destroy == null) return;

		getTargetInstance().remove(obj, true);
		obj.destroy();
		variables.remove(tag);
	}

	public static function cancelTween(tag:String):Void {
		if (!tag.startsWith('tween_')) tag = 'tween_' + formatVariable(tag);
		var variables:Map<String, Dynamic> = MusicBeatState.getVariables();
		var twn:FlxTween = variables.get(tag);
		if (twn != null) {
			twn.cancel();
			twn.destroy();
			variables.remove(tag);
		}
	}

	public static function formatVariable(tag:String):String
		return tag.trim().replace(' ', '_').replace('.', '');

	public static function tweenPrepare(tag:String, vars:String):Dynamic {
		if (tag != null) cancelTween(tag);
		return getObjectLoop(vars);
	}

	public static function cancelTimer(tag:String):Void {
		if (!tag.startsWith('timer_')) tag = 'timer_' + formatVariable(tag);
		var variables:Map<String, Dynamic> = MusicBeatState.getVariables();
		var tmr:FlxTimer = variables.get(tag);
		if (tmr != null) {
			tmr.cancel();
			tmr.destroy();
			variables.remove(tag);
		}
	}

	// buncho string stuffs
	inline public static function getTweenTypeByString(?type:String = ''):FlxTweenType {
		return switch (type.toLowerCase().trim()) {
			case 'backward': FlxTweenType.BACKWARD;
			case 'looping' | 'loop': FlxTweenType.LOOPING;
			case 'persist': FlxTweenType.PERSIST;
			case 'pingpong': FlxTweenType.PINGPONG;
			default: FlxTweenType.ONESHOT;
		}
	}

	inline public static function getTweenEaseByString(?ease:String = '') {
		return switch (ease.toLowerCase().trim()) {
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
		return cast(blend.toLowerCase().trim() : BlendMode);

	inline public static function axesFromString(axe:String):FlxAxes {
		try {
			return FlxAxes.fromString(axe);
		} catch (e) {
			Logs.trace('axesFromString: invalid axes: $axe!', ERROR);
			return FlxAxes.XY;
		}
	}

	inline public static function typeToString(type:Int):String {
		#if LUA_ALLOWED
		return switch (type) {
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
		switch (cam.toLowerCase()) {
			case 'camgame' | 'game': return PlayState.instance.camGame;
			case 'camhud' | 'hud': return PlayState.instance.camHUD;
			case 'camother' | 'other': return PlayState.instance.camOther;
		}
		var camera:Dynamic = MusicBeatState.getVariables().get(cam);
		if (camera == null || !Std.isOfType(camera, FlxCamera)) camera = PlayState.instance.camGame;
		return camera;
	}

	public static function setTextBorderFromString(text:FlxText, border:String) {
		text.borderStyle = switch (border.toLowerCase().trim()) {
			case 'shadow': SHADOW;
			case 'outline': OUTLINE;
			case 'outline_fast', 'outlinefast': OUTLINE_FAST;
			default: NONE;
		}
	}

	public static function getTargetOS():String {
		#if windows
		#if x86_BUILD
		return 'windows_x86';
		#else
		return 'windows';
		#end
		#elseif linux
		return 'linux';
		#elseif (mac || macos)
		return 'mac';
		#else
		return 'unknown';
		#end
	}

	public static function getTarget():String {
		#if cpp
		return 'C++';
		#elseif hl
		return 'Hashlink';
		#elseif neko
		return 'Neko';
		#else
		return 'Unknown';
		#end
	}
}