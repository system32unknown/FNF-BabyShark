package shaders;

import flixel.system.FlxAssets.FlxShader;

class ScanlineEffect extends Effect
{
	public var shader(default, null):Scanline = new Scanline();

	public var lockAlpha(default, set):Bool = false;

    public function set_lockAlpha(modifier:Bool):Bool {
        lockAlpha = modifier;
        shader.lockAlpha.value = [lockAlpha];
        return modifier;
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