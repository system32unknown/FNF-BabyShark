package options;

import backend.InputFormatter;
import flixel.addons.display.FlxBackdrop;
import objects.AttachedSprite;
import flixel.input.keyboard.FlxKey;

class ControlsSubState extends MusicBeatSubstate {
	var curSelected:Int = 0;
	var curPage:Int = 0;
	var curAlt:Bool = false;

	//Show on gamepad - Display name - Save file key - Rebind display name
	var options:Array<Dynamic> = [
		[true, 'PAGE #1', 'Previous', 'Next'],
		[true],
		[true, 'NOTES'],
		// INSERT AFTER TWO!!!
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
	static var defaultKey:String = 'Reset to Default';

	var bg:FlxSprite;
	var grpDisplay:FlxTypedGroup<Alphabet>;
	var grpBlacks:FlxTypedGroup<AttachedSprite>;
	var grpOptions:FlxTypedGroup<Alphabet>;
	var grpBinds:FlxTypedGroup<Alphabet>;
	var selectSpr:AttachedSprite;
	
	public function new() {
		super();

		options.push([true]);
		options.push([true]);
		options.push([true, defaultKey]);

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff7192fd;
		bg.antialiasing = ClientPrefs.getPref('Antialiasing');
		bg.screenCenter();
		add(bg);

		var grid:FlxBackdrop = CoolUtil.createBackDrop(80, 80, 160, 160, true, 0x33FFFFFF, 0x0);
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, .5, {ease: FlxEase.quadOut});
		add(grid);

		grpDisplay = new FlxTypedGroup<Alphabet>();
		add(grpDisplay);
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);
		grpBlacks = new FlxTypedGroup<AttachedSprite>();
		add(grpBlacks);
		selectSpr = new AttachedSprite();
		selectSpr.makeGraphic(250, 78, FlxColor.WHITE);
		selectSpr.copyAlpha = false;
		selectSpr.alpha = 0.75;
		add(selectSpr);
		grpBinds = new FlxTypedGroup<Alphabet>();
		add(grpBinds);

		updatePage();
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
		for (i in 0...options.length) {
			var option:Array<Dynamic> = options[i];
			if(option[0]) {
				if(option.length > 1) {
					var isCentered:Bool = (option.length < 3);
					var isDefaultKey:Bool = (option[1] == defaultKey);
					var isDisplayKey:Bool = (isCentered && !isDefaultKey) && i != 1;

					var text:Alphabet = new Alphabet(200, 300, option[1], !isDisplayKey);
					text.isMenuItem = true;
					text.changeX = false;
					text.distancePerItem.y = 60;
					text.targetY = myID;
					if(isDisplayKey) grpDisplay.add(text);
					else {
						grpOptions.add(text);
						curOptions.push(i);
						curOptionsValid.push(myID);
					}
					text.ID = myID;
					lastID = myID;

					if(isCentered) addCenteredText(text, option, myID);
					else addKeyText(text, option, myID);

					text.snapToPosition();
					text.y += FlxG.height * 2;
				}
				myID++;
			}
		}
		updateText();
	}

	function addCenteredText(text:Alphabet, option:Array<Dynamic>, id:Int) {
		text.screenCenter(X);
		text.y -= 55;
		text.startPosition.y -= 55;
	}
	function addKeyText(text:Alphabet, option:Array<Dynamic>, id:Int) {
		for (n in 0...2) {
			var textX:Float = 350 + n * 300;

			var key:String = null;

			if (options.indexOf(option) != 0) {
				var savKey:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(option[2]);
				key = InputFormatter.getKeyName((savKey[n] != null) ? savKey[n] : NONE);
			} else key = options[0][n + 2];

			var attach:Alphabet = new Alphabet(textX + 210, 248, key, false);
			attach.isMenuItem = true;
			attach.changeX = false;
			attach.distancePerItem.y = 60;
			attach.targetY = text.targetY;
			attach.ID = Math.floor(grpBinds.length / 2);
			attach.snapToPosition();
			attach.y += FlxG.height * 2;
			grpBinds.add(attach);

			attach.scaleX = Math.min(1, 230 / attach.width);

			// spawn black bars at the right of the key name
			var black:AttachedSprite = new AttachedSprite();
			black.makeGraphic(250, 78, FlxColor.BLACK);
			black.alphaMult = 0.4;
			black.sprTracker = text;
			black.addPoint.set(textX, -6);
			grpBlacks.add(black);
		}
	}

	function updateBind(num:Int, text:String)
	{
		var bind:Alphabet = grpBinds.members[num];
		var attach:Alphabet = new Alphabet(350 + (num % 2) * 300, 248, text, false);
		attach.isMenuItem = true;
		attach.changeX = false;
		attach.distancePerItem.y = 60;
		attach.targetY = bind.targetY;
		attach.ID = bind.ID;
		attach.x = bind.x;
		attach.y = bind.y;
		
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

	var timeForMoving:Float = .1;
	override function update(elapsed:Float)
	{
		if(timeForMoving > 0) {
			timeForMoving = Math.max(0, timeForMoving - elapsed);
			super.update(elapsed);
			return;
		}

		if(!binding) {
			if(FlxG.keys.justPressed.ESCAPE) {
				close();
				return;
			}

			if(FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT)
				updateAlt(true);

			if(FlxG.keys.justPressed.UP) updateText(-1);
			else if(FlxG.keys.justPressed.DOWN) updateText(1);

			if(FlxG.keys.justPressed.ENTER) {
				if (options[0] == options[curOptions[curSelected]]) {
					if (curAlt && curPage != EK.maxMania)
						updatePage(1);
					else if (!curAlt && curPage != EK.minMania)
						updatePage(-1);
				} else if(options[curOptions[curSelected]][1] != defaultKey) {
					bindingBlack = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
					bindingBlack.alpha = 0;
					FlxTween.tween(bindingBlack, {alpha: 0.6}, 0.35, {ease: FlxEase.linear});
					add(bindingBlack);

					bindingText = new Alphabet(FlxG.width / 2, 160, "Rebinding " + options[curOptions[curSelected]][3], false);
					bindingText.alignment = CENTERED;
					add(bindingText);
					
					bindingText2 = new Alphabet(FlxG.width / 2, 340, "Hold ESC to Cancel\nHold Backspace to Delete", true);
					bindingText2.alignment = CENTERED;
					add(bindingText2);

					binding = true;
					holdingEsc = 0;
					ClientPrefs.toggleVolumeKeys(false);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else {
					ClientPrefs.resetKeys();
					ClientPrefs.reloadVolumeKeys();
					var lastSel:Int = curSelected;
					createTexts();
					curSelected = lastSel;
					updateText();
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
			}
		}
		else
		{
			var altNum:Int = curAlt ? 1 : 0;
			var curOption:Array<Dynamic> = options[curOptions[curSelected]];
			if(FlxG.keys.pressed.ESCAPE) {
				holdingEsc += elapsed;
				if(holdingEsc > 0.5)
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					closeBinding();
				}
			} else if (FlxG.keys.pressed.BACKSPACE) {
				holdingEsc += elapsed;
				if(holdingEsc > .5) {
					ClientPrefs.keyBinds.get(curOption[2])[altNum] = NONE;
					ClientPrefs.clearInvalidKeys(curOption[2]);
					updateBind(Math.floor(curSelected * 2) + altNum, InputFormatter.getKeyName(NONE));
					FlxG.sound.play(Paths.sound('cancelMenu'));
					closeBinding();
				}
			} else {
				holdingEsc = 0;
				var changed:Bool = false;
				var curKeys:Array<FlxKey> = ClientPrefs.keyBinds.get(curOption[2]);

				if(FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY) {
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

				if(changed) {
					if(curKeys[altNum] == curKeys[1 - altNum])
						curKeys[1 - altNum] = FlxKey.NONE;

					var option:String = options[curOptions[curSelected]][2];
					ClientPrefs.clearInvalidKeys(option);
					for (n in 0...2) {
						var key:String = null;
						var savKey:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(option);
						key = InputFormatter.getKeyName(savKey[n] != null ? savKey[n] : NONE);
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
		ClientPrefs.reloadVolumeKeys();
	}

	function updatePage(?move:Int = 0) {
		curPage = FlxMath.wrap(curPage + move, EK.minMania, EK.maxMania);

		var tempOptionArray:Array<Dynamic> = [
			[true, 'PAGE #1', 'Previous', 'Next'],
			[true],
			[true, 'NOTES'],

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
		tempOptionArray[0][1] = 'PAGE #'+(curPage+1);

		var keybindsToInsert:Array<Dynamic> = EK.controlMenu[curPage];
		for (i in 0...keybindsToInsert.length) {
			tempOptionArray.insert(3 + i, keybindsToInsert[i]);
		}

		options = tempOptionArray;

		createTexts();
	}

	function updateText(?move:Int = 0) {
		if(move != 0) {
			curSelected += move;

			if(curSelected < 0) curSelected = curOptions.length - 1;
			else if (curSelected >= curOptions.length) curSelected = 0;
		}

		var num:Int = curOptionsValid[curSelected];
		var addNum:Int = 0;
		if(num < 3) addNum = 3 - num;
		else if(num > lastID - 4) addNum = (lastID - 4) - num;

		grpDisplay.forEachAlive((item:Alphabet) -> item.targetY = item.ID - num - addNum);

		grpOptions.forEachAlive(function(item:Alphabet) {
			item.targetY = item.ID - num - addNum;
			item.alpha = (item.ID - num == 0) ? 1 : .6;
		});
		grpBinds.forEachAlive(function(item:Alphabet) {
			var parent:Alphabet = grpOptions.members[item.ID];
			item.targetY = parent.targetY;
			item.alpha = parent.alpha;
		});

		updateAlt();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function updateAlt(?doSwap:Bool = false) {
		if(doSwap) {
			curAlt = !curAlt;
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		selectSpr.sprTracker = grpBlacks.members[Math.floor(curSelected * 2) + (curAlt ? 1 : 0)];
		selectSpr.visible = (selectSpr.sprTracker != null);
	}
}