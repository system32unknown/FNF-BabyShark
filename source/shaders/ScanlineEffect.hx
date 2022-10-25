package shaders;

import flixel.system.FlxAssets.FlxShader;

class ScanlineEffect extends Effect
{
	public var shader:Scanline;
	public function new (lockAlpha) {
		shader = new Scanline();
		shader.data.lockAlpha.value = [lockAlpha];
	}
}

class Scanline extends FlxShader
{
    @:glFragmentSource('
	#pragma header
	const float scale = 1.0;
	uniform bool lockAlpha = false;
	void main()
	{
		if (mod(floor(openfl_TextureCoordv.y * openfl_TextureSize.y / scale), 2.0) == 0.0 ){
			float bitch = 1.0;

			vec4 texColor = texture2D(bitmap, openfl_TextureCoordv);
			if (lockAlpha) bitch = texColor.a;
			gl_FragColor = vec4(0.0, 0.0, 0.0, bitch);
		} else {
			gl_FragColor = texture2D(bitmap, openfl_TextureCoordv);
		}
	}')
}
class Effect {
	public function setValue(shader:FlxShader, variable:String, value:Float) {
		Reflect.setProperty(Reflect.getProperty(shader, 'variable'), 'value', [value]);
	}
}