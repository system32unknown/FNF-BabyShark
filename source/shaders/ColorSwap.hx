package shaders;

class ColorSwap {
	public var shader(default, null):ColorSwapShader = new ColorSwapShader();
	public var hue(default, set):Float = 0;
	public var saturation(default, set):Float = 0;
	public var brightness(default, set):Float = 0;

	public var daAlpha(default, set):Float = 1;
	public var flash(default, set):Float = 0;

	public var flashR(default, set):Float = 1;
	public var flashG(default, set):Float = 1;
	public var flashB(default, set):Float = 1;
	public var flashA(default, set):Float = 1;

	function set_flashR(value:Float):Float {
		flashR = value;
		shader.flashColor.value[0] = flashR;
		return flashR;
	}

	function set_flashG(value:Float):Float {
		flashG = value;
		shader.flashColor.value[1] = flashG;
		return flashG;
	}

	function set_flashB(value:Float):Float {
		flashB = value;
		shader.flashColor.value[2] = flashB;
		return flashB;
	}

	function set_flashA(value:Float):Float {
		flashA = value;
		shader.flashColor.value[3] = flashA;
		return flashA;
	}

	function set_daAlpha(value:Float):Float {
		daAlpha = value;
		shader.daAlpha.value[0] = daAlpha;
		return daAlpha;
	}

	function set_flash(value:Float):Float {
		flash = value;
		shader.flash.value[0] = flash;
		return flash;
	}

	function set_hue(value:Float) {
		hue = value;
		shader.uTime.value[0] = hue;
		return hue;
	}

	function set_saturation(value:Float):Float {
		saturation = value;
		shader.uTime.value[1] = saturation;
		return saturation;
	}

	function set_brightness(value:Float):Float {
		brightness = value;
		shader.uTime.value[2] = brightness;
		return brightness;
	}

	public function new() {
		shader.uTime.value = [0, 0, 0];
		shader.flashColor.value = [1, 1, 1, 1];
		shader.daAlpha.value = [1];
		shader.flash.value = [0];
	}

	inline public function setHSB(h:Float = 0, s:Float = 0, b:Float = 0) {
		hue = h; saturation = b; brightness = b;
	}
	
	inline public function setHSBInt(h:Int = 0, s:Int = 0, b:Int = 0) {
		hue = h / 360; saturation = s / 100; brightness = b / 100;
	}

	inline public function setHSBArray(ray:Array<Float>) {
		ray == null ? setHSB() : setHSB(ray[0], ray[1], ray[2]);
	}
	
	inline public function setHSBIntArray(ray:Array<Int>) {
		ray == null ? setHSB() : setHSBInt(ray[0], ray[1], ray[2]);
	}

	inline public function copyFrom(colorSwap:ColorSwap) {
		setHSB(colorSwap.hue, colorSwap.saturation, colorSwap.brightness);
	}
}

class ColorSwapShader extends flixel.system.FlxAssets.FlxShader {
	@:glFragmentSource('
		#pragma header

		uniform vec3 uTime;
		uniform float daAlpha;
		uniform float flash;
		uniform vec4 flashColor;

        vec4 colorMult(vec4 color) {
			if (!hasTransform) return color;
			if (color.a == 0.0) return vec4(0.0, 0.0, 0.0, 0.0);
			if (!hasColorTransform) return color * openfl_Alphav;

			color = vec4(color.rgb / color.a, color.a);

			mat4 colorMultiplier = mat4(0);
			colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
			colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
			colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
			colorMultiplier[3][3] = openfl_ColorMultiplierv.w;

			color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);

			if (color.a > 0.0) {
				return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
			}
			return vec4(0.0, 0.0, 0.0, 0.0);
		}

		vec3 rgb2hsv(vec3 c) {
			vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
			vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
			vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

			float d = q.x - min(q.w, q.y);
			float e = 1.0e-10;
			return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
		}

		vec3 hsv2rgb(vec3 c) {
			vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
			vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
			return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
		}

		void main()
		{
			vec4 color = texture2D(bitmap, openfl_TextureCoordv);
			vec4 swagColor = vec4(rgb2hsv(vec3(color[0], color[1], color[2])), color[3]);

			swagColor[0] = swagColor[0] + uTime[0];
			swagColor[1] = swagColor[1] * (1.0 + uTime[1]);
			swagColor[2] = swagColor[2] * (1.0 + uTime[2]);
			
			if(swagColor[1] < 0.0)
			{
				swagColor[1] = 0.0;
			}
			else if(swagColor[1] > 1.0)
			{
				swagColor[1] = 1.0;
			}

			color = vec4(hsv2rgb(vec3(swagColor[0], swagColor[1], swagColor[2])), swagColor[3]);

			if(flash != 0.0) color = mix(color, flashColor, flash) * color.a;
			color *= daAlpha;
			gl_FragColor = colorMult(color);
		}')
	public function new() {super();}
}