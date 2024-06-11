package shaders;

@:keep
class OverlayBlend extends flixel.system.FlxAssets.FlxShader {
	@:glFragmentSource('
        #pragma header

		uniform sampler2D funnyShit;

		vec4 blendOverlay(vec4 base, vec4 blend) {
			return mix(1.0 - 2.0 * (1.0 - base) * (1.0 - blend), 2.0 * base * blend, step(base, vec4(0.5)));
		}

        void main() {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
			vec4 gf = flixel_texture2D(funnyShit, openfl_TextureCoordv.xy + vec2(.1, .2));

            gl_FragColor = blendOverlay(color, gf);
        }

    ')
	public function new() {
		super();
	}
}
