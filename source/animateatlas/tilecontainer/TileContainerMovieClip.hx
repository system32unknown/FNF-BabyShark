package animateatlas.tilecontainer;

import animateatlas.HelperEnums.LoopMode;
import animateatlas.HelperEnums.SymbolType;
import openfl.display.TileContainer;

@:access(animateatlas.tilecontainer.TileContainerSymbol)
class TileContainerMovieClip extends TileContainer {
	public var framerate(get, set):Float;
	public var currentLabel(get, set):String;
	public var currentFrame(get, set):Int;
	public var type(get, set):String;
	public var loopMode(get, set):String;
	public var symbolName(get, never):String;
	public var numLayers(get, never):Int;
	public var numFrames(get, never):Int;
	public var layers(get, never):Array<TileContainer>; // ! Dangerous AF.

	var symbol:TileContainerSymbol;
	var _framerate:Null<Float> = null;

	var frameElapsed:Float = 0;

	public function new(symbol:TileContainerSymbol) {
		super();
		this.symbol = symbol;
		addTile(this.symbol);
	}

	public function update(dt:Int) {
		var frameDuration:Float = 1000 / framerate;
		frameElapsed += dt;

		while (frameElapsed > frameDuration) {
			frameElapsed -= frameDuration;
			symbol.nextFrame();
		}
		while (frameElapsed < -frameDuration) {
			frameElapsed += frameDuration;
			symbol.prevFrame();
		}
	}

	public function getFrameLabels():Array<String> {
		return symbol.getFrameLabels();
	}

	public function getFrame(label:String):Int {
		return symbol.getFrame(label);
	}
	public function getFramesofAnim(label:String):Int {
		var framesArray:Array<Int>;
		var uncalculatedArray:Array<Int> = [];
		var uncalculatedFrames:Int = 0;
		
		for (i in 0...getFrameLabels().length) {
			uncalculatedArray.push(getFrame(getFrameLabels()[i]));
		}
		uncalculatedFrames = uncalculatedArray[0] + uncalculatedArray.length;

		return uncalculatedFrames;
	}

	// # region Property setter and getter

	function set_currentLabel(value:String):String {
		symbol.currentFrame = symbol.getFrame(value);
		return value;
	}

	function get_currentLabel():String {
		return symbol.currentLabel;
	}

	function set_currentFrame(value:Int):Int {
		symbol.currentFrame = value;
		return value;
	}

	public function get_animFrames():Int{
		return symbol.get_numFrames();
	}

	function get_currentFrame():Int {
		return symbol.currentFrame;
	}

	function set_type(value:SymbolType):SymbolType {
		symbol.type = value;
		return value;
	}

	function get_type():SymbolType {
		return symbol.type;
	}

	function set_loopMode(value:LoopMode):LoopMode {
		symbol.loopMode = value;
		return value;
	}

	function get_loopMode():LoopMode {
		return symbol.loopMode;
	}

	function get_symbolName():String {
		return symbol.symbolName;
	}

	public function get_numLayers():Int {
		return symbol.numLayers;
	}

	function get_numFrames():Int {
		return symbol.numFrames;
	}

	public function get_layers():Array<TileContainer> {
		return symbol._layers;
	}

	function set_framerate(value:Float):Float {
		return _framerate = value;
	}

	function get_framerate():Float {
		return _framerate == null ? symbol._library.frameRate : _framerate;
	}
	// # end region
}
