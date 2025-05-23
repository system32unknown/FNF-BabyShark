package states.editors;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

import objects.Character;
import objects.HealthIcon;
import objects.Bar;

import states.editors.content.Prompt;

#if (FLX_DEBUG || flixel < version("5.7.0"))
typedef PointerGraphic = flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
#else
@:bitmap("assets/images/debugger/cursorCross.png")
class PointerGraphic extends openfl.display.BitmapData {}
#end

class CharacterEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent {
	var character:Character;
	var ghost:FlxSprite;
	var animateGhost:FlxAnimate;
	var animateGhostImage:String;
	var cameraFollowPointer:FlxSprite;

	var silhouettes:FlxSpriteGroup;
	var dadPosition:FlxPoint = FlxPoint.weak();
	var bfPosition:FlxPoint = FlxPoint.weak();

	var helpBg:FlxSprite;
	var helpTexts:FlxSpriteGroup;
	var cameraZoomText:FlxText;
	var frameAdvanceText:FlxText;

	var healthBar:Bar;
	var healthIcon:HealthIcon;

	var copiedOffset:Array<Float> = [0, 0];
	var _char:String = null;
	var _goToPlayState:Bool = true;

	var anims = null;
	var animsTxt:FlxText;
	var curAnim = 0;

	var camEditor:FlxCamera;
	var camHUD:FlxCamera;

	var UI_box:PsychUIBox;
	var UI_characterbox:PsychUIBox;

	var unsavedProgress:Bool = false;
	var selectedFormat:FlxTextFormat = new FlxTextFormat(FlxColor.LIME);
	public function new(char:String = null, goToPlayState:Bool = true) {
		this._char = char;
		this._goToPlayState = goToPlayState;
		if (this._char == null) this._char = Character.DEFAULT_CHARACTER;

		super();
	}

	override function create() {
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		FlxG.sound.music.stop();
		camEditor = initPsychCamera();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		loadBG();

		add(silhouettes = new FlxSpriteGroup());

		var dad:FlxSprite = new FlxSprite(dadPosition.x, dadPosition.y, Paths.image('editors/silhouetteDad'));
		dad.antialiasing = Settings.data.antialiasing;
		dad.active = false;
		dad.offset.set(-4, 1);
		silhouettes.add(dad);

		var boyfriend:FlxSprite = new FlxSprite(bfPosition.x, bfPosition.y + 350, Paths.image('editors/silhouetteBF'));
		boyfriend.antialiasing = Settings.data.antialiasing;
		boyfriend.active = false;
		boyfriend.offset.set(-6, 2);
		silhouettes.add(boyfriend);

		silhouettes.alpha = 0.25;

		ghost = new FlxSprite();
		ghost.visible = false;
		ghost.alpha = ghostAlpha;
		add(ghost);

		animsTxt = new FlxText(10, 32, 400, '');
		animsTxt.setFormat(null, 16);
		animsTxt.setBorderStyle(OUTLINE_FAST, FlxColor.BLACK);
		animsTxt.scrollFactor.set();
		animsTxt.cameras = [camHUD];

		addCharacter();

		cameraFollowPointer = new FlxSprite(flixel.graphics.FlxGraphic.fromClass(PointerGraphic));
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();

		healthBar = new Bar(30, FlxG.height - 75);
		healthBar.scrollFactor.set();
		healthBar.cameras = [camHUD];

		healthIcon = new HealthIcon(character.healthIcon, false, false);
		healthIcon.y = healthBar.y - (healthIcon.frameHeight / 2);
		healthIcon.cameras = [camHUD];

		add(cameraFollowPointer);
		add(healthBar);
		add(healthIcon);
		add(animsTxt);

		var tipText:FlxText = new FlxText(FlxG.width - 300, FlxG.height - 24, 300, "Press F1 for Help", 16);
		tipText.cameras = [camHUD];
		tipText.setFormat(null, 16, FlxColor.WHITE, RIGHT);
		tipText.setBorderStyle(OUTLINE_FAST, FlxColor.BLACK);
		tipText.scrollFactor.set();
		tipText.active = false;
		add(tipText);

		cameraZoomText = new FlxText(0, 50, 200, 'Zoom: 1x');
		cameraZoomText.setFormat(null, 16, FlxColor.WHITE, CENTER);
		cameraZoomText.setBorderStyle(OUTLINE_FAST, FlxColor.BLACK);
		cameraZoomText.scrollFactor.set();
		cameraZoomText.gameCenter(X);
		cameraZoomText.cameras = [camHUD];
		add(cameraZoomText);

		frameAdvanceText = new FlxText(0, 75, 350, '');
		frameAdvanceText.setFormat(null, 16, FlxColor.WHITE, CENTER);
		frameAdvanceText.setBorderStyle(OUTLINE_FAST, FlxColor.BLACK);
		frameAdvanceText.scrollFactor.set();
		frameAdvanceText.gameCenter(X);
		frameAdvanceText.cameras = [camHUD];
		add(frameAdvanceText);

		addHelpScreen();
		FlxG.mouse.visible = true;
		FlxG.camera.zoom = 1;

		makeUIMenu();

		updatePointerPos();
		updateHealthBar();
		character.finishAnimation();

		if (Settings.data.cacheOnGPU) Paths.clearUnusedMemory();
		super.create();
	}

	function addHelpScreen() {
		var str:Array<String> = [
			"CAMERA",
			"E/Q - Camera Zoom In/Out",
			"J/K/L/I - Move Camera",
			"R - Reset Camera Zoom",
			"",
			"CHARACTER",
			"Ctrl + R - Reset Current Offset",
			"Ctrl + C - Copy Current Offset",
			"Ctrl + V - Paste Copied Offset on Current Animation",
			"Ctrl + Z - Undo Last Paste or Reset",
			"W/S - Previous/Next Animation",
			"Space - Replay Animation",
			"Arrow Keys/Mouse & Right Click - Move Offset",
			"A/D - Frame Advance (Back/Forward)",
			"",
			"OTHER",
			"F12 - Toggle Silhouettes",
			"Hold Shift - Move Offsets 10x faster and Camera 4x faster",
			"Hold Control - Move camera 4x slower"
		];

		helpBg = new FlxSprite().makeSolid(FlxG.width, FlxG.height, FlxColor.BLACK);
		helpBg.alpha = 0.6;
		helpBg.cameras = [camHUD];
		helpBg.active = helpBg.visible = false;
		add(helpBg);

		helpTexts = new FlxSpriteGroup();
		helpTexts.cameras = [camHUD];
		for (i => txt in str) {
			if (txt.length < 1) continue;

			var helpText:FlxText = new FlxText(0, 0, 600, txt, 16);
			helpText.setFormat(null, 16, FlxColor.WHITE, CENTER);
			helpText.setBorderStyle(OUTLINE_FAST, FlxColor.BLACK);
			helpText.scrollFactor.set();
			helpText.gameCenter();
			add(helpText);
			helpText.y += ((i - str.length / 2) * 32) + 16;
			helpText.active = false;
			helpTexts.add(helpText);
		}
		helpTexts.active = helpTexts.visible = false;
		add(helpTexts);
	}

	function addCharacter(reload:Bool = false) {
		var pos:Int = -1;
		if (character != null) {
			pos = members.indexOf(character);
			remove(character);
			character.destroy();
		}

		var isPlayer:Bool = (reload ? character.isPlayer : !predictCharacterIsNotPlayer(_char));
		character = new Character(0, 0, _char, isPlayer);
		if (!reload && character.editorIsPlayer != null && isPlayer != character.editorIsPlayer) {
			character.isPlayer = !character.isPlayer;
			character.flipX = (character.originalFlipX != character.isPlayer);
			if (check_player != null) check_player.checked = character.isPlayer;
		}
		character.debugMode = true;
		character.missingCharacter = false;

		if (pos > -1) insert(pos, character);
		else add(character);
		updateCharacterPositions();
		reloadAnimList();
		if (healthBar != null && healthIcon != null) updateHealthBar();
	}

	function makeUIMenu() {
		UI_box = new PsychUIBox(FlxG.width - 275, 25, 250, 120, ['Ghost', 'Settings']);
		UI_box.scrollFactor.set();
		UI_box.cameras = [camHUD];

		UI_characterbox = new PsychUIBox(UI_box.x - 100, UI_box.y + UI_box.height + 10, 350, 250, ['Animations', 'Character']);
		UI_characterbox.scrollFactor.set();
		UI_characterbox.cameras = [camHUD];
		add(UI_characterbox);
		add(UI_box);

		addGhostUI();
		addSettingsUI();
		addAnimationsUI();
		addCharacterUI();

		UI_box.selectedName = 'Settings';
		UI_characterbox.selectedName = 'Character';
	}

	var ghostAlpha:Float = .6;
	function addGhostUI() {
		var tab_group:FlxSpriteGroup = UI_box.getTab('Ghost').menu;

		var makeGhostButton:PsychUIButton = new PsychUIButton(25, 15, "Make Ghost", () -> {
			if (!character.isAnimationNull()) {
				var myAnim:AnimArray = anims[curAnim];
				if (!character.isAnimateAtlas) {
					ghost.loadGraphic(character.graphic);
					ghost.frames.frames = character.frames.frames;
					ghost.animation.copyFrom(character.animation);
					ghost.animation.play(character.animation.curAnim.name, true, false, character.animation.curAnim.curFrame);
					ghost.animation.pause();
				} else if (myAnim != null) { // This is VERY unoptimized and bad, I hope to find a better replacement that loads only a specific frame as bitmap in the future.
					if (animateGhost == null) { // If I created the animateGhost on create() and you didn't load an atlas, it would crash the game on destroy, so we create it here
						animateGhost = new FlxAnimate(ghost.x, ghost.y);
						animateGhost.showPivot = false;
						insert(members.indexOf(ghost), animateGhost);
						animateGhost.active = false;
					}

					if (animateGhost == null || animateGhostImage != character.imageFile)
						Paths.loadAnimateAtlas(animateGhost, character.imageFile);

					if (myAnim.indices != null && myAnim.indices.length > 0)
						animateGhost.anim.addBySymbolIndices('anim', myAnim.name, myAnim.indices, 0, false);
					else animateGhost.anim.addBySymbol('anim', myAnim.name, 0, false);

					animateGhost.anim.play('anim', true, false, character.atlas.anim.curFrame);
					animateGhost.anim.pause();

					animateGhostImage = character.imageFile;
				}

				var spr:FlxSprite = !character.isAnimateAtlas ? ghost : animateGhost;
				if (spr != null) {
					spr.setPosition(character.x, character.y);
					spr.antialiasing = character.antialiasing;
					spr.flipX = character.flipX;
					spr.alpha = ghostAlpha;

					spr.scale.set(character.scale.x, character.scale.y);
					spr.updateHitbox();

					spr.offset.set(character.offset.x, character.offset.y);
					spr.visible = true;

					var otherSpr:FlxSprite = (spr == animateGhost) ? ghost : animateGhost;
					if (otherSpr != null) otherSpr.visible = false;
				}
			}
		});

		var highlightGhost:PsychUICheckBox = new PsychUICheckBox(20 + makeGhostButton.x + makeGhostButton.width, makeGhostButton.y, "Highlight Ghost");
		highlightGhost.onClick = () -> {
			var value:Int = highlightGhost.checked ? 125 : 0;
			ghost.colorTransform.redOffset = value;
			ghost.colorTransform.greenOffset = value;
			ghost.colorTransform.blueOffset = value;
			if (animateGhost != null) {
				animateGhost.colorTransform.redOffset = value;
				animateGhost.colorTransform.greenOffset = value;
				animateGhost.colorTransform.blueOffset = value;
			}
		};

		var ghostAlphaSlider:PsychUISlider = new PsychUISlider(10, makeGhostButton.y + 25, (v:Float) -> {
			ghostAlpha = v;
			ghost.alpha = ghostAlpha;
			if (animateGhost != null) animateGhost.alpha = ghostAlpha;
		}, ghostAlpha, 0, 1);
		ghostAlphaSlider.label = 'Opacity:';

		tab_group.add(makeGhostButton);
		tab_group.add(highlightGhost);
		tab_group.add(ghostAlphaSlider);
	}

	var check_player:PsychUICheckBox;
	var charDropDown:PsychUIDropDownMenu;
	function addSettingsUI() {
		var tab_group:FlxSpriteGroup = UI_box.getTab('Settings').menu;

		check_player = new PsychUICheckBox(10, 60, "Playable Character");
		check_player.checked = character.isPlayer;
		check_player.onClick = () -> {
			character.isPlayer = !character.isPlayer;
			character.flipX = !character.flipX;
			updateCharacterPositions();
			updatePointerPos(false);
		};

		var reloadCharacter:PsychUIButton = new PsychUIButton(140, 20, "Reload Char", () -> {
			addCharacter(true);
			updatePointerPos();
			reloadCharacterOptions();
			reloadCharacterDropDown();
		});

		var templateCharacter:PsychUIButton = new PsychUIButton(140, 50, "Load Template", () -> {
			character.loadCharacterFile({
				animations: [
					newAnim('idle', 'BF idle dance'),
					newAnim('singLEFT', 'BF NOTE LEFT0'),
					newAnim('singDOWN', 'BF NOTE DOWN0'),
					newAnim('singUP', 'BF NOTE UP0'),
					newAnim('singRIGHT', 'BF NOTE RIGHT0')
				],
				no_antialiasing: false,
				flip_x: false,
				healthicon: 'face',
				image: 'characters/BOYFRIEND',
				sing_duration: 4,
				scale: 1,
				healthbar_colors: [161, 161, 161],
				camera_position: [0, 0],
				position: [0, 0]
			});
			character.missingCharacter = false;
			character.color = FlxColor.WHITE;
			character.alpha = 1;
			reloadAnimList();
			reloadCharacterOptions();
			updateCharacterPositions();
			updatePointerPos();
			reloadCharacterDropDown();
			updateHealthBar();
		});
		templateCharacter.normalStyle.bgColor = FlxColor.RED;
		templateCharacter.normalStyle.textColor = FlxColor.WHITE;

		charDropDown = new PsychUIDropDownMenu(10, 30, [''], function(index:Int, intended:String) {
			if (intended == null || intended.length < 1) return;

			if (Paths.exists(Paths.getPath('characters/$intended.json'))) {
				_char = intended;
				check_player.checked = character.isPlayer;
				addCharacter();
				reloadCharacterOptions();
				reloadCharacterDropDown();
				updatePointerPos();
			} else {
				reloadCharacterDropDown();
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		});
		reloadCharacterDropDown();
		charDropDown.selectedLabel = _char;

		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 80, 'Character:'));
		tab_group.add(check_player);
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		tab_group.add(charDropDown);
	}

	var animationDropDown:PsychUIDropDownMenu;
	var animationInputText:PsychUIInputText;
	var animationNameInputText:PsychUIInputText;
	var animationIndicesInputText:PsychUIInputText;
	var animationFramerate:PsychUINumericStepper;
	var animationLoopCheckBox:PsychUICheckBox;
	function addAnimationsUI() {
		var tab_group:FlxSpriteGroup = UI_characterbox.getTab('Animations').menu;

		animationInputText = new PsychUIInputText(15, 85, 80);
		animationNameInputText = new PsychUIInputText(animationInputText.x, animationInputText.y + 35, 150);
		animationIndicesInputText = new PsychUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250);
		animationFramerate = new PsychUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240);
		animationLoopCheckBox = new PsychUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, "Should it Loop?");

		animationDropDown = new PsychUIDropDownMenu(15, animationInputText.y - 55, [''], function(selectedAnimation:Int, pressed:String) {
			var anim:AnimArray = character.animationsArray[selectedAnimation];
			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationFramerate.value = anim.fps;

			var indicesStr:String = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		});

		var addUpdateButton:PsychUIButton = new PsychUIButton(70, animationIndicesInputText.y + 30, "Add/Update", () -> {
			var indicesText:String = animationIndicesInputText.text.trim();
			var indices:Array<Int> = [];
			if (indicesText.length > 0) {
				var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
				if (indicesStr.length > 0) {
					for (ind in indicesStr) {
						if (ind.contains('-')) {
							var splitIndices:Array<String> = ind.split('-');
							var indexStart:Int = Std.parseInt(splitIndices[0]);
							if (Math.isNaN(indexStart) || indexStart < 0) indexStart = 0;

							var indexEnd:Int = Std.parseInt(splitIndices[1]);
							if (Math.isNaN(indexEnd) || indexEnd < indexStart) indexEnd = indexStart;

							for (index in indexStart...indexEnd + 1) indices.push(index);
						} else {
							var index:Int = Std.parseInt(ind);
							if (!Math.isNaN(index) && index > -1) indices.push(index);
						}
					}
				}
			}
			var lastAnim:String = (character.animationsArray[curAnim] != null) ? character.animationsArray[curAnim].anim : '';
			var lastOffsets:Array<Int> = [0, 0];
			for (anim in character.animationsArray)
				if (animationInputText.text == anim.anim) {
					lastOffsets = anim.offsets;
					if (character.hasAnimation(animationInputText.text)) {
						if (!character.isAnimateAtlas) character.animation.remove(animationInputText.text);
						else @:privateAccess character.atlas.anim.animsMap.remove(animationInputText.text);
					}
					character.animationsArray.remove(anim);
				}
			var addedAnim:AnimArray = newAnim(animationInputText.text, animationNameInputText.text);
			addedAnim.fps = Math.round(animationFramerate.value);
			addedAnim.loop = animationLoopCheckBox.checked;
			addedAnim.indices = indices;
			addedAnim.offsets = lastOffsets;
			addAnimation(addedAnim.anim, addedAnim.name, addedAnim.fps, addedAnim.loop, addedAnim.indices);
			character.animationsArray.push(addedAnim);
			reloadAnimList();
			@:arrayAccess curAnim = Std.int(Math.max(0, character.animationsArray.indexOf(addedAnim)));
			character.playAnim(addedAnim.anim, true);
			trace('Added/Updated animation: ' + animationInputText.text);
		});

		var removeButton:PsychUIButton = new PsychUIButton(180, animationIndicesInputText.y + 30, "Remove", () -> {
			for (anim in character.animationsArray)
				if (animationInputText.text == anim.anim) {
					var resetAnim:Bool = false;
					if (anim.anim == character.getAnimationName()) resetAnim = true;
					if (character.hasAnimation(anim.anim)) {
						if (!character.isAnimateAtlas) character.animation.remove(anim.anim);
						else @:privateAccess character.atlas.anim.animsMap.remove(anim.anim);
						character.animOffsets.remove(anim.anim);
						character.animationsArray.remove(anim);
					}

					if (resetAnim && character.animationsArray.length > 0) {
						curAnim = FlxMath.wrap(curAnim, 0, anims.length - 1);
						character.playAnim(anims[curAnim].anim, true);
					}
					reloadAnimList();
					trace('Removed animation: ' + animationInputText.text);
					break;
				}
		});
		reloadAnimList();
		animationDropDown.selectedLabel = anims[0] != null ? anims[0].anim : '';

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 100, 'Animations:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 100, 'Animation name:'));
		tab_group.add(new FlxText(animationFramerate.x, animationFramerate.y - 18, 100, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 150, 'Animation Symbol Name/Tag:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 170, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(animationDropDown);
	}

	var imageInputText:PsychUIInputText;
	var healthIconInputText:PsychUIInputText;

	var singDurationStepper:PsychUINumericStepper;
	var scaleStepper:PsychUINumericStepper;
	var positionXStepper:PsychUINumericStepper;
	var positionYStepper:PsychUINumericStepper;
	var positionCameraXStepper:PsychUINumericStepper;
	var positionCameraYStepper:PsychUINumericStepper;

	var flipXCheckBox:PsychUICheckBox;
	var noAntialiasingCheckBox:PsychUICheckBox;

	var healthColorStepperR:PsychUINumericStepper;
	var healthColorStepperG:PsychUINumericStepper;
	var healthColorStepperB:PsychUINumericStepper;
	function addCharacterUI() {
		var tab_group:FlxSpriteGroup = UI_characterbox.getTab('Character').menu;

		imageInputText = new PsychUIInputText(15, 30, 200, character.imageFile);
		var reloadImage:PsychUIButton = new PsychUIButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", () -> {
			var lastAnim = character.getAnimationName();
			character.imageFile = imageInputText.text;
			reloadCharacterImage();
			if (!character.isAnimationNull()) character.playAnim(lastAnim, true);
		});

		var decideIconColor:PsychUIButton = new PsychUIButton(reloadImage.x, reloadImage.y + 30, "Get Icon Color", () -> {
			var coolColor:FlxColor = SpriteUtil.dominantColor(healthIcon);
			character.healthColorArray[0] = coolColor.red;
			character.healthColorArray[1] = coolColor.green;
			character.healthColorArray[2] = coolColor.blue;
			updateHealthBar();
		});

		healthIconInputText = new PsychUIInputText(15, imageInputText.y + 35, 75, healthIcon.getCharacter());

		singDurationStepper = new PsychUINumericStepper(15, healthIconInputText.y + 45, 0.1, 4, 0, 999, 1);
		scaleStepper = new PsychUINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 10, 2);

		flipXCheckBox = new PsychUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, "Flip X", 50);
		flipXCheckBox.checked = character.flipX;
		if (character.isPlayer) flipXCheckBox.checked = !flipXCheckBox.checked;
		flipXCheckBox.onClick = () -> {
			character.originalFlipX = !character.originalFlipX;
			character.flipX = (character.originalFlipX != character.isPlayer);
		};

		noAntialiasingCheckBox = new PsychUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, "No Antialiasing", 80);
		noAntialiasingCheckBox.checked = character.noAntialiasing;
		noAntialiasingCheckBox.onClick = () -> {
			character.antialiasing = false;
			if (!noAntialiasingCheckBox.checked && Settings.data.antialiasing)
				character.antialiasing = true;
			character.noAntialiasing = noAntialiasingCheckBox.checked;
		};

		positionXStepper = new PsychUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, character.positionArray[0], -9000, 9000);
		positionYStepper = new PsychUINumericStepper(positionXStepper.x + 70, positionXStepper.y, 10, character.positionArray[1], -9000, 9000);

		positionCameraXStepper = new PsychUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, character.cameraPosition[0], -9000, 9000);
		positionCameraYStepper = new PsychUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, character.cameraPosition[1], -9000, 9000);

		var saveCharacterButton:PsychUIButton = new PsychUIButton(reloadImage.x, noAntialiasingCheckBox.y + 40, "Save Character", () -> saveCharacter());

		healthColorStepperR = new PsychUINumericStepper(singDurationStepper.x, saveCharacterButton.y, 20, character.healthColorArray[0], 0, 255);
		healthColorStepperG = new PsychUINumericStepper(singDurationStepper.x + 65, saveCharacterButton.y, 20, character.healthColorArray[1], 0, 255);
		healthColorStepperB = new PsychUINumericStepper(singDurationStepper.x + 130, saveCharacterButton.y, 20, character.healthColorArray[2], 0, 255);

		tab_group.add(new FlxText(15, imageInputText.y - 18, 100, 'Image file name:'));
		tab_group.add(new FlxText(15, healthIconInputText.y - 18, 100, 'Health icon name:'));
		tab_group.add(new FlxText(15, singDurationStepper.y - 18, 120, 'Sing Animation length:'));
		tab_group.add(new FlxText(15, scaleStepper.y - 18, 100, 'Scale:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 100, 'Character X/Y:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 100, 'Camera X/Y:'));
		tab_group.add(new FlxText(healthColorStepperR.x, healthColorStepperR.y - 18, 100, 'Health bar R/G/B:'));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		tab_group.add(decideIconColor);
		tab_group.add(healthIconInputText);
		tab_group.add(singDurationStepper);
		tab_group.add(scaleStepper);
		tab_group.add(flipXCheckBox);
		tab_group.add(noAntialiasingCheckBox);
		tab_group.add(positionXStepper);
		tab_group.add(positionYStepper);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		tab_group.add(healthColorStepperR);
		tab_group.add(healthColorStepperG);
		tab_group.add(healthColorStepperB);
		tab_group.add(saveCharacterButton);
	}

	public function UIEvent(id:String, sender:Dynamic) {
		if (id == PsychUICheckBox.CLICK_EVENT) unsavedProgress = true;

		if (id == PsychUIInputText.CHANGE_EVENT) {
			if (sender == healthIconInputText) {
				var lastIcon:String = healthIcon.getCharacter();
				healthIcon.changeIcon(healthIconInputText.text, false);
				character.healthIcon = healthIconInputText.text;
				if (lastIcon != healthIcon.getCharacter()) updatePresence();
				unsavedProgress = true;
			} else if (sender == imageInputText) {
				character.imageFile = imageInputText.text;
				unsavedProgress = true;
			}
		} else if (id == PsychUINumericStepper.CHANGE_EVENT) {
			if (sender == scaleStepper) {
				reloadCharacterImage();
				character.jsonScale = sender.value;
				character.scale.set(character.jsonScale, character.jsonScale);
				character.updateHitbox();
				updatePointerPos(false);
				unsavedProgress = true;
			} else if (sender == positionXStepper) {
				character.positionArray[0] = positionXStepper.value;
				updateCharacterPositions();
				unsavedProgress = true;
			} else if (sender == positionYStepper) {
				character.positionArray[1] = positionYStepper.value;
				updateCharacterPositions();
				unsavedProgress = true;
			} else if (sender == singDurationStepper) {
				character.singDuration = singDurationStepper.value;
				unsavedProgress = true;
			} else if (sender == positionCameraXStepper) {
				character.cameraPosition[0] = positionCameraXStepper.value;
				updatePointerPos();
				unsavedProgress = true;
			} else if (sender == positionCameraYStepper) {
				character.cameraPosition[1] = positionCameraYStepper.value;
				updatePointerPos();
				unsavedProgress = true;
			} else if (sender == healthColorStepperR) {
				character.healthColorArray[0] = Math.round(healthColorStepperR.value);
				updateHealthBar();
				unsavedProgress = true;
			} else if (sender == healthColorStepperG) {
				character.healthColorArray[1] = Math.round(healthColorStepperG.value);
				updateHealthBar();
				unsavedProgress = true;
			} else if (sender == healthColorStepperB) {
				character.healthColorArray[2] = Math.round(healthColorStepperB.value);
				updateHealthBar();
				unsavedProgress = true;
			}
		}
	}

	function reloadCharacterImage() {
		var lastAnim:String = character.getAnimationName();
		var anims:Array<AnimArray> = character.animationsArray.copy();

		character.atlas = flixel.util.FlxDestroyUtil.destroy(character.atlas);
		character.isAnimateAtlas = false;
		character.color = FlxColor.WHITE;
		character.alpha = 1;

		if (Paths.fileExists('images/${character.imageFile}/Animation.json')) {
			character.atlas = new FlxAnimate();
			character.atlas.showPivot = false;
			try {
				Paths.loadAnimateAtlas(character.atlas, character.imageFile);
			} catch (e:Dynamic) FlxG.log.warn('Could not load atlas ${character.imageFile}: $e');
			character.isAnimateAtlas = true;
		} else character.frames = Paths.getMultiAtlas(character.imageFile.split(','));

		for (anim in anims) {
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; // Bruh
			var animIndices:Array<Int> = anim.indices;
			addAnimation(animAnim, animName, animFps, animLoop, animIndices);
		}

		if (anims.length > 0) {
			if (lastAnim != '') character.playAnim(lastAnim, true);
			else character.dance();
		}
	}

	function reloadCharacterOptions() {
		if (UI_characterbox == null) return;

		check_player.checked = character.isPlayer;
		imageInputText.text = character.imageFile;
		healthIconInputText.text = character.healthIcon;
		singDurationStepper.value = character.singDuration;
		scaleStepper.value = character.jsonScale;
		flipXCheckBox.checked = character.originalFlipX;
		noAntialiasingCheckBox.checked = character.noAntialiasing;
		positionXStepper.value = character.positionArray[0];
		positionYStepper.value = character.positionArray[1];
		positionCameraXStepper.value = character.cameraPosition[0];
		positionCameraYStepper.value = character.cameraPosition[1];
		reloadAnimationDropDown();
		updateHealthBar();
	}

	var holdingArrowsTime:Float = 0;
	var holdingArrowsElapsed:Float = 0;
	var holdingFrameTime:Float = 0;
	var holdingFrameElapsed:Float = 0;
	var undoOffsets:Array<Float> = null;
	override function update(elapsed:Float) {
		super.update(elapsed);

		if (PsychUIInputText.focusOn != null) {
			Controls.toggleVolumeKeys(false);
			return;
		}
		Controls.toggleVolumeKeys();

		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		var shiftMultBig:Float = 1;
		if (FlxG.keys.pressed.SHIFT) {
			shiftMult = 4;
			shiftMultBig = 10;
		}
		if (FlxG.keys.pressed.CONTROL) ctrlMult = 0.25;

		// CAMERA CONTROLS
		if (FlxG.keys.pressed.J) FlxG.camera.scroll.x -= elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.K) FlxG.camera.scroll.y += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.L) FlxG.camera.scroll.x += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.I) FlxG.camera.scroll.y -= elapsed * 500 * shiftMult * ctrlMult;

		var lastZoom:Float = FlxG.camera.zoom;
		if (FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL) FlxG.camera.zoom = 1;
		else if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
			FlxG.camera.zoom += elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if (FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
		} else if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
			FlxG.camera.zoom -= elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if (FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
		}

		if (lastZoom != FlxG.camera.zoom) cameraZoomText.text = 'Zoom: ' + FlxMath.roundDecimal(FlxG.camera.zoom, 2) + 'x';

		// CHARACTER CONTROLS
		var changedAnim:Bool = false;
		if (anims.length > 1) {
			if (FlxG.keys.justPressed.W && (changedAnim = true)) curAnim--;
			else if (FlxG.keys.justPressed.S && (changedAnim = true)) curAnim++;

			if (changedAnim) {
				undoOffsets = null;
				curAnim = FlxMath.wrap(curAnim, 0, anims.length - 1);
				character.playAnim(anims[curAnim].anim, true);
				updateText();
			}
		}

		var changedOffset:Bool = false;
		var moveKeysP:Array<Bool> = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
		var moveKeys:Array<Bool> = [FlxG.keys.pressed.LEFT, FlxG.keys.pressed.RIGHT, FlxG.keys.pressed.UP, FlxG.keys.pressed.DOWN];
		if (moveKeysP.contains(true)) {
			character.offset.add(((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig, ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig);
			changedOffset = true;
		}

		if (moveKeys.contains(true)) {
			holdingArrowsTime += elapsed;
			if (holdingArrowsTime > .6) {
				holdingArrowsElapsed += elapsed;
				while (holdingArrowsElapsed > (1 / 60)) {
					character.offset.add(((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * shiftMultBig, ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * shiftMultBig);
					holdingArrowsElapsed -= (1 / 60);
					changedOffset = true;
				}
			}
		} else holdingArrowsTime = 0;

		if (FlxG.mouse.pressedRight && (FlxG.mouse.deltaViewX != 0 || FlxG.mouse.deltaViewY != 0)) {
			character.offset.subtract(FlxG.mouse.deltaViewX, FlxG.mouse.deltaViewY);
			changedOffset = true;
		}

		if (FlxG.keys.pressed.CONTROL) {
			if (FlxG.keys.justPressed.C) {
				copiedOffset[0] = character.offset.x;
				copiedOffset[1] = character.offset.y;
				changedOffset = true;
			} else if (FlxG.keys.justPressed.V) {
				undoOffsets = [character.offset.x, character.offset.y];
				character.offset.set(copiedOffset[0], copiedOffset[1]);
				changedOffset = true;
			} else if (FlxG.keys.justPressed.R) {
				undoOffsets = [character.offset.x, character.offset.y];
				character.offset.set();
				changedOffset = true;
			} else if (FlxG.keys.justPressed.Z && undoOffsets != null) {
				character.offset.set(undoOffsets[0], undoOffsets[1]);
				changedOffset = true;
			}
		}

		var anim:AnimArray = anims[curAnim];
		if (changedOffset && anim != null && anim.offsets != null) {
			anim.offsets[0] = Std.int(character.offset.x);
			anim.offsets[1] = Std.int(character.offset.y);

			character.addOffset(anim.anim, character.offset.x, character.offset.y);
			updateText();
		}

		var txt:String = 'ERROR: No Animation Found';
		var clr:FlxColor = FlxColor.RED;
		if (!character.isAnimationNull()) {
			if (FlxG.keys.pressed.A || FlxG.keys.pressed.D) {
				holdingFrameTime += elapsed;
				if (holdingFrameTime > 0.5) holdingFrameElapsed += elapsed;
			} else holdingFrameTime = 0;

			if (FlxG.keys.justPressed.SPACE)
				character.playAnim(character.getAnimationName(), true);

			var frames:Int = -1;
			var length:Int = -1;
			if (!character.isAnimateAtlas && character.animation.curAnim != null) {
				frames = character.animation.curAnim.curFrame;
				length = character.animation.curAnim.numFrames;
			} else if (character.isAnimateAtlas && character.atlas.anim != null) {
				frames = character.atlas.anim.curFrame;
				length = character.atlas.anim.length;
			}

			if (length >= 0) {
				if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.D || holdingFrameTime > .5) {
					var isLeft = false;
					if ((holdingFrameTime > .5 && FlxG.keys.pressed.A) || FlxG.keys.justPressed.A) isLeft = true;
					character.animPaused = true;

					if (holdingFrameTime <= .5 || holdingFrameElapsed > .1) {
						frames = FlxMath.wrap(frames + Std.int(isLeft ? -shiftMult : shiftMult), 0, length - 1);
						if (!character.isAnimateAtlas) character.animation.curAnim.curFrame = frames;
						else character.atlas.anim.curFrame = frames;
						holdingFrameElapsed -= .1;
					}
				}

				txt = 'Frames: ( $frames / ${length - 1} )';
				clr = FlxColor.WHITE;
			}
		}
		if (txt != frameAdvanceText.text) frameAdvanceText.text = txt;
		frameAdvanceText.color = clr;

		// OTHER CONTROLS
		if (FlxG.keys.justPressed.F12)
			silhouettes.visible = !silhouettes.visible;

		if (FlxG.keys.justPressed.F1 || (helpBg.visible && FlxG.keys.justPressed.ESCAPE)) {
			helpBg.visible = !helpBg.visible;
			helpTexts.visible = helpBg.visible;
		} else if (FlxG.keys.justPressed.ESCAPE) {
			if (!_goToPlayState) {
				if (!unsavedProgress) {
					FlxG.switchState(() -> new MasterEditorMenu());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				} else openSubState(new ExitConfirmationPrompt());
			} else {
				FlxG.mouse.visible = false;
				FlxG.switchState(() -> new PlayState());
			}
			return;
		}
	}

	inline function loadBG() {
		camEditor.bgColor = 0xFF666666;
		dadPosition.set(100, 100);
		bfPosition.set(770, 100);
	}

	inline function updatePointerPos(?snap:Bool = true) {
		if (character == null || cameraFollowPointer == null) return;

		var offX:Float = 0;
		var offY:Float = 0;
		final mid:FlxPoint = character.getMidpoint();
		if (!character.isPlayer) {
			offX = mid.x + 150 + character.cameraPosition[0];
			offY = mid.y - 100 + character.cameraPosition[1];
		} else {
			offX = mid.x - 100 - character.cameraPosition[0];
			offY = mid.y - 100 + character.cameraPosition[1];
		}
		cameraFollowPointer.setPosition(offX, offY);

		if (snap) {
			final midcam:FlxPoint = cameraFollowPointer.getMidpoint();
			FlxG.camera.scroll.set(midcam.x - FlxG.width / 2, midcam.y - FlxG.height / 2);
			midcam.put();
		}
		mid.put();
	}

	inline function updateHealthBar() {
		healthColorStepperR.value = character.healthColorArray[0];
		healthColorStepperG.value = character.healthColorArray[1];
		healthColorStepperB.value = character.healthColorArray[2];
		healthBar.leftBar.color = healthBar.rightBar.color = FlxColor.fromRGB(character.healthColorArray[0], character.healthColorArray[1], character.healthColorArray[2]);
		healthIcon.changeIcon(character.healthIcon, false);
		updatePresence();
	}

	inline function updatePresence() {
		#if DISCORD_ALLOWED DiscordClient.changePresence("Character Editor", 'Character: $_char'); #end
	}

	inline function reloadAnimList() {
		anims = character.animationsArray;
		if (anims.length > 0) character.playAnim(anims[0].anim, true);
		curAnim = 0;

		updateText();
		if (animationDropDown != null) reloadAnimationDropDown();
	}

	inline function updateText() {
		animsTxt.removeFormat(selectedFormat);

		var intendText:String = '';
		for (num => anim in anims) {
			if (num > 0) intendText += '\n';

			if (num == curAnim) {
				var n:Int = intendText.length;
				intendText += anim.anim + ": " + anim.offsets;
				animsTxt.addFormat(selectedFormat, n, intendText.length);
			} else intendText += anim.anim + ": " + anim.offsets;
		}
		animsTxt.text = intendText;
	}

	inline function updateCharacterPositions() {
		if ((character != null && !character.isPlayer) || (character == null && predictCharacterIsNotPlayer(_char))) character.setPosition(dadPosition.x, dadPosition.y);
		else character.setPosition(bfPosition.x, bfPosition.y);

		character.x += character.positionArray[0];
		character.y += character.positionArray[1];
		updatePointerPos(false);
	}

	inline function predictCharacterIsNotPlayer(name:String):Bool {
		return (name != 'bf' && !name.startsWith('bf-') && !name.endsWith('-player') && !name.endsWith('-playable') && !name.endsWith('-dead')) || name.endsWith('-opponent') || name.startsWith('gf-') || name.endsWith('-gf') || name == 'gf';
	}

	function addAnimation(anim:String, name:String, fps:Float, loop:Bool, indices:Array<Int>) {
		if (!character.isAnimateAtlas) {
			if (indices != null && indices.length > 0)
				character.animation.addByIndices(anim, name, indices, "", fps, loop);
			else character.animation.addByPrefix(anim, name, fps, loop);
		} else {
			if (indices != null && indices.length > 0)
				character.atlas.anim.addBySymbolIndices(anim, name, indices, fps, loop);
			else character.atlas.anim.addBySymbol(anim, name, fps, loop);
		}

		if (!character.hasAnimation(anim)) character.addOffset(anim);
	}

	inline function newAnim(anim:String, name:String):AnimArray {
		return {
			offsets: [0, 0],
			loop: false,
			fps: 24,
			anim: anim,
			indices: [],
			name: name
		};
	}

	var characterList:Array<String> = [];
	function reloadCharacterDropDown() {
		characterList = Mods.mergeAllTextsNamed('data/characterList.txt');
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'characters/'))
			for (file in FileSystem.readDirectory(folder))
				if (file.toLowerCase().endsWith('.json')) {
					var charToCheck:String = file.substr(0, file.length - 5);
					if (!characterList.contains(charToCheck)) characterList.push(charToCheck);
				}

		if (characterList.length < 1) characterList.push('');
		charDropDown.list = characterList;
		charDropDown.selectedLabel = _char;
	}

	function reloadAnimationDropDown() {
		var animList:Array<String> = [];
		for (anim in anims) animList.push(anim.anim);
		if (animList.length < 1) animList.push('NO ANIMATIONS'); // Prevents crash
		animationDropDown.list = animList;
	}

	// save
	var _file:FileReference;
	function onSaveComplete(_):Void {
		if (_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void {
		if (_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void {
		if (_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function saveCharacter() {
		if (_file != null) return;

		var data:String = states.editors.content.PsychJsonPrinter.print({
			"animations": character.animationsArray,
			"image": character.imageFile,
			"scale": character.jsonScale,
			"sing_duration": character.singDuration,
			"healthicon": character.healthIcon,

			"position": character.positionArray,
			"camera_position": character.cameraPosition,

			"flip_x": character.originalFlipX,
			"no_antialiasing": character.noAntialiasing,
			"healthbar_colors": character.healthColorArray,
			"_editor_isPlayer": character.isPlayer
		}, ['offsets', 'position', 'healthbar_colors', 'camera_position', 'indices']);

		if (data.length > 0) {
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, '$_char.json');
		}
	}
}