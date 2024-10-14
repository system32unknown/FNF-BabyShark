package modcharting;

import modcharting.Modifier.ModifierType;
import modcharting.Modifier.EaseCurveModifier;

// for lua and hscript
class ModchartFuncs {
	public static function loadLuaFunctions(funkin:psychlua.FunkinLua) {
		#if LUA_ALLOWED
		funkin.set('startMod', function(name:String, modClass:String, type:String = '', pf:Int = -1) {
			startMod(name, modClass, type, pf);
			PlayState.instance.playfieldRenderer.modifierTable.reconstructTable(); // needs to be reconstructed for lua modcharts
		});
		funkin.set('setMod', function(name:String, value:Float) {
			setMod(name, value);
		});
		funkin.set('setSubMod', function(name:String, subValName:String, value:Float) {
			setSubMod(name, subValName, value);
		});
		funkin.set('setModTargetLane', function(name:String, value:Int) {
			setModTargetLane(name, value);
		});
		funkin.set('setModPlayfield', function(name:String, value:Int) {
			setModPlayfield(name, value);
		});
		funkin.set('addPlayfield', function(?x:Float = 0, ?y:Float = 0, ?z:Float = 0) {
			addPlayfield(x, y, z);
		});
		funkin.set('removePlayfield', function(idx:Int) {
			removePlayfield(idx);
		});
		funkin.set('tweenModifier', function(modifier:String, val:Float, time:Float, ease:String, ?tag:String = null) {
			tweenModifier(modifier, val, time, ease, null, tag);
		});
		funkin.set('tweenModifierSubValue',
			function(modifier:String, subValue:String, val:Float, time:Float, ease:String, ?tag:String = null) {
				tweenModifierSubValue(modifier, subValue, val, time, ease, null, tag);
			});
		funkin.set('setModEaseFunc', function(name:String, ease:String) {
			setModEaseFunc(name, ease);
		});
		funkin.set('set', function(beat:Float, argsAsString:String) {
			set(beat, argsAsString);
		});
		funkin.set('ease', function(beat:Float, time:Float, easeStr:String, argsAsString:String, ?tag:String = null) {
			ease(beat, time, easeStr, argsAsString, null, tag);
		});
		#end
	}

	#if HSCRIPT_ALLOWED
	public static function loadHScriptFunctions(parent:Dynamic) {
		parent.set('startMod', function(name:String, modClass:String, type:String = '', pf:Int = -1) {
			startMod(name, modClass, type, pf);

			if (PlayState.instance == FlxG.state && PlayState.instance.playfieldRenderer != null) {
				PlayState.instance.playfieldRenderer.modifierTable.reconstructTable(); // needs to be reconstructed for lua modcharts
			}
		});
		parent.set('setMod', function(name:String, value:Float) {
			setMod(name, value);
		});
		parent.set('setSubMod', function(name:String, subValName:String, value:Float) {
			setSubMod(name, subValName, value);
		});
		parent.set('setModTargetLane', function(name:String, value:Int) {
			setModTargetLane(name, value);
		});
		parent.set('setModPlayfield', function(name:String, value:Int) {
			setModPlayfield(name, value);
		});
		parent.set('addPlayfield', function(?x:Float = 0, ?y:Float = 0, ?z:Float = 0) {
			addPlayfield(x, y, z);
		});
		parent.set('removePlayfield', function(idx:Int) {
			removePlayfield(idx);
		});
		parent.set('tweenModifier', function(modifier:String, val:Float, time:Float, ease:String, ?tag:String = null) {
			tweenModifier(modifier, val, time, ease, null, tag);
		});
		parent.set('tweenModifierSubValue', function(modifier:String, subValue:String, val:Float, time:Float, ease:String, ?tag:String = null) {
			tweenModifierSubValue(modifier, subValue, val, time, ease, null, tag);
		});
		parent.set('setModEaseFunc', function(name:String, ease:String, ?tag:String = null) {
			setModEaseFunc(name, ease);
		});
		parent.set('setModValue', function(beat:Float, argsAsString:String) {
			set(beat, argsAsString);
		});
		parent.set('easeModValue', function(beat:Float, time:Float, easeStr:String, argsAsString:String, ?tag:String = null) {
			ease(beat, time, easeStr, argsAsString, null, tag);
		});
	}
	#end

	public static function startMod(name:String, modClass:String, type:String = '', pf:Int = -1, ?instance:ModchartMusicBeatState = null) {
		if (instance == null) {
			instance = PlayState.instance;
			if (instance.playfieldRenderer.modchart != null)
				if (instance.playfieldRenderer.modchart.scriptListen) {
					instance.playfieldRenderer.modchart.data.modifiers.push([name, modClass, type, pf]);
					trace(name, modClass, type, pf);
				}
		}

		if (instance.playfieldRenderer.modchart != null)
			if (instance.playfieldRenderer.modchart.customModifiers.exists(modClass)) {
				var modifier = new Modifier(name, getModTypeFromString(type), pf);
				if (instance.playfieldRenderer.modchart.customModifiers.get(modClass).interp != null)
					instance.playfieldRenderer.modchart.customModifiers.get(modClass).interp.variables.set('instance', instance);
				instance.playfieldRenderer.modchart.customModifiers.get(modClass).initMod(modifier); // need to do it this way instead because using current value in the modifier script didnt work
				instance.playfieldRenderer.modifierTable.add(modifier);
				return;
			}

		var mod:Class<Dynamic> = Type.resolveClass('modcharting.' + modClass);
		if (mod == null) mod = Type.resolveClass('modcharting.' + modClass + "Modifier"); // dont need to add "Modifier" to the end of every mod

		if (mod != null) {
			var modType:ModifierType = getModTypeFromString(type);
			var modifier = Type.createInstance(mod, [name, modType, pf]);
			instance.playfieldRenderer.modifierTable.add(modifier);
		}
	}

	public static function getModTypeFromString(type:String):ModifierType {
		var modType:ModifierType = ModifierType.ALL;
		switch (type.toLowerCase()) {
			case 'player': modType = ModifierType.PLAYERONLY;
			case 'opponent': modType = ModifierType.OPPONENTONLY;
			case 'lane' | 'lanespecific': modType = ModifierType.LANESPECIFIC;
		}
		return modType;
	}

	public static function setMod(name:String, value:Float, ?instance:ModchartMusicBeatState = null) {
		if (instance == null) instance = PlayState.instance;
		if (instance.playfieldRenderer.modchart != null)
			if (instance.playfieldRenderer.modchart.scriptListen) {
				instance.playfieldRenderer.modchart.data.events.push(["set", [0, value + "," + name]]);
			}
		if (instance.playfieldRenderer.modifierTable.modifiers.exists(name))
			instance.playfieldRenderer.modifierTable.modifiers.get(name).currentValue = value;
	}

	public static function setSubMod(name:String, subValName:String, value:Float, ?instance:ModchartMusicBeatState = null) {
		if (instance == null) instance = PlayState.instance;
		if (instance.playfieldRenderer.modchart != null)
			if (instance.playfieldRenderer.modchart.scriptListen) {
				instance.playfieldRenderer.modchart.data.events.push(["set", [0, value + "," + name + ":" + subValName]]);
			}
		if (instance.playfieldRenderer.modifiers.exists(name))
			if (instance.playfieldRenderer.modifiers.get(name).subValues.exists(subValName)) instance.playfieldRenderer.modifiers.get(name).subValues.get(subValName).value = value;
			else instance.playfieldRenderer.modifiers.get(name).subValues.set(subValName, new Modifier.ModifierSubValue(value));
	}

	public static function setModTargetLane(name:String, value:Int, ?instance:ModchartMusicBeatState = null) {
		if (instance == null) instance = PlayState.instance;
		if (instance.playfieldRenderer.modifierTable.modifiers.exists(name))
			instance.playfieldRenderer.modifierTable.modifiers.get(name).targetLane = value;
	}

	public static function setModPlayfield(name:String, value:Int, ?instance:ModchartMusicBeatState = null) {
		if (instance == null) instance = PlayState.instance;
		if (instance.playfieldRenderer.modifierTable.modifiers.exists(name))
			instance.playfieldRenderer.modifierTable.modifiers.get(name).playfield = value;
	}

	public static function addPlayfield(?x:Float = 0, ?y:Float = 0, ?z:Float = 0, ?instance:ModchartMusicBeatState = null) {
		if (instance == null) instance = PlayState.instance;
		instance.playfieldRenderer.addNewPlayfield(x, y, z);
	}

	public static function removePlayfield(idx:Int, ?instance:ModchartMusicBeatState = null) {
		if (instance == null)
			instance = PlayState.instance;
		instance.playfieldRenderer.playfields.remove(instance.playfieldRenderer.playfields[idx]);
	}

	public static function tweenModifier(modifier:String, val:Float, time:Float, ease:String, ?instance:ModchartMusicBeatState = null, ?tag:String = null) {
		if (instance == null)
			instance = PlayState.instance;
		instance.playfieldRenderer.modifierTable.tweenModifier(modifier, val, time, ease, Modifier.beat, tag);
	}

	public static function tweenModifierSubValue(modifier:String, subValue:String, val:Float, time:Float, ease:String,
			?instance:ModchartMusicBeatState = null, ?tag:String = null) {
		if (instance == null)
			instance = PlayState.instance;
		instance.playfieldRenderer.modifierTable.tweenModifierSubValue(modifier, subValue, val, time, ease, Modifier.beat, tag);
	}

	public static function setModEaseFunc(name:String, ease:String, ?instance:ModchartMusicBeatState = null) {
		if (instance == null) instance = PlayState.instance;
		if (instance.playfieldRenderer.modifierTable.modifiers.exists(name)) {
			var mod = instance.playfieldRenderer.modifierTable.modifiers.get(name);
			if (Std.isOfType(mod, EaseCurveModifier)) {
				var temp:Dynamic = mod;
				var castedMod:EaseCurveModifier = temp;
				castedMod.setEase(ease);
			}
		}
	}

	public static function set(beat:Float, argsAsString:String, ?instance:ModchartMusicBeatState = null) {
		if (instance == null) {
			instance = PlayState.instance;
			if (instance.playfieldRenderer.modchart != null)
				if (instance.playfieldRenderer.modchart.scriptListen) {
					instance.playfieldRenderer.modchart.data.events.push(["set", [beat, argsAsString]]);
				}
		}
		var args:Array<String> = argsAsString.trim().replace(' ', '').split(',');

		instance.playfieldRenderer.eventManager.addEvent(beat, function(arguments:Array<String>) {
			for (i in 0...Math.floor(arguments.length / 2)) {
				var name:String = Std.string(arguments[1 + (i * 2)]);
				var value:Float = Std.parseFloat(arguments[0 + (i * 2)]);
				if (Math.isNaN(value))
					value = 0;
				if (instance.playfieldRenderer.modifierTable.modifiers.exists(name)) {
					instance.playfieldRenderer.modifierTable.modifiers.get(name).currentValue = value;
				} else {
					var subModCheck = name.split(':');
					if (subModCheck.length > 1) {
						var modName = subModCheck[0];
						var subModName = subModCheck[1];
						if (instance.playfieldRenderer.modifierTable.modifiers.exists(modName))
							instance.playfieldRenderer.modifierTable.modifiers.get(modName).subValues.get(subModName).value = value;
					}
				}
			}
		}, args);
	}

	public static function ease(beat:Float, time:Float, ease:String, argsAsString:String, ?instance:ModchartMusicBeatState = null, ?tag:String = null):Void {
		if (instance == null) {
			instance = PlayState.instance;
			if (instance.playfieldRenderer.modchart != null)
				if (instance.playfieldRenderer.modchart.scriptListen) {
					instance.playfieldRenderer.modchart.data.events.push(["ease", [beat, time, ease, argsAsString, tag]]);
				}
		}

		if (Math.isNaN(time)) time = 1;

		var args:Array<String> = argsAsString.trim().replace(' ', '').split(',');

		var func = function(arguments:Array<String>) {
			for (i in 0...Math.floor(arguments.length / 2)) {
				var name:String = Std.string(arguments[1 + (i * 2)]);
				var value:Float = Std.parseFloat(arguments[0 + (i * 2)]);
				if (Math.isNaN(value))
					value = 0;
				var subModCheck = name.split(':');
				if (subModCheck.length > 1) {
					var modName = subModCheck[0];
					var subModName = subModCheck[1];
					instance.playfieldRenderer.modifierTable.tweenModifierSubValue(modName, subModName, value, time * Conductor.crochet * 0.001, ease, beat, tag);
				} else instance.playfieldRenderer.modifierTable.tweenModifier(name, value, time * Conductor.crochet * 0.001, ease, beat, tag);
			}
		};
		instance.playfieldRenderer.eventManager.addEvent(beat, func, args);
	}
}
