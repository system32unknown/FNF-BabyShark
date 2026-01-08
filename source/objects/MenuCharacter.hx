package objects;

typedef MenuCharacterFile = {
	var image:String;
	var scale:Float;
	var offset:Array<Float>;
	var idle:String;
	var confirm:String;
	var ?flipX:Bool;
	var ?antialiasing:Bool;
}

class MenuCharacter extends FlxSprite {
	public var character:String;
	var _file:MenuCharacterFile;

	public var hasConfirmAnimation:Bool = false;
	inline static final DEFAULT_CHARACTER:String = 'bf';

	public function new(?x:Float, ?y:Float, ?name:String = 'bf') {
		super(x, y);
		changeCharacter(name);
	}

	public function changeCharacter(?character:String = DEFAULT_CHARACTER) {
		if (character == null) character = '';
		if (character == this.character) return;

		this.character = character;
		visible = true;

		scale.set(1, 1);
		updateHitbox();

		color = FlxColor.WHITE;
		alpha = 1;

		hasConfirmAnimation = false;
		if (character.length == 0) {
			visible = false;
			return;
		}

		var path:String = Paths.getPath('images/menucharacters/$character.json');
		if (!Paths.exists(path)) {
			path = Paths.getSharedPath('characters/$DEFAULT_CHARACTER.json'); //If a character couldn't be found, change him to BF just to prevent a crash
			color = FlxColor.BLACK;
			alpha = 0.6;
		}

		try {
			_file = haxe.Json.parse(#if MODS_ALLOWED File.getContent #else Assets.getText #end(path));
		} catch (e:Dynamic) Logs.error('Error loading menu character file of "$character": $e');

		frames = Paths.getSparrowAtlas('menucharacters/' + _file.image);
		animation.addByPrefix('idle', _file.idle, 24);

		var confirmAnim:String = _file.confirm;
		if (confirmAnim != null && confirmAnim.length > 0 && confirmAnim != _file.idle) {
			animation.addByPrefix('confirm', confirmAnim, 24, false);
			if (animation.getByName('confirm') != null) hasConfirmAnimation = true; // check for invalid animation
		}
		flipX = (_file.flipX == true);

		if (_file.scale != 1) {
			scale.set(_file.scale, _file.scale);
			updateHitbox();
		}
		offset.set(_file.offset[0], _file.offset[1]);
		animation.play('idle');
		antialiasing = (_file.antialiasing != false && Settings.data.antialiasing);
	}
}