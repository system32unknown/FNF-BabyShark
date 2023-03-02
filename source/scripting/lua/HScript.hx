package scripting.lua;

#if hscript
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import states.PlayState;

class HScript
{
	#if hscript
	public static var parser:Parser;
	public var interp:Interp;

	public var variables(get, never):Map<String, Dynamic>;

	public function get_variables()
		return interp.variables;
	
	public static function initHaxeModule() {
		#if hscript
		if(FunkinLua.hscript == null)
			FunkinLua.hscript = new HScript(); //TO DO: Fix issue with 2 scripts not being able to use the same variable names
		#end
	}

	public function setVar(key:String, data:Dynamic):Map<String, Dynamic> {
		FunkinLua.hscriptVars.set(key, data);
		
		for (i in FunkinLua.hscriptVars.keys())
			if (!interp.variables.exists(i)) interp.variables.set(i, FunkinLua.hscriptVars.get(i));

		return interp.variables;
	}

	public function new() {
		interp = new Interp();
		parser = new Parser();
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
		@:privateAccess
		parser.line = 1;
		parser.allowTypes = parser.allowMetadata = parser.allowJSON = true;
		return interp.execute(parser.parseString(codeToRun));
	}
	#end
}