package shaders;

class RGBPalette {
	public var shader(default, null):RGBPaletteShader = new RGBPaletteShader();
	public var r(default, set):FlxColor;
	public var g(default, set):FlxColor;
	public var b(default, set):FlxColor;
	public var mult(default, set):Float;

	public function copyValues(tempShader:RGBPalette) {
		if (tempShader != null) {
			for (i in 0...3) {
				shader.r.value[i] = tempShader.shader.r.value[i];
				shader.g.value[i] = tempShader.shader.g.value[i];
				shader.b.value[i] = tempShader.shader.b.value[i];
			}
			shader.mult.value[0] = tempShader.shader.mult.value[0];
		} else shader.mult.value[0] = 0.0;
	}

	function set_r(color:FlxColor):FlxColor {
		r = color;
		shader.r.value = [color.redFloat, color.greenFloat, color.blueFloat];
		return color;
	}

	function set_g(color:FlxColor):FlxColor {
		g = color;
		shader.g.value = [color.redFloat, color.greenFloat, color.blueFloat];
		return color;
	}

	function set_b(color:FlxColor):FlxColor {
		b = color;
		shader.b.value = [color.redFloat, color.greenFloat, color.blueFloat];
		return color;
	}

	function set_mult(value:Float):Float {
		mult = FlxMath.bound(value, 0, 1);
		shader.mult.value = [mult];
		return value;
	}

	public function new() {
		r = FlxColor.RED;
		g = FlxColor.LIME;
		b = FlxColor.BLUE;
		mult = 1.0;
	}
}

// automatic handler for easy usability
class RGBShaderReference {
	public var r(default, set):FlxColor;
	public var g(default, set):FlxColor;
	public var b(default, set):FlxColor;
	public var mult(default, set):Float;
	public var enabled(default, set):Bool = true;

	public var parent:RGBPalette;
	var _owner:FlxSprite;
	var _original:RGBPalette;
	public function new(owner:FlxSprite, ref:RGBPalette) {
		parent = ref;
		_owner = owner;
		_original = ref;
		owner.shader = ref.shader;

		@:bypassAccessor {
			r = parent.r;
			g = parent.g;
			b = parent.b;
			mult = parent.mult;
		}
	}

	function set_r(value:FlxColor):FlxColor {
		if (allowNew && value != _original.r) cloneOriginal();
		return (r = parent.r = value);
	}
	function set_g(value:FlxColor):FlxColor {
		if (allowNew && value != _original.g) cloneOriginal();
		return (g = parent.g = value);
	}
	function set_b(value:FlxColor):FlxColor {
		if (allowNew && value != _original.b) cloneOriginal();
		return (b = parent.b = value);
	}

	function set_mult(value:Float):Float {
		if (allowNew && value != _original.mult) cloneOriginal();
		return (mult = parent.mult = value);
	}

	function set_enabled(value:Bool):Bool {
		_owner.shader = value ? parent.shader : null;
		return (enabled = value);
	}

	inline public function setRGB(r:FlxColor, g:FlxColor, b:FlxColor) {
		this.r = r;
		this.g = g;
		this.b = b;
	}

	inline public function copyFrom(ref:RGBShaderReference) {
		setRGB(ref.r, ref.g, ref.b);
	}
	inline public function copyFromPalette(palette:RGBPalette) {
		setRGB(palette.r, palette.g, palette.b);
	}

	public var allowNew = true;
	function cloneOriginal() {
		if (!allowNew) return;
		allowNew = false;
		if (_original != parent) return;

		parent = new RGBPalette();
		parent.r = _original.r;
		parent.g = _original.g;
		parent.b = _original.b;
		parent.mult = _original.mult;
		_owner.shader = parent.shader;
	}
}

class RGBPaletteShader extends flixel.system.FlxAssets.FlxShader {
	@:glFragmentHeader('
		#pragma header
		
		uniform vec3 r;
		uniform vec3 g;
		uniform vec3 b;
		uniform float mult;

		vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
			vec4 color = flixel_texture2D(bitmap, coord);
			if (!hasTransform || color.a == 0.0 || mult == 0.0) {
				return color;
			}

			vec4 newColor = color;
			newColor.rgb = min(color.r * r + color.g * g + color.b * b, vec3(1.0));
			newColor.a = color.a;
			
			color = mix(color, newColor, mult);
			
			if (color.a > 0.0) return vec4(color.rgb, color.a);
			return vec4(0.0, 0.0, 0.0, 0.0);
		}')
	@:glFragmentSource('
		#pragma header

		void main() {
			gl_FragColor = flixel_texture2DCustom(bitmap, openfl_TextureCoordv);
		}')
	public function new() {super();}
}