package shaders;

import flixel.system.FlxAssets.FlxShader;

class GlitchEffect 
{
    public var shader(default,null):GlitchShader = new GlitchShader();

    public var waveSpeed(default, set):Float = 0;
	public var waveFrequency(default, set):Float = 0;
	public var waveAmplitude(default, set):Float = 0;
    public var isBG(default, set):Bool = false;
    public var enabled(default, set):Bool = true;

	public function new() {
		shader.uTime.value = [0];
	}

    public function update(elapsed:Float):Void {
        shader.uTime.value[0] += elapsed;
    }

    function set_waveSpeed(v:Float):Float {
        waveSpeed = v;
        shader.uSpeed.value = [waveSpeed];
        return v;
    }
    
    function set_waveFrequency(v:Float):Float {
        waveFrequency = v;
        shader.uFrequency.value = [waveFrequency];
        return v;
    }
    
    function set_waveAmplitude(v:Float):Float {
        waveAmplitude = v;
        shader.uWaveAmplitude.value = [waveAmplitude];
        return v;
    }

    function set_isBG(v:Bool):Bool {
        isBG = v;
        shader.uDistortBG.value = [isBG];
        return v;
    }

    function set_enabled(v:Bool):Bool {
        enabled = v;
        shader.uEnabled.value = [enabled];
        return v;
    }
}
 
class GlitchShader extends FlxShader
{
    @:glFragmentSource('
    #pragma header 

    //modified version of the wave shader to create weird garbled corruption like messes
    uniform float uTime;
    
    /*
     * How fast the waves move over time
    */
    uniform float uSpeed;
    
    /*
     * Number of waves over time
    */
    uniform float uFrequency;
    
    /*
     * How much the pixels are going to stretch over the waves
    */
    uniform float uWaveAmplitude;
    /*
     * Distort BG?
    */
    uniform bool uDistortBG;

    /*
     * Enabled?
    */
    uniform bool uEnabled;
    
    vec2 sineWave(vec2 pt) {
        if (!uEnabled) return vec2(pt.x, pt.y);

        float x = 0.0;
        float y = 0.0;
        
        float offsetX = sin(pt.y * uFrequency + uTime * uSpeed) * (uWaveAmplitude / pt.x * pt.y);
        float offsetY = sin(pt.x * uFrequency - uTime * uSpeed) * (uDistortBG ? (uWaveAmplitude / pt.y * pt.x) : (uWaveAmplitude));
        pt.x += offsetX;
        pt.y += offsetY;
        return vec2(pt.x + x, pt.y + y);
    }
    
    void main() {
        vec2 uv = sineWave(openfl_TextureCoordv);
        gl_FragColor = texture2D(bitmap, uv);
    }')

    public function new() {super();}
}