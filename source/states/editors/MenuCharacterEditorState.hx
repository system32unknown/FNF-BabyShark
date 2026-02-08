package states.editors;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import haxe.Json;
import objects.MenuCharacter;

import states.editors.content.Prompt;

class MenuCharacterEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent {
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var characterFile:MenuCharacterFile = null;
	var txtOffsets:FlxText;
	final defaultCharacters:Array<String> = ['', 'bf', 'gf'];
	var unsavedProgress:Bool = false;

	override function create() {
		characterFile = {
			image: 'Menu_Dad',
			scale: 1,
			offset: [0, 0],
			idle: 'M Dad Idle',
			confirm: 'M Dad Idle',
			flipX: false,
			antialiasing: true
		};
		#if DISCORD_ALLOWED DiscordClient.changePresence("Menu Character Editor", 'Editing: ${characterFile.image}'); #end

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		for (char in 0...3) {
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * .25) * (1 + char) - 150, defaultCharacters[char]);
			weekCharacterThing.y += 70;
			weekCharacterThing.alpha = .2;
			grpWeekCharacters.add(weekCharacterThing);
		}

		add(new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51));
		add(grpWeekCharacters);

		txtOffsets = new FlxText(20, 10, 0, "[0, 0]", 32);
		txtOffsets.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		txtOffsets.alpha = 0.7;
		add(txtOffsets);

		var tipText:FlxText = new FlxText(0, 540, FlxG.width,
			"Arrow Keys - Change Current Offset (Hold shift for 10x speed)
			\nSpace - Play \"Confirm\" animation", 16);
		tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		tipText.scrollFactor.set();
		add(tipText);

		addEditorBox();
		FlxG.mouse.visible = true;
		super.create();
	}

	var UI_typebox:PsychUIBox;
	var UI_mainbox:PsychUIBox;
	function addEditorBox() {
		UI_typebox = new PsychUIBox(100, FlxG.height - 230, 120, 180, ['Character Type']);
		UI_typebox.scrollFactor.set();
		addTypeUI();
		add(UI_typebox);

		UI_mainbox = new PsychUIBox(FlxG.width - 340, FlxG.height - 265, 240, 215, ['Character']);
		UI_mainbox.scrollFactor.set();
		addCharacterUI();
		add(UI_mainbox);

		var loadButton:PsychUIButton = new PsychUIButton(0, 480, "Load Character", () -> loadCharacter());
		loadButton.gameCenter(X).x -= 60;
		add(loadButton);

		var saveButton:PsychUIButton = new PsychUIButton(0, 480, "Save Character", () -> saveCharacter());
		saveButton.gameCenter(X).x += 60;
		add(saveButton);
	}

	var characterTypeRadio:PsychUIRadioGroup;
	function addTypeUI() {
		var tab_group:FlxSpriteGroup = UI_typebox.getTab('Character Type').menu;

		characterTypeRadio = new PsychUIRadioGroup(10, 20, ['Opponent', 'Boyfriend', 'Girlfriend'], 40);
		characterTypeRadio.checked = 0;
		characterTypeRadio.onClick = updateCharacters;
		tab_group.add(characterTypeRadio);
	}

	var imageInputText:PsychUIInputText;
	var idleInputText:PsychUIInputText;
	var confirmInputText:PsychUIInputText;
	var scaleStepper:PsychUINumericStepper;
	var flipXCheckbox:PsychUICheckBox;
	var antialiasingCheckbox:PsychUICheckBox;
	function addCharacterUI() {
		var tab_group:FlxSpriteGroup = UI_mainbox.getTab('Character').menu;

		imageInputText = new PsychUIInputText(10, 20, 80, characterFile.image, 8);
		idleInputText = new PsychUIInputText(10, imageInputText.y + 35, 100, characterFile.idle, 8);
		confirmInputText = new PsychUIInputText(10, idleInputText.y + 35, 100, characterFile.confirm, 8);

		flipXCheckbox = new PsychUICheckBox(10, confirmInputText.y + 30, "Flip X");
		flipXCheckbox.onClick = () -> {
			grpWeekCharacters.members[characterTypeRadio.checked].flipX = flipXCheckbox.checked;
			characterFile.flipX = flipXCheckbox.checked;
		};

		antialiasingCheckbox = new PsychUICheckBox(10, flipXCheckbox.y + 30, "Antialiasing");
		antialiasingCheckbox.checked = grpWeekCharacters.members[characterTypeRadio.checked].antialiasing;
		antialiasingCheckbox.onClick = () -> {
			grpWeekCharacters.members[characterTypeRadio.checked].antialiasing = antialiasingCheckbox.checked;
			characterFile.antialiasing = antialiasingCheckbox.checked;
		};

		var reloadImageButton:PsychUIButton = new PsychUIButton(140, confirmInputText.y + 30, "Reload Char", () -> reloadSelectedCharacter());

		scaleStepper = new PsychUINumericStepper(140, imageInputText.y, 0.05, 1, 0.1, 30, 2);

		tab_group.add(new FlxText(10, imageInputText.y - 18, 0, 'Image file name:'));
		tab_group.add(new FlxText(10, idleInputText.y - 18, 0, 'Idle animation on the .XML:'));
		tab_group.add(new FlxText(scaleStepper.x, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(flipXCheckbox);
		tab_group.add(antialiasingCheckbox);
		tab_group.add(reloadImageButton);
		tab_group.add(new FlxText(10, confirmInputText.y - 18, 0, 'Confirm animation on the .XML:'));
		tab_group.add(imageInputText);
		tab_group.add(idleInputText);
		tab_group.add(confirmInputText);
		tab_group.add(scaleStepper);
	}

	function updateCharacters() {
		for (i in 0...3) {
			var char:MenuCharacter = grpWeekCharacters.members[i];
			char.alpha = 0.2;
			char.name = defaultCharacters[i];
		}
		reloadSelectedCharacter();
	}

	function reloadSelectedCharacter() {
		var char:MenuCharacter = grpWeekCharacters.members[characterTypeRadio.checked];

		char.alpha = 1;
		char.frames = Paths.getSparrowAtlas('menucharacters/' + characterFile.image);
		char.animation.addByPrefix('idle', characterFile.idle, 24);
		if (characterTypeRadio.checked == 1 && characterFile.confirm != null && characterFile.confirm != '' && characterFile.confirm != characterFile.idle) char.animation.addByPrefix('confirm', characterFile.confirm, 24, false);
		char.flipX = (characterFile.flipX == true);

		char.scale.set(characterFile.scale, characterFile.scale);
		char.updateHitbox();
		char.animation.play('idle');

		updateOffset();

		#if DISCORD_ALLOWED DiscordClient.changePresence("Menu Character Editor", "Editing: " + characterFile.image); #end
	}

	public function UIEvent(id:String, sender:Dynamic) {
		if (id == PsychUICheckBox.CLICK_EVENT) unsavedProgress = true;
		if (id == PsychUIInputText.CHANGE_EVENT && (sender is PsychUIInputText)) {
			if (sender == imageInputText) {
				characterFile.image = imageInputText.text;
				unsavedProgress = true;
			} else if (sender == idleInputText) {
				characterFile.idle = idleInputText.text;
				unsavedProgress = true;
			} else if (sender == confirmInputText) {
				characterFile.confirm = confirmInputText.text;
				unsavedProgress = true;
			}
		} else if (id == PsychUINumericStepper.CHANGE_EVENT && (sender is PsychUINumericStepper)) {
			if (sender == scaleStepper) {
				characterFile.scale = scaleStepper.value;
				reloadSelectedCharacter();
				unsavedProgress = true;
			}
		}
	}

	override function update(elapsed:Float) {
		if (PsychUIInputText.focusOn == null) {
			Controls.toggleVolumeKeys();

			if (FlxG.keys.justPressed.ESCAPE) {
				if (!unsavedProgress) {
					FlxG.switchState(() -> new MasterEditorMenu());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				} else openSubState(new ExitConfirmationPrompt());
			}

			var shiftMult:Int = 1;
			if (FlxG.keys.pressed.SHIFT) shiftMult = 10;
			if (FlxG.keys.justPressed.LEFT) {
				characterFile.offset[0] += shiftMult;
				updateOffset();
			}
			if (FlxG.keys.justPressed.RIGHT) {
				characterFile.offset[0] -= shiftMult;
				updateOffset();
			}
			if (FlxG.keys.justPressed.UP) {
				characterFile.offset[1] += shiftMult;
				updateOffset();
			}
			if (FlxG.keys.justPressed.DOWN) {
				characterFile.offset[1] -= shiftMult;
				updateOffset();
			}

			if (FlxG.keys.justPressed.SPACE && characterTypeRadio.checked == 1) {
				grpWeekCharacters.members[characterTypeRadio.checked].animation.play('confirm', true);
			}
		}

		var char:MenuCharacter = grpWeekCharacters.members[1];
		if (char.animation.curAnim != null && char.animation.curAnim.name == 'confirm' && char.animation.curAnim.finished)
			char.animation.play('idle', true);

		super.update(elapsed);
	}

	function updateOffset() {
		var char:MenuCharacter = grpWeekCharacters.members[characterTypeRadio.checked];
		char.offset.set(characterFile.offset[0], characterFile.offset[1]);
		txtOffsets.text = '' + characterFile.offset;
	}

	var _file:FileReference = null;
	function loadCharacter() {
		_file = new FileReference();
		_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([new openfl.net.FileFilter('JSON', 'json')]);
	}

	function onLoadComplete(_):Void {
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var fullPath:String = null;
		@:privateAccess
		if (_file.__path != null) fullPath = _file.__path;

		if (fullPath != null) {
			var rawJson:String = File.getContent(fullPath);
			if (rawJson != null) {
				var loadedChar:MenuCharacterFile = Json.parse(rawJson);
				if (loadedChar.idle != null && loadedChar.confirm != null) { // Make sure it's really a character
					trace('Successfully loaded file: ${_file.name.substr(0, _file.name.length - 5)}');
					characterFile = loadedChar;
					reloadSelectedCharacter();
					imageInputText.text = characterFile.image;
					idleInputText.text = characterFile.idle;
					confirmInputText.text = characterFile.confirm;
					scaleStepper.value = characterFile.scale;
					updateOffset();
					_file = null;
					return;
				}
			}
		}
		_file = null;
		#else
		Logs.warn("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onLoadCancel(_):Void {
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Cancelled file loading.");
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onLoadError(_):Void {
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		Logs.warn("Problem loading file");
	}

	function saveCharacter() {
		var data:String = states.editors.content.PsychJsonPrinter.print(characterFile, ['offset']);
		if (data.length > 0) {
			var splittedImage:Array<String> = imageInputText.text.trim().split('_');
			var characterName:String = splittedImage[splittedImage.length - 1].toLowerCase().replace(' ', '');

			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, '$characterName.json');
		}
	}

	function onSaveComplete(_):Void {
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void {
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void {
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}
}