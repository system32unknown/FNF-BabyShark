package scripting.lua;

#if (hscript && HSCRIPT_ALLOWED)
import hscript.Parser;
import hscript.Interp;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class HScript
{
	#if (hscript && HSCRIPT_ALLOWED)
	public static var parser:Parser;
	public var interp:Interp;

	public var variables(get, never):Map<String, Dynamic>;

	public function get_variables()
		return interp.variables;
	
	public static function initHaxeModule() {
		#if (hscript && HSCRIPT_ALLOWED)
		if(FunkinLua.hscript == null)
			FunkinLua.hscript = new HScript(); //TO DO: Fix issue with 2 scripts not being able to use the same variable names
		#end
	}

	public function setVar(key:String, data:Dynamic):Map<String, Dynamic> {
		variables.set(key, data);
		
		for (i in variables.keys())
			if (!variables.exists(i)) variables.set(i, variables.get(i));

		return variables;
	}

	public function new() {
		interp = new Interp();
		parser = new Parser();

		parser.allowTypes = parser.allowJSON = true;
		parser.line = 1;
		setVars();
	}

	function setVars():Void {
		setVar('FlxG', FlxG);
		setVar('FlxSprite', FlxSprite);
		setVar('FlxCamera', FlxCamera);
		setVar('FlxTimer', FlxTimer);
		setVar('FlxTween', FlxTween);
		setVar('FlxEase', FlxEase);
		setVar('PlayState', states.PlayState);
		setVar('game', states.PlayState.instance);
		setVar('Paths', Paths);
		setVar('Character', game.Character);
		setVar('Alphabet', ui.Alphabet);
		setVar('CustomSubstate', CustomSubstate);
		#if (!flash && sys)
		setVar('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		#end
		setVar('ShaderFilter', openfl.filters.ShaderFilter);
		setVar('StringTools', StringTools);

		setVar('setVar', function(name:String, value:Dynamic) {
			PlayState.instance.variables.set(name, value);
		});
		setVar('getVar', function(name:String) {
			var result:Dynamic = null;
			if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
			return result;
		});
		setVar('removeVar', function(name:String) {
			if(PlayState.instance.variables.exists(name)) {
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});
	}

	public function execute(codeToRun:String):Dynamic {
		return interp.execute(parser.parseString(codeToRun));
	}
	#end
}