package shaders;

import flixel.system.FlxAssets.FlxShader;

class PulseEffect {
    public var shader(default, null):PulseShader = new PulseShader();

    public var waveSpeed(default, set):Float = 0;
	public var waveFrequency(default, set):Float = 0;
	public var waveAmplitude(default, set):Float = 0;
    public var ampmul(default, set):Float = 0;

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

    function set_ampmul(v:Float):Float {
        ampmul = v;
        shader.uampmul.value = [ampmul];
        return v;
    }
}
 
class PulseShader extends FlxShader
{
    @:glFragmentSource('
    #pragma header
    uniform float uampmul;

    //modified version of the wave shader to create weird garbled corruption like messes
    uniform float uTime;
    
    /**
     * How fast the waves move over time
     */
    uniform float uSpeed;
    
    /**
     * Number of waves over time
     */
    uniform float uFrequency;
    
    /**
     * How much the pixels are going to stretch over the waves
     */
    uniform float uWaveAmplitude;

    vec4 sineWave(vec4 pt, vec2 pos) {
        if (uampmul > 0.0) {
            float offsetX = sin(pt.y * uFrequency + uTime * uSpeed);
            float offsetY = sin(pt.x * (uFrequency * 2) - (uTime / 2) * uSpeed);
            float offsetZ = sin(pt.z * (uFrequency / 2) + (uTime / 3) * uSpeed);
            pt.x = mix(pt.x, sin(pt.x / 2 * pt.y + (5 * offsetX) * pt.z), uWaveAmplitude * uampmul);
            pt.y = mix(pt.y, sin(pt.y / 3 * pt.z + (2 * offsetZ) - pt.x), uWaveAmplitude * uampmul);
            pt.z = mix(pt.z, sin(pt.z / 6 * (pt.x * offsetY) - (50 * offsetZ) * (pt.z * offsetX)), uWaveAmplitude * uampmul);
        }

        return vec4(pt.x, pt.y, pt.z, pt.w);
    }

    void main() {
        vec2 uv = openfl_TextureCoordv;
        gl_FragColor = sineWave(texture2D(bitmap, uv), uv);
    }')

    public function new()
    {
       super();
    }
}