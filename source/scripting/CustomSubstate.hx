package scripting;

import flixel.FlxObject;

class CustomSubstate extends MusicBeatSubstate {
	public static var name:String = 'unnamed';
	public static var instance:CustomSubstate;

	public static function openCustomSubstate(name:String, ?pauseGame:Bool = false) {
		if (pauseGame) {
			FlxG.camera.followLerp = 0;
			PlayState.instance.persistentUpdate = false;
			PlayState.instance.persistentDraw = true;
			PlayState.instance.paused = true;
			if (FlxG.sound.music != null) {
				FlxG.sound.music.pause();
				PlayState.instance.vocals.pause();
			}
		}
		PlayState.instance.openSubState(new CustomSubstate(name));
	}

	public static function closeCustomSubstate():Bool {
		if (instance != null) {
			PlayState.instance.closeSubState();
			return true;
		}
		return false;
	}

	public static function insertToCustomSubstate(tag:String, ?pos:Int = -1):Bool {
		if (instance != null) {
			var tagObject:FlxObject = cast(MusicBeatState.getVariables().get(tag), FlxObject);
			if (tagObject != null) {
				if (pos < 0) instance.add(tagObject);
				else instance.insert(pos, tagObject);
				return true;
			}
		}
		return false;
	}

	override function create() {
		instance = this;
		PlayState.instance.setOnHScript('customSubstate', instance);

		PlayState.instance.callOnHScript('onCustomSubstateCreate', [name]);
		super.create();
		PlayState.instance.callOnHScript('onCustomSubstateCreatePost', [name]);
	}

	public function new(name:String) {
		CustomSubstate.name = name;
		PlayState.instance.setOnHScript('customSubstateName', name);
		super();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float) {
		PlayState.instance.callOnHScript('onCustomSubstateUpdate', [name, elapsed]);
		super.update(elapsed);
		PlayState.instance.callOnHScript('onCustomSubstateUpdatePost', [name, elapsed]);
	}

	override function destroy() {
		PlayState.instance.callOnHScript('onCustomSubstateDestroy', [name]);
		instance = null;
		name = 'unnamed';

		PlayState.instance.setOnHScript('customSubstate', null);
		PlayState.instance.setOnHScript('customSubstateName', name);
		super.destroy();
	}
}