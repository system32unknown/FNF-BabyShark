package modcharting;

import modcharting.Modifier;
import modcharting.PlayfieldRenderer;
import modcharting.NoteMovement;
import modcharting.ModchartUtil;

import game.Conductor;
import scripting.lua.FunkinLua;

//for lua and hscript
class ModchartFuncs
{
    public static function loadLuaFunctions()
    {
        #if LUA_ALLOWED
        for (funkin in PlayState.instance.luaArray)
        {
            #if hscript
            funkin.initHaxeModule();
            #end
            
            funkin.addCallback('startMod', function(name:String, modClass:String, type:String = '', pf:Int = -1) {
                startMod(name,modClass,type,pf);
            });
            funkin.addCallback('setMod', function(name:String, value:Float) {
                setMod(name, value);
            });
            funkin.addCallback('setSubMod', function(name:String, subValName:String, value:Float) {
                setSubMod(name, subValName,value);
            });
            funkin.addCallback('setModTargetLane', function(name:String, value:Int) {
                setModTargetLane(name, value);
            });
            funkin.addCallback('setModPlayfield', function(name:String, value:Int) {
                setModPlayfield(name,value);
            });
            funkin.addCallback('addPlayfield', function(?x:Float = 0, ?y:Float = 0, ?z:Float = 0) {
                addPlayfield(x,y,z);
            });
            funkin.addCallback('removePlayfield', function(idx:Int) {
                removePlayfield(idx);
            });
            funkin.addCallback('tweenModifier', function(modifier:String, val:Float, time:Float, ease:String) {
                tweenModifier(modifier,val,time,ease);
            });
            funkin.addCallback('tweenModifierSubValue', function(modifier:String, subValue:String, val:Float, time:Float, ease:String) {
                tweenModifierSubValue(modifier,subValue,val,time,ease);
            });
            funkin.addCallback('setModEaseFunc', function(name:String, ease:String) {
                setModEaseFunc(name,ease);
            });
            funkin.addCallback('set', function(beat:Float, argsAsString:String) {
                set(beat, argsAsString);
            });
            funkin.addCallback('ease', function(beat:Float, time:Float, easeStr:String, argsAsString:String) {
                ease(beat, time, easeStr, argsAsString);  
            });
        }
        #end
        #if (hscript && HSCRIPT_ALLOWED)
        if (FunkinLua.hscript != null)
        {
            FunkinLua.hscript.setVar('Math', Math);
            FunkinLua.hscript.setVar('PlayfieldRenderer', PlayfieldRenderer);
            FunkinLua.hscript.setVar('ModchartUtil', ModchartUtil);
            FunkinLua.hscript.setVar('Modifier', Modifier);
            FunkinLua.hscript.setVar('NoteMovement', NoteMovement);
            FunkinLua.hscript.setVar('NotePositionData', PlayfieldRenderer.NotePositionData);
            FunkinLua.hscript.setVar('ModchartFile', ModchartFile);
        }
        #end
    }

    public static function startMod(name:String, modClass:String, type:String = '', pf:Int = -1, ?instance:ModchartMusicBeatState = null)
    {
        if (instance == null)
        {
            instance = PlayState.instance;
            if (instance.playfieldRenderer.modchart.scriptListen)
            {
                instance.playfieldRenderer.modchart.data.modifiers.push([name, modClass, type, pf]);
            }
        }

        if (instance.playfieldRenderer.modchart.customModifiers.exists(modClass))
        {
            var modifier = new Modifier(name, getModTypeFromString(type), pf);
            if (instance.playfieldRenderer.modchart.customModifiers.get(modClass).interp != null)
                instance.playfieldRenderer.modchart.customModifiers.get(modClass).interp.variables.set('instance', instance);
            instance.playfieldRenderer.modchart.customModifiers.get(modClass).initMod(modifier); //need to do it this way instead because using current value in the modifier script didnt work
            instance.playfieldRenderer.addModifier(modifier);
            return;
        }

        var mod = Type.resolveClass('modcharting.'+modClass);
        if (mod == null) {mod = Type.resolveClass('modcharting.'+modClass+"Modifier");} //dont need to add "Modifier" to the end of every mod

        if (mod != null)
        {
            var modType = getModTypeFromString(type);
            var modifier = Type.createInstance(mod, [name, modType, pf]);
            instance.playfieldRenderer.addModifier(modifier);
        }
    }
    public static function getModTypeFromString(type:String)
    {
        var modType = ModifierType.ALL;
        switch (type.toLowerCase()) {
            case 'player': modType = ModifierType.PLAYERONLY;
            case 'opponent': modType = ModifierType.OPPONENTONLY;
            case 'lane' | 'lanespecific': modType = ModifierType.LANESPECIFIC;
        }
        return modType;
    }

    public static function setMod(name:String, value:Float, ?instance:ModchartMusicBeatState = null)
    {
        if (instance == null)
            instance = PlayState.instance;
        if (instance.playfieldRenderer.modchart.scriptListen)
            instance.playfieldRenderer.modchart.data.events.push(["set", [0, value+","+name]]);
        if (instance.playfieldRenderer.modifiers.exists(name))
            instance.playfieldRenderer.modifiers.get(name).currentValue = value;
    }
    public static function setSubMod(name:String, subValName:String, value:Float, ?instance:ModchartMusicBeatState = null)
    {
        if (instance == null)
            instance = PlayState.instance;
        if (instance.playfieldRenderer.modchart.scriptListen)
            instance.playfieldRenderer.modchart.data.events.push(["set", [0, value+","+name+":"+subValName]]);
        if (instance.playfieldRenderer.modifiers.exists(name))
            instance.playfieldRenderer.modifiers.get(name).subValues.get(subValName).value = value;
    }
    public static function setModTargetLane(name:String, value:Int, ?instance:ModchartMusicBeatState = null)
    {
        if (instance == null)
            instance = PlayState.instance;
        if (instance.playfieldRenderer.modifiers.exists(name))
            instance.playfieldRenderer.modifiers.get(name).targetLane = value;
    }
    public static function setModPlayfield(name:String, value:Int, ?instance:ModchartMusicBeatState = null)
    {
        if (instance == null)
            instance = PlayState.instance;
        if (instance.playfieldRenderer.modifiers.exists(name))
            instance.playfieldRenderer.modifiers.get(name).playfield = value;
    }
    public static function addPlayfield(?x:Float = 0, ?y:Float = 0, ?z:Float = 0, ?instance:ModchartMusicBeatState = null)
    {
        if (instance == null)
            instance = PlayState.instance;
        instance.playfieldRenderer.addNewplayfield(x,y,z);
    }
    public static function removePlayfield(idx:Int, ?instance:ModchartMusicBeatState = null)
    {
        if (instance == null)
            instance = PlayState.instance;
        instance.playfieldRenderer.playfields.remove(instance.playfieldRenderer.playfields[idx]);
    }

    public static function tweenModifier(modifier:String, val:Float, time:Float, ease:String, ?instance:ModchartMusicBeatState = null)
    {
        if (instance == null)
            instance = PlayState.instance;
        instance.playfieldRenderer.tweenModifier(modifier,val,time,ease, Modifier.beat);
    }

    public static function tweenModifierSubValue(modifier:String, subValue:String, val:Float, time:Float, ease:String, ?instance:ModchartMusicBeatState = null)
    {
        if (instance == null)
            instance = PlayState.instance;
        instance.playfieldRenderer.tweenModifierSubValue(modifier,subValue,val,time,ease, Modifier.beat);
    }

    public static function setModEaseFunc(name:String, ease:String, ?instance:ModchartMusicBeatState = null)
    {
        if (instance == null)
            instance = PlayState.instance;
        if (instance.playfieldRenderer.modifiers.exists(name))
        {
            var mod = instance.playfieldRenderer.modifiers.get(name);
            if (Std.isOfType(mod, EaseCurveModifier))
            {
                var temp:Dynamic = mod;
                var castedMod:EaseCurveModifier = temp;
                castedMod.setEase(ease);
            }
        }
    }
    public static function set(beat:Float, argsAsString:String, ?instance:ModchartMusicBeatState = null)
    {
        if (instance == null)
        {
            instance = PlayState.instance;
            if (instance.playfieldRenderer.modchart.scriptListen)
            {
                instance.playfieldRenderer.modchart.data.events.push(["set", [beat, argsAsString]]);
            }
        }
        var args = argsAsString.trim().replace(' ', '').split(',');

        instance.playfieldRenderer.addEvent(beat, function(arguments:Array<String>) {
            for (i in 0...Math.floor(arguments.length/2))
            {
                var name:String = Std.string(arguments[1 + (i*2)]);
                var value:Float = Std.parseFloat(arguments[0 + (i*2)]);
                if(Math.isNaN(value))
                    value = 0;
                if (instance.playfieldRenderer.modifiers.exists(name)) {
                    instance.playfieldRenderer.modifiers.get(name).currentValue = value;
                } else {
                    var subModCheck = name.split(':');
                    if (subModCheck.length > 1)
                    {
                        var modName = subModCheck[0];
                        var subModName = subModCheck[1];
                        if (instance.playfieldRenderer.modifiers.exists(modName))
                            instance.playfieldRenderer.modifiers.get(modName).subValues.get(subModName).value = value;
                    }
                }
                    
            }
        }, args);
    }

    public static function ease(beat:Float, time:Float, ease:String, argsAsString:String, ?instance:ModchartMusicBeatState = null) : Void
    {
        if (instance == null)
        {
            instance = PlayState.instance;
            if (instance.playfieldRenderer.modchart.scriptListen)
            {
                instance.playfieldRenderer.modchart.data.events.push(["ease", [beat, time, ease, argsAsString]]);
            }
        }
            
        if(Math.isNaN(time))
            time = 1;

        var args = argsAsString.trim().replace(' ', '').split(',');
        var func = function(arguments:Array<String>) {
            for (i in 0...Math.floor(arguments.length/2))
            {
                var name:String = Std.string(arguments[1 + (i*2)]);
                var value:Float = Std.parseFloat(arguments[0 + (i*2)]);
                if(Math.isNaN(value))
                    value = 0;
                var subModCheck = name.split(':');
                if (subModCheck.length > 1) {
                    var modName = subModCheck[0];
                    var subModName = subModCheck[1];
                    instance.playfieldRenderer.tweenModifierSubValue(modName,subModName,value,time*Conductor.crochet*0.001,ease, beat);
                } else instance.playfieldRenderer.tweenModifier(name,value,time*Conductor.crochet*0.001,ease, beat);
                
            }
        };
        instance.playfieldRenderer.addEvent(beat, func, args);
    }
}


