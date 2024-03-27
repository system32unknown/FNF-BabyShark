package objects;

typedef MenuCharacterFile = {
	var image:String;
	var scale:Float;
	var position:Array<Int>;
	var idle_anim:String;
	var confirm_anim:String;
	var flipX:Bool;
}

class MenuCharacter extends FlxSprite {
	public var character:String;
	public var hasConfirmAnimation:Bool = false;
	inline static final DEFAULT_CHARACTER:String = 'bf';

	public function new(x:Float, character:String = DEFAULT_CHARACTER) {
		super(x);
		changeCharacter(character);
	}

	public function changeCharacter(?character:String = DEFAULT_CHARACTER) {
		if(character == null) character = '';
		if(character == this.character) return;

		this.character = character;
		antialiasing = ClientPrefs.data.antialiasing;
		visible = true;

		scale.set(1, 1);
		updateHitbox();

		color = FlxColor.WHITE;
		alpha = 1;

		hasConfirmAnimation = false;
		switch(character) {
			case '': visible = false;
			default:
				var path:String = Paths.getPath('images/menucharacters/$character.json');
				
				if (!#if MODS_ALLOWED FileSystem #else Assets #end.exists(path)) {
					path = Paths.getSharedPath('characters/$DEFAULT_CHARACTER.json'); //If a character couldn't be found, change him to BF just to prevent a crash
					color = FlxColor.BLACK;
					alpha = 0.6;
				}

				var charFile:MenuCharacterFile = null;
				try {
					charFile = haxe.Json.parse(#if MODS_ALLOWED File.getContent #else Assets.getText #end(path));
				} catch(e:Dynamic) Logs.trace('Error loading menu character file of "$character": $e', ERROR);
				frames = Paths.getSparrowAtlas('menucharacters/' + charFile.image);
				animation.addByPrefix('idle', charFile.idle_anim, 24);

				var confirmAnim:String = charFile.confirm_anim;
				if(confirmAnim != null && confirmAnim.length > 0 && confirmAnim != charFile.idle_anim) {
					animation.addByPrefix('confirm', confirmAnim, 24, false);
					if (animation.getByName('confirm') != null) //check for invalid animation
						hasConfirmAnimation = true;
				}

				flipX = (charFile.flipX == true);

				if(charFile.scale != 1) {
					scale.set(charFile.scale, charFile.scale);
					updateHitbox();
				}
				offset.set(charFile.position[0] * scale.x, charFile.position[1] * scale.y);
				animation.play('idle');
		}
	}
}