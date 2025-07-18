package flxanimate;

import haxe.Json;
import flixel.util.FlxDestroyUtil;
import flxanimate.frames.FlxAnimateFrames;
import flxanimate.data.AnimationData;
import flxanimate.FlxAnimate as OriginalFlxAnimate;

class PsychFlxAnimate extends OriginalFlxAnimate {
	public function loadAtlasEx(img:flixel.system.FlxAssets.FlxGraphicAsset, pathOrStr:String = null, myJson:Dynamic = null) {
		var animJson:AnimAtlas = null;
		if (myJson is String) {
			var trimmed:String = pathOrStr.trim();
			trimmed = trimmed.substr(trimmed.length - 5).toLowerCase();

			if (trimmed == '.json') myJson = File.getContent(myJson); // is a path
			animJson = cast haxe.Json.parse(_removeBOM(myJson));
		} else animJson = cast myJson;

		var isXml:Null<Bool> = null;
		var myData:Dynamic = pathOrStr;

		var trimmed:String = pathOrStr.trim();
		trimmed = trimmed.substr(trimmed.length - 5).toLowerCase();

		if (trimmed == '.json') { // Path is json
			myData = File.getContent(pathOrStr);
			isXml = false;
		} else if (trimmed.substr(1) == '.xml') { // Path is xml
			myData = File.getContent(pathOrStr);
			isXml = true;
		}
		myData = _removeBOM(myData);

		// Automatic if everything else fails
		switch (isXml) {
			case true: myData = Xml.parse(myData);
			case false: myData = Json.parse(myData);
			case null:
				try {
					myData = Json.parse(myData);
					isXml = false;
				} catch (e:Dynamic) {
					myData = Xml.parse(myData);
					isXml = true;
				}
		}

		anim._loadAtlas(animJson);
		if (!isXml) frames = FlxAnimateFrames.fromSpriteMap(cast myData, img);
		else frames = FlxAnimateFrames.fromSparrow(cast myData, img);
		origin = anim.curInstance.symbol.transformationPoint;
	}

	override function draw() {
		if (anim.curInstance == null || anim.curSymbol == null) return;
		super.draw();
	}

	override function destroy() {
		try {
			super.destroy();
		} catch (e:haxe.Exception) {
			anim.stageInstance = FlxDestroyUtil.destroy(anim.stageInstance);
			anim.metadata.destroy();
			anim.library.destroy();
		}
	}

	function _removeBOM(str:String):String { //Removes BOM byte order indicator
		if (str.charCodeAt(0) == 0xFEFF) str = str.substr(1);
		return str;
	}

	public function pauseAnimation() {
		if (anim.curInstance == null || anim.curSymbol == null) return;
		anim.pause();
	}
	public function resumeAnimation() {
		if (anim.curInstance == null || anim.curSymbol == null) return;
		anim.play();
	}
}