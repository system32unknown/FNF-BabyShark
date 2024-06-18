package debug.framerate;

import flixel.util.FlxStringUtil;
import openfl.display3D.Context3D;
import lime.system.System;
import haxe.macro.Compiler;

class SystemInfo extends FramerateCategory {
	public static var osInfo:String = "Unknown";
	public static var gpuName:String = "Unknown";
	public static var vRAM:String = "Unknown";
	public static var cpuName:String = "Unknown";
	public static var totalMem:String = "Unknown";

	static var __formattedSysText:String = "";

	public static inline function init() {
		if (System.platformLabel != null && System.platformLabel != "" && System.platformVersion != null && System.platformVersion != "")
			osInfo = '${System.platformLabel.replace(System.platformVersion, "").trim()} ${System.platformVersion}';
		else Logs.trace('Unable to grab OS Label', ERROR, RED);

		@:privateAccess {
			if (FlxG.stage.context3D != null && FlxG.stage.context3D.gl != null) {
				gpuName = Std.string(FlxG.stage.context3D.gl.getParameter(FlxG.stage.context3D.gl.RENDERER)).split("/")[0].trim();

				if(Context3D.__glMemoryTotalAvailable != -1) {
					var vRAMBytes:UInt = cast(FlxG.stage.context3D.gl.getParameter(Context3D.__glMemoryTotalAvailable), UInt);
					if (vRAMBytes == 1000 || vRAMBytes == 1 || vRAMBytes <= 0)
						Logs.trace('Unable to grab GPU VRAM', ERROR, RED);
					else vRAM = FlxStringUtil.formatBytes(vRAMBytes);
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
		var gl:Dynamic = FlxG.stage.context3D.gl;

		switch (info) {
			case RENDERER: return Std.string(gl.getParameter(gl.RENDERER));
			case SHADING_LANGUAGE_VERSION: return Std.string(gl.getParameter(gl.SHADING_LANGUAGE_VERSION));
		}
		return '';
	}

	static function formatSysInfo() {
		__formattedSysText = "";
		if (osInfo != "Unknown") __formattedSysText += 'System: $osInfo';
		if (cpuName != "Unknown") __formattedSysText += '\nCPU: $cpuName ${openfl.system.Capabilities.cpuArchitecture} ${(openfl.system.Capabilities.supports64BitProcesses ? '64-Bit' : '32-Bit')}';
		if (gpuName != cpuName || vRAM != "Unknown") {
			var gpuNameKnown:Bool = gpuName != "Unknown" && gpuName != cpuName;
			var vramKnown:Bool = vRAM != "Unknown";

			if(gpuNameKnown || vramKnown) __formattedSysText += "\n";

			if(gpuNameKnown) __formattedSysText += 'GPU: $gpuName';
			if(gpuNameKnown && vramKnown) __formattedSysText += " | ";
			if(vramKnown) __formattedSysText += 'VRAM: $vRAM'; // 1000 bytes of vram (apus)
		}
		if (totalMem != "Unknown") __formattedSysText += '\nTotal MEM: $totalMem';
		__formattedSysText += "\nGL Render: " + getGLInfo(RENDERER);
		__formattedSysText += "\nGL Shading version: " + getGLInfo(SHADING_LANGUAGE_VERSION);
	}

	public function new() {
		super("System Info");
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;

		_text = __formattedSysText;

		this.text.text = _text;
		super.__enterFrame(t);
	}
}
enum GLInfo {
	RENDERER;
	SHADING_LANGUAGE_VERSION;
}