package shaders;

import flixel.system.FlxAssets.FlxShader;
import openfl.Lib;

class VCRDistortionEffect extends Effect
{
    public var shader(default, null):VCRDistortionShader = new VCRDistortionShader();

    public var glitchModifier(default, set):Float = 0.5;
    public var vignetteOn(default, set):Bool = true;
    public var perspectiveOn(default, set):Bool = true;
    public var distortionOn(default, set):Bool = false;
    public var vignetteMoving(default, set):Bool = true;
    public var scanlinesOn(default, set):Bool = true;
    public var iResolution(default, set):Dynamic = [Lib.current.stage.stageWidth, Lib.current.stage.stageHeight];

    public function new() {
        shader.iTime.value = [0];
    }

    public function update(elapsed:Float):Void {
        shader.iTime.value[0] += elapsed;
        shader.iResolution.value = [iResolution];
    }

    public function set_glitchModifier(modifier:Float):Float {
        glitchModifier = modifier;
        shader.glitchModifier.value = [glitchModifier];
        return modifier;
    }

    public function set_vignetteOn(state:Bool):Bool {
        vignetteOn = state; 
        shader.vignetteOn.value = [vignetteOn];
        return state;
    }

    public function set_perspectiveOn(state:Bool):Bool {
        perspectiveOn = state;
        shader.perspectiveOn.value = [perspectiveOn];
        return state;
    }

    public function set_distortionOn(state:Bool):Bool {
        distortionOn = state;
        shader.distortionOn.value = [distortionOn];
        return state;
    }

    public function set_vignetteMoving(state:Bool):Bool {
        vignetteMoving = state;
        shader.vignetteMoving.value = [vignetteMoving];
        return state;
    }

    public function set_scanlinesOn(state:Bool):Bool {
        scanlinesOn = state;
        shader.scanlinesOn.value = [scanlinesOn];
        return state;
    }

    public function set_iResolution(state:Dynamic):Dynamic {
        iResolution = state;
        shader.iResolution.value = [iResolution];
        return state;
    }
}

class VCRDistortionShader extends FlxShader {
    @:glFragmentSource('
        #pragma header

        uniform float iTime;
        uniform bool vignetteOn;
        uniform bool perspectiveOn;
        uniform bool distortionOn;
        uniform bool scanlinesOn;
        uniform bool vignetteMoving;
        uniform float glitchModifier;
        uniform vec3 iResolution;

        float onOff(float a, float b, float c)
        {
        	return step(c, sin(iTime + a*cos(iTime*b)));
        }

        float ramp(float y, float start, float end)
        {
        	float inside = step(start,y) - step(end,y);
        	float fact = (y-start)/(end-start)*inside;
        	return (1.-fact) * inside;
        }

        vec4 getVideo(vec2 uv) {
          	vec2 look = uv;
            if(distortionOn){
            	float window = 1./(1.+20.*(look.y-mod(iTime/4.,1.))*(look.y-mod(iTime/4.,1.)));
            	look.x = look.x + (sin(look.y*10. + iTime)/50.*onOff(4.,4.,.3)*(1.+cos(iTime*80.))*window)*(glitchModifier*2);
            	float vShift = 0.4*onOff(2.,3.,.9)*(sin(iTime)*sin(iTime*20.) +
            										 (0.5 + 0.1*sin(iTime*200.)*cos(iTime)));
            	look.y = mod(look.y + vShift*glitchModifier, 1.);
            }
          	vec4 video = flixel_texture2D(bitmap,look);

          	return video;
        }

        vec2 screenDistort(vec2 uv)
        {
            if(perspectiveOn) {
                uv = (uv - 0.5) * 2.0;
          	    uv *= 1.1;
          	    uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
          	    uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
          	    uv  = (uv / 2.0) + 0.5;
          	    uv =  uv * 0.92 + 0.04;
          	    return uv;
            }
        	return uv;
        }

        float random(vec2 uv)
        {
         	return fract(sin(dot(uv, vec2(15.5151, 42.2561))) * 12341.14122 * sin(iTime * 0.03));
        }

        float noise(vec2 uv)
        {
         	vec2 i = floor(uv);
            vec2 f = fract(uv);

            float a = random(i);
            float b = random(i + vec2(1.,0.));
        	float c = random(i + vec2(0., 1.));
            float d = random(i + vec2(1.));

            vec2 u = smoothstep(0., 1., f);

            return mix(a, b, u.x) + (c - a) * u.y * (1. - u.x) + (d - b) * u.x * u.y;
        }

        vec2 scandistort(vec2 uv) {
        	float scan1 = clamp(cos(uv.y * 2.0 + iTime), 0.0, 1.0);
        	float scan2 = clamp(cos(uv.y * 2.0 + iTime + 4.0) * 10.0, 0.0, 1.0) ;
        	float amount = scan1 * scan2 * uv.x;

        	return uv;
        }

        void main()
        {
        	vec2 uv = openfl_TextureCoordv;
            vec2 curUV = screenDistort(uv);
        	uv = scandistort(curUV);
        	vec4 video = getVideo(uv);
            float vigAmt = 1.0;
            float x = 0.;

            video.r = getVideo(vec2(x + uv.x + 0.001, uv.y + 0.001)).x + 0.05;
            video.g = getVideo(vec2(x + uv.x + 0.000, uv.y - 0.002)).y + 0.05;
            video.b = getVideo(vec2(x + uv.x - 0.002, uv.y + 0.000)).z + 0.05;
            video.r += 0.08 * getVideo(0.75 * vec2(x + 0.025, -0.027) + vec2(uv.x + 0.001, uv.y + 0.001)).x;
            video.g += 0.05 * getVideo(0.75 * vec2(x + -0.022, -0.02) + vec2(uv.x + 0.000, uv.y - 0.002)).y;
            video.b += 0.08 * getVideo(0.75 * vec2(x + -0.02, -0.018) + vec2(uv.x - 0.002, uv.y + 0.000)).z;

            video = clamp(video * 0.6 + 0.4 * video * video *1.0, 0.0, 1.0);
            if(vignetteMoving)
        	    vigAmt = 3.+.3 * sin(iTime + 5. * cos(iTime * 5.));

        	float vignette = (1. - vigAmt * (uv.y - .5) * (uv.y - .5)) * (1. - vigAmt * (uv.x - .5) * (uv.x - .5));

            if(vignetteOn)
        	    video *= vignette;

            gl_FragColor = mix(video, vec4(noise(uv * 75.)), .05);

            if(curUV.x < 0 || curUV.x > 1 || curUV.y < 0 || curUV.y > 1) {
                gl_FragColor = vec4(0, 0, 0, 0);
            }
        }
    ')

    public function new() {
       super();
    }
}

class Effect {
	public function setValue(shader:FlxShader, variable:String, value:Float) {
		Reflect.setProperty(Reflect.getProperty(shader, 'variable'), 'value', [value]);
	}
}