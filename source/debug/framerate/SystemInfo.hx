package debug.framerate;

import openfl.display3D.Context3D;
import lime.system.System;

class SystemInfo extends FramerateCategory {
	public static var osInfo:String = "Unknown";
	public static var gpuName:String = "Unknown";
	public static var vRAM:String = "Unknown";
	public static var totalMem:String = "Unknown";

	static var __gpuInfo:Array<String> = [];
	static var __formattedSysText:String = "";

	public static inline function init() {
		if (System.platformLabel != null && System.platformLabel != "" && System.platformVersion != null && System.platformVersion != "")
			osInfo = '${System.platformLabel.replace(System.platformVersion, "").trim()} ${System.platformVersion}';
		else Logs.trace('Unable to grab OS Label', ERROR, RED);

		@:privateAccess {
			if (FlxG.stage.context3D != null && FlxG.stage.context3D.gl != null) {
				__gpuInfo = getGLInfo(RENDERER).split("/");
				gpuName = __gpuInfo[0].trim();

				if(Context3D.__glMemoryTotalAvailable != -1) {
					var vRAMBytes:UInt = cast(FlxG.stage.context3D.gl.getParameter(Context3D.__glMemoryTotalAvailable), UInt);
					if (vRAMBytes == 1000 || vRAMBytes == 1 || vRAMBytes <= 0) Logs.trace('Unable to grab GPU VRAM', ERROR, RED);
					else vRAM = flixel.util.FlxStringUtil.formatBytes(vRAMBytes * 1000);
				}
			} else Logs.trace('Unable to grab GPU Info', ERROR, RED);
		}

		#if cpp
		totalMem = '${utils.system.MemoryUtil.getTotalRam() / 1024}GB';
		#else
		Logs.trace('Unable to grab RAM Amount', ERROR, RED);
		#end
		formatSysInfo();
	}

	static function getGLInfo(info:GLInfo):String {
		@:privateAccess
		var gl:lime.graphics.WebGLRenderContext = FlxG.stage.context3D.gl;

		return switch (info) {
			case RENDERER: Std.string(gl.getParameter(gl.RENDERER));
			case SHADING_LANGUAGE_VERSION: Std.string(gl.getParameter(gl.SHADING_LANGUAGE_VERSION));
			default: '';
		}
	}

	static function formatSysInfo() {
		__formattedSysText = "";
		if (osInfo != "Unknown") __formattedSysText += 'System: $osInfo';
		if (vRAM != "Unknown") {
			var gpuNameKnown:Bool = gpuName != "Unknown";
			var vramKnown:Bool = vRAM != "Unknown";

			if(gpuNameKnown || vramKnown) __formattedSysText += "\n";

			if(gpuNameKnown) __formattedSysText += 'GPU: $gpuName';
			if(gpuNameKnown && vramKnown) __formattedSysText += " | ";
			if(vramKnown) __formattedSysText += 'VRAM: $vRAM'; // 1000 bytes of vram (apus)
		}
		if (totalMem != "Unknown") __formattedSysText += '\nTotal MEM: $totalMem';
		__formattedSysText += "\nGL Version: " + getGLInfo(SHADING_LANGUAGE_VERSION) + " " + __gpuInfo[1].trim();
	}

	public function new() {
		super("System Info");
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;

		_text = __formattedSysText;
		if (this.text.text != _text) this.text.text = _text;
		super.__enterFrame(t);
	}
}
enum GLInfo {
	RENDERER;
	SHADING_LANGUAGE_VERSION;
}