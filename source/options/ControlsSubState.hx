package options;

import backend.InputFormatter;
import objects.AttachedSprite;

import flixel.input.keyboard.FlxKey;

class ControlsSubState extends FlxSubState {
	var curSelected:Int = 0;
	var curAlt:Bool = false;

	// Show on gamepad - Display name - Save file key - Rebind display name
	var curNoteKeys:Int = 4;
	var options:Array<Dynamic> = [
		[true, 'NOTES'],
		[true, '4 KEY'],
		[true, 'Note', 'note_1', '1 Key Note', 1],
		[true, 'Left', 'note_left', '2 Key Note Left', 2],
		[true, 'Right', 'note_right', '2 Key Note Right', 2],
		[true, 'Left', 'note_left', '3 Key Note Left', 3],
		[true, 'Center', 'note_3a', '3 Key Note Center', 3],
		[true, 'Right', 'note_right', '3 Key Note Right', 3],
		[true, 'Left', 'note_left', '4 Key Note Left', 4],
		[true, 'Down', 'note_down', '4 Key Note Down', 4],
		[true, 'Up', 'note_up', '4 Key Note Up', 4],
		[true, 'Right', 'note_right', '4 Key Note Right', 4],
		[true, 'Left', 'note_left', '5 Key Note Left', 5],
		[true, 'Down', 'note_down', '5 Key Note Down', 5],
		[true, 'Center', 'note_5a', '5 Key Note Center', 5],
		[true, 'Up', 'note_up', '5 Key Note Up', 5],
		[true, 'Right', 'note_right', '5 Key Note Right', 5],
		[true, 'Left 1', 'note_6a', '6 Key Note Left 1', 6],
		[true, 'Up', 'note_6b', '6 Key Note Up', 6],
		[true, 'Right 1', 'note_6c', '6 Key Note Right 1', 6],
		[true, 'Left 2', 'note_6d', '6 Key Note Left 2', 6],
		[true, 'Down', 'note_6e', '6 Key Note Down', 6],
		[true, 'Right 1', 'note_6f', '6 Key Note Right 2', 6],
		[true, 'Left 1', 'note_7a', '7 Key Note Left 1', 7],
		[true, 'Up', 'note_7b', '7 Key Note Up', 7],
		[true, 'Right 1', 'note_7c', '7 Key Note Right 1', 7],
		[true, 'Center', 'note_7d', '7 Key Note Center', 7],
		[true, 'Left 2', 'note_7e', '7 Key Note Left 2', 7],
		[true, 'Down', 'note_7f', '7 Key Note Down', 7],
		[true, 'Right 2', 'note_7g', '7 Key Note Right 2', 7],
		[true, 'Left 1', 'note_8a', '8 Key Note Left 1', 8],
		[true, 'Down 1', 'note_8b', '8 Key Note Down 1', 8],
		[true, 'Up 1', 'note_8c', '8 Key Note Up 1', 8],
		[true, 'Right 1', 'note_8d', '8 Key Note Right 1', 8],
		[true, 'Left 2', 'note_8e', '8 Key Note Left 2', 8],
		[true, 'Down 2', 'note_8f', '8 Key Note Down 2', 8],
		[true, 'Up 2', 'note_8g', '8 Key Note Up 2', 8],
		[true, 'Right 2', 'note_8h', '8 Key Note Right 2', 8],
		[true, 'Left 1', 'note_9a', '9 Key Note Left 1', 9],
		[true, 'Down 1', 'note_9b', '9 Key Note Down 1', 9],
		[true, 'Up 1', 'note_9c', '9 Key Note Up 1', 9],
		[true, 'Right 1', 'note_9d', '9 Key Note Right 1', 9],
		[true, 'Center', 'note_9e', '9 Key Note Center', 9],
		[true, 'Left 2', 'note_9f', '9 Key Note Left 2', 9],
		[true, 'Down 2', 'note_9g', '9 Key Note Down 2', 9],
		[true, 'Up 2', 'note_9h', '9 Key Note Up 2', 9],
		[true, 'Right 2', 'note_9i', '9 Key Note Right 2', 9],
		[true],
		[true, 'UI'],
		[true, 'Left', 'ui_left', 'UI Left'],
		[true, 'Down', 'ui_down', 'UI Down'],
		[true, 'Up', 'ui_up', 'UI Up'],
		[true, 'Right', 'ui_right', 'UI Right'],
		[true],
		[true, 'Reset', 'reset', 'Reset'],
		[true, 'Accept', 'accept', 'Accept'],
		[true, 'Back', 'back', 'Back'],
		[true, 'Pause', 'pause', 'Pause'],
		[false],
		[false, 'VOLUME'],
		[false, 'Mute', 'volume_mute', 'Volume Mute'],
		[false, 'Up', 'volume_up', 'Volume Up'],
		[false, 'Down', 'volume_down', 'Volume Down'],
		[false],
		[false, 'DEBUG'],
		[false, 'Key 1', 'debug_1', 'Debug Key #1'],
		[false, 'Key 2', 'debug_2', 'Debug Key #2']
	];
	var curOptions:Array<Int>;
	var curOptionsValid:Array<Int>;
	static var defaultKey:String = 'Reset to Default Keys';

	var grpDisplay:FlxTypedGroup<Alphabet>;
	var grpBlacks:FlxTypedGroup<AttachedSprite>;
	var grpOptions:FlxTypedGroup<Alphabet>;
	var grpBinds:FlxTypedGroup<Alphabet>;
	var selectSpr:AttachedSprite;

	public function new() {
		super();

		#if DISCORD_ALLOWED DiscordClient.changePresence("Controls Menu"); #end

		options.push([true]);
		options.push([true]);
		options.push([true, defaultKey]);

		var bg:FlxSprite = new FlxSprite(Paths.image('menuDesat'));
		bg.color = 0xff7192fd;
		bg.antialiasing = Settings.data.antialiasing;
		bg.gameCenter();
		add(bg);

		var grid:flixel.addons.display.FlxBackdrop = Util.createBackDrop(80, 80, 160, 160, true, 0x33FFFFFF, 0x0);
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, .5, {ease: FlxEase.quadOut});
		add(grid);

		add(grpDisplay = new FlxTypedGroup<Alphabet>());
		add(grpOptions = new FlxTypedGroup<Alphabet>());
		add(grpBlacks = new FlxTypedGroup<AttachedSprite>());
		selectSpr = new AttachedSprite();
		selectSpr.makeGraphic(1, 1, FlxColor.WHITE);
		selectSpr.copyAlpha = false;
		selectSpr.alpha = 0.75;
		add(selectSpr);
		add(grpBinds = new FlxTypedGroup<Alphabet>());

		var text:Alphabet = new Alphabet(50, 600, 'SHIFT + < or > to\nChange Key Number');
		text.updateScale(.4, .4);
		add(text);

		createTexts();
	}

	var lastID:Int = 0;
	function createTexts() {
		curOptions = [];
		curOptionsValid = [];
		grpDisplay.forEachAlive((text:Alphabet) -> text.destroy());
		grpBlacks.forEachAlive((black:AttachedSprite) -> black.destroy());
		grpOptions.forEachAlive((text:Alphabet) -> text.destroy());
		grpBinds.forEachAlive((text:Alphabet) -> text.destroy());
		grpDisplay.clear();
		grpBlacks.clear();
		grpOptions.clear();
		grpBinds.clear();

		var myID:Int = 0;
		for (i => option in options) {
			if (option[0] && (option.length > 4 && option[4] == curNoteKeys || option.length <= 4)) {
				if (option.length > 1) {
					var isCentered:Bool = (option.length < 3);
					var isDefaultKey:Bool = (option[1] == defaultKey);
					var isDisplayKey:Bool = (isCentered && !isDefaultKey);

					var str:String = option[1];
					var keyStr:String = option[2];
					if (isDefaultKey) str = Language.getPhrase(str);
					var text:Alphabet = new Alphabet(475, 300, !isDisplayKey ? Language.getPhrase('key_$keyStr', str) : Language.getPhrase('keygroup_$str', str), isDisplayKey ? NORMAL : BOLD);
					text.isMenuItem = true;
					text.changeX = false;
					text.distancePerItem.y = 60;
					text.targetY = myID;
					if (text.text.endsWith('KEY')) text.text = '$curNoteKeys KEY';
					text.ID = myID;
					lastID = myID;

					if (!isDisplayKey) {
						text.alignment = RIGHT;
						text.x -= 200;
						grpOptions.add(text);
						curOptions.push(i);
						curOptionsValid.push(myID);
					} else grpDisplay.add(text);

					if (isCentered) addCenteredText(text);
					else addKeyText(text, option);

					text.snapToPosition();
					text.y += FlxG.height * 2;
				}
				myID++;
			}
		}
		updateText();
	}

	function addCenteredText(text:Alphabet) {
		text.alignment = LEFT;
		text.gameCenter(X).y -= 55;
		text.spawnPos.y -= 55;
	}
	function addKeyText(text:Alphabet, option:Array<Dynamic>) {
		var keys:Array<Null<FlxKey>> = Controls.binds.get(option[2]);
		if (keys == null) keys = Controls.default_binds.get(option[2]).copy();

		for (n in 0...2) {
			var key:String = InputFormatter.getKeyName(keys[n] ?? NONE);

			var attach:Alphabet = new Alphabet(360 + n * 300, 248, key, NORMAL);
			attach.isMenuItem = true;
			attach.changeX = false;
			attach.distancePerItem.y = 60;
			attach.targetY = text.targetY;
			attach.ID = Math.floor(grpBinds.length / 2);
			attach.snapToPosition();
			attach.y += FlxG.height * 2;
			grpBinds.add(attach);

			attach.scaleX = Math.min(attach.scaleY, (420 - 30) / attach.width);

			// spawn black bars at the right of the key name
			var black:AttachedSprite = new AttachedSprite();
			black.makeGraphic(250, 78, FlxColor.BLACK);
			black.alphaMult = 0.4;
			black.sprTracker = text;
			black.addPoint.set(75 + n * 300, -6);
			grpBlacks.add(black);
		}
	}

	function updateBind(num:Int, text:String) {
		var bind:Alphabet = grpBinds.members[num];
		var attach:Alphabet = new Alphabet(350 + (num % 2) * 300, 248, text, NORMAL);
		attach.isMenuItem = true;
		attach.changeX = false;
		attach.distancePerItem.y = 60;
		attach.targetY = bind.targetY;
		attach.ID = bind.ID;
		attach.setPosition(bind.x, bind.y);

		attach.scaleX = Math.min(1, 230 / attach.width);

		bind.kill();
		grpBinds.remove(bind);
		grpBinds.insert(num, attach);
		bind.destroy();
	}

	var binding:Bool = false;
	var holdingEsc:Float = 0;
	var bindingBlack:FlxSprite;
	var bindingText:Alphabet;
	var bindingText2:Alphabet;

	var timeForMoving:Float = 0.1;
	override function update(elapsed:Float) {
		if (timeForMoving > 0) { //Fix controller bug
			timeForMoving = Math.max(0, timeForMoving - elapsed);
			super.update(elapsed);
			return;
		}

		if (!binding) {
			if (FlxG.keys.justPressed.ESCAPE) {
				close();
				return;
			}

			if (FlxG.keys.pressed.SHIFT) {
				if (FlxG.keys.justPressed.LEFT) keyChange(-1);
				if (FlxG.keys.justPressed.RIGHT) keyChange(1);
			} else if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT) updateAlt(true);

			if (FlxG.keys.justPressed.UP) updateText(-1);
			else if (FlxG.keys.justPressed.DOWN) updateText(1);

			if (FlxG.keys.justPressed.ENTER) {
				if (options[curOptions[curSelected]][1] != defaultKey) {
					bindingBlack = new FlxSprite().makeSolid(FlxG.width, FlxG.height);
					bindingBlack.alpha = 0;
					FlxTween.tween(bindingBlack, {alpha: 0.6}, 0.35);
					add(bindingBlack);

					bindingText = new Alphabet(FlxG.width / 2, 160, Language.getPhrase('controls_rebinding', 'Rebinding {1}', [options[curOptions[curSelected]][3]]), NORMAL);
					bindingText.alignment = CENTER;
					add(bindingText);
					
					bindingText2 = new Alphabet(FlxG.width / 2, 340, Language.getPhrase('controls_rebinding2', 'Hold ESC to Cancel\nHold Backspace to Delete'));
					bindingText2.alignment = CENTER;
					add(bindingText2);

					binding = true;
					holdingEsc = 0;
					Controls.toggleVolumeKeys(false);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else {
					// Reset to Default
					Controls.reset();
					Controls.reloadVolumeKeys();
					var lastSel:Int = curSelected;
					createTexts();
					curSelected = lastSel;
					updateText();
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
			}
		} else {
			var altNum:Int = curAlt ? 1 : 0;
			var curOption:Array<Dynamic> = options[curOptions[curSelected]];
			if (FlxG.keys.pressed.ESCAPE) {
				holdingEsc += elapsed;
				if (holdingEsc > .5) {
					FlxG.sound.play(Paths.sound('cancelMenu'));
					closeBinding();
				}
			} else if (FlxG.keys.pressed.BACKSPACE) {
				holdingEsc += elapsed;
				if (holdingEsc > .5) {
					Controls.binds.get(curOption[2])[altNum] = NONE;
					updateBind(Math.floor(curSelected * 2) + altNum, InputFormatter.getKeyName(NONE));
					FlxG.sound.play(Paths.sound('cancelMenu'));
					closeBinding();
				}
			} else {
				holdingEsc = 0;
				var changed:Bool = false;
				var curKeys:Array<FlxKey> = Controls.binds.get(curOption[2]);

				if (FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY) {
					var keyPressed:Int = FlxG.keys.firstJustPressed();
					var keyReleased:Int = FlxG.keys.firstJustReleased();
					if (keyPressed > -1 && keyPressed != FlxKey.ESCAPE && keyPressed != FlxKey.BACKSPACE) {
						curKeys[altNum] = keyPressed;
						changed = true;
					} else if (keyReleased > -1 && (keyReleased == FlxKey.ESCAPE || keyReleased == FlxKey.BACKSPACE)) {
						curKeys[altNum] = keyReleased;
						changed = true;
					}
				}

				if (changed) {
					if (curKeys[altNum] == curKeys[1 - altNum])
						curKeys[1 - altNum] = FlxKey.NONE;

					var option:String = options[curOptions[curSelected]][2];
					for (n in 0...2) {
						var key:String = null;
						var savKey:Array<Null<FlxKey>> = Controls.binds.get(option);
						key = InputFormatter.getKeyName(savKey[n] ?? NONE);
						updateBind(Math.floor(curSelected * 2) + n, key);
					}
					FlxG.sound.play(Paths.sound('confirmMenu'));
					closeBinding();
				}
			}
		}
		super.update(elapsed);
	}

	function closeBinding() {
		binding = false;
		bindingBlack.destroy();
		remove(bindingBlack);

		bindingText.destroy();
		remove(bindingText);

		bindingText2.destroy();
		remove(bindingText2);
		Controls.reloadVolumeKeys();
	}

	function updateText(?change:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + change, 0, curOptions.length - 1);

		var num:Int = curOptionsValid[curSelected];
		var addNum:Int = 0;
		if (num < 3) addNum = 3 - num;
		else if (num > lastID - 4) addNum = (lastID - 4) - num;

		grpDisplay.forEachAlive((item:Alphabet) -> item.targetY = item.ID - num - addNum);

		grpOptions.forEachAlive((item:Alphabet) -> {
			item.targetY = item.ID - num - addNum;
			item.alpha = (item.ID - num == 0) ? 1 : 0.6;
		});
		grpBinds.forEachAlive((item:Alphabet) -> {
			var parent:Alphabet = grpOptions.members[item.ID];
			item.targetY = parent.targetY;
			item.alpha = parent.alpha;
		});

		updateAlt();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function keyChange(?move:Int = 0) {
		curNoteKeys += move;

		if (curNoteKeys > 9) curNoteKeys = 1;
		if (curNoteKeys < 1) curNoteKeys = 9;

		curSelected = 0;
		curAlt = false;
		createTexts();
	}
	
	function updateAlt(?doSwap:Bool = false) {
		if (doSwap) {
			curAlt = !curAlt;
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		var selectedBG:AttachedSprite = grpBlacks.members[Math.floor(curSelected * 2) + (curAlt ? 1 : 0)];
		selectSpr.sprTracker = selectedBG;
		selectSpr.visible = false;
		
		if (selectSpr.sprTracker != null) {
			selectSpr.scale.set(selectedBG.width, selectedBG.height);
			selectSpr.updateHitbox();
			selectSpr.visible = true;
		}
	}

	override function destroy() {
		Controls.save();
		super.destroy();
	}
}