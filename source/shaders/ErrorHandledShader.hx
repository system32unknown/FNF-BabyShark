package shaders;

import lime.graphics.opengl.GLProgram;
import utils.system.NativeUtil;
import haxe.Exception;

class ErrorHandledShader extends flixel.system.FlxAssets.FlxShader implements IErrorHandler {
	public var shaderName:String = '';

	public dynamic function onError(error:Dynamic):Void {}

	public function new(?shaderName:String) {
		this.shaderName = shaderName;
		super();
	}

	override function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram {
		try {
			final res:GLProgram = super.__createGLProgram(vertexSource, fragmentSource);
			return res;
		} catch (error:Exception) {
			ErrorHandledShader.crashSave(this.shaderName, error, onError);
			return null;
		}
	}

	public static function crashSave(shaderName:String, error:Dynamic, onError:Dynamic) { // prevent the app from dying immediately
		if (shaderName == null) shaderName = 'unnamed';
		var alertTitle:String = 'Error on Shader: "$shaderName"';
		Logs.error(error);
		#if !debug
		// Save a crash log on Release builds
		var dateNow:String = Date.now().toString().replace(" ", "_").replace(":", "'");
		if (!FileSystem.exists('./crash/')) FileSystem.createDirectory('./crash/');
		var crashLogPath:String = './crash/shader_${shaderName}_${dateNow}.txt';
		File.saveContent(crashLogPath, error);
		NativeUtil.showMessageBox('Error log saved at: $crashLogPath', alertTitle, MSG_ERROR);
		#else
		NativeUtil.showMessageBox('Error logs aren\'t created on debug builds, check the trace log instead.', alertTitle, MSG_ERROR);
		#end
		onError(error);
	}
}

class ErrorHandledRuntimeShader extends flixel.addons.display.FlxRuntimeShader implements IErrorHandler {
	public var shaderName:String = '';

	public dynamic function onError(error:Dynamic):Void {}

	public function new(?shaderName:String, ?fragmentSource:String, ?vertexSource:String) {
		this.shaderName = shaderName;
		super(fragmentSource, vertexSource);
	}

	override function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram {
		try {
			final res:GLProgram = super.__createGLProgram(vertexSource, fragmentSource);
			return res;
		} catch (error:Exception) {
			ErrorHandledShader.crashSave(this.shaderName, error, onError);
			return null;
		}
	}
}

interface IErrorHandler {
	public var shaderName:String;
	public dynamic function onError(error:Dynamic):Void;
}