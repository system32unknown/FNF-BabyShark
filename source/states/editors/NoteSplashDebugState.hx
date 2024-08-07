package states.editors;

import objects.Note;
import objects.StrumNote;
import objects.NoteSplash;

class NoteSplashDebugState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent {
	var config:NoteSplashConfig;
	var forceFrame:Int = -1;
	var curSelected:Int = 0;
	var maxNotes:Int = 4;

	var selection:FlxSprite;
	var notes:FlxTypedGroup<StrumNote>;
	var splashes:FlxTypedGroup<FlxSprite>;
	
	var imageInputText:PsychUIInputText;
	var nameInputText:PsychUIInputText;
	var stepperMinFps:PsychUINumericStepper;
	var stepperMaxFps:PsychUINumericStepper;

	var offsetsText:FlxText;
	var curFrameText:FlxText;
	var curAnimText:FlxText;
	var savedText:FlxText;
	var selecArr:Array<Float> = null;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	public static final defaultTexture:String = 'noteSplashes';

	override function create() {
		FlxG.camera.bgColor = FlxColor.fromHSL(0, 0, .5);
		selection = new FlxSprite(0, 270).makeGraphic(150, 150, FlxColor.BLACK);
		selection.alpha = 0.4;
		add(selection);

		add(notes = new FlxTypedGroup<StrumNote>());
		add(splashes = new FlxTypedGroup<FlxSprite>());

		PlayState.mania = 3;
		addStrumAndSplash();

		var txtx:Float = 60;
		var txty:Float = 640;

		add(new FlxText(txtx, txty - 120, 'Image Name:', 16));

		imageInputText = new PsychUIInputText(txtx, txty - 100, 360, defaultTexture, 16);
		imageInputText.onPressEnter = (_) -> {
			textureName = imageInputText.text;
			try {
				loadFrames();
			} catch(e:Dynamic) {
				Logs.trace('ERROR! $e', ERROR);
				textureName = defaultTexture;
				loadFrames();

				missingText.text = 'ERROR WHILE LOADING IMAGE:\n${imageInputText.text}';
				missingText.screenCenter(Y);
				missingText.visible = true;
				missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));

				FlxTimer.wait(2.5, () -> {
					missingText.visible = false;
					missingTextBG.visible = false;
				});
			}
			PsychUIInputText.focusOn = null;
		}
		add(imageInputText);

		add(new FlxText(txtx, txty, 'Animation Name:', 16));

		nameInputText = new PsychUIInputText(txtx, txty + 20, 360, '', 16);
		nameInputText.onChange = function(oldText:String, curText:String) {
			trace('changed anim name to $curText');
			config.anim = curText;
			curAnim = 1;
			reloadAnims();
		};
		add(nameInputText);

		add(new FlxText(txtx, txty - 84, 0, 'Min/Max Framerate:', 16));
		stepperMinFps = new PsychUINumericStepper(txtx, txty - 60, 1, 22, 1, 60, 0);
		stepperMinFps.name = 'min_fps';
		add(stepperMinFps);

		stepperMaxFps = new PsychUINumericStepper(txtx + 60, txty - 60, 1, 26, 1, 60, 0);
		stepperMaxFps.name = 'max_fps';
		add(stepperMaxFps);

		offsetsText = new FlxText(300, 150, 680, '', 16);
		offsetsText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		offsetsText.scrollFactor.set();
		add(offsetsText);

		curFrameText = new FlxText(300, 100, 680, '', 16);
		curFrameText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		curFrameText.scrollFactor.set();
		add(curFrameText);

		curAnimText = new FlxText(300, 50, 680, '', 16);
		curAnimText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		curAnimText.scrollFactor.set();
		add(curAnimText);

		var text:FlxText = new FlxText(0, 520, FlxG.width,
			"Press SPACE to Reset animation\n
			Press ENTER twice to save to the loaded Note Splash PNG's folder\n
			A/D change selected note - Arrow Keys to change offset (Hold shift for 10x)\n
			Ctrl + C/V - Copy & Paste\n
			Z/X - Change Mania", 16);
		text.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		text.scrollFactor.set();
		add(text);

		savedText = new FlxText(0, 340, FlxG.width, '', 24);
		savedText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		savedText.scrollFactor.set();
		add(savedText);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);

		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		loadFrames();
		changeSelection();
		super.create();
		FlxG.mouse.visible = true;
	}

	var curAnim:Int = 1;
	var visibleTime:Float = 0;
	var pressEnterToSave:Float = 0;
	override function update(elapsed:Float) {
		var notTyping:Bool = (PsychUIInputText.focusOn == null);
		if(controls.BACK && notTyping) {
			FlxG.switchState(() -> new MasterEditorMenu());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			FlxG.mouse.visible = false;
		}
		super.update(elapsed);

		if(!notTyping) return;
		
		if (FlxG.keys.justPressed.A) changeSelection(-1);
		else if (FlxG.keys.justPressed.D) changeSelection(1);

		if(maxAnims < 1) return;

		if(selecArr != null) {
			var movex:Int = 0;
			var movey:Int = 0;
			if(FlxG.keys.justPressed.LEFT) movex = -1;
			else if(FlxG.keys.justPressed.RIGHT) movex = 1;

			if(FlxG.keys.justPressed.UP) movey = 1;
			else if(FlxG.keys.justPressed.DOWN) movey = -1;
			
			if(FlxG.keys.pressed.SHIFT) {
				movex *= 10;
				movey *= 10;
			}

			if(movex != 0 || movey != 0) {
				selecArr[0] -= movex;
				selecArr[1] += movey;
				updateOffsetText();
				splashes.members[curSelected].offset.set(10 + selecArr[0], 10 + selecArr[1]);
			}
		}

		// Copy & Paste
		if(FlxG.keys.pressed.CONTROL) {
			if(FlxG.keys.justPressed.C) {
				var arr:Array<Float> = selectedArray();
				if(copiedArray == null) copiedArray = [0, 0];
				copiedArray[0] = arr[0];
				copiedArray[1] = arr[1];
			} else if(FlxG.keys.justPressed.V && copiedArray != null) {
				var offs:Array<Float> = selectedArray();
				offs[0] = copiedArray[0];
				offs[1] = copiedArray[1];
				splashes.members[curSelected].offset.set(10 + offs[0], 10 + offs[1]);
				updateOffsetText();
			}
		}

		// Saving
		pressEnterToSave -= elapsed;
		if(visibleTime >= 0) {
			visibleTime -= elapsed;
			if(visibleTime <= 0) savedText.visible = false;
		}

		if(FlxG.keys.justPressed.ENTER) {
			savedText.text = 'Press ENTER again to save.';
			if(pressEnterToSave > 0) { //save
				saveFile();
				FlxG.sound.play(Paths.sound('confirmMenu'), .4);
				pressEnterToSave = 0;
				visibleTime = 3;
			} else {
				pressEnterToSave = 0.5;
				visibleTime = 0.5;
			}
			savedText.visible = true;
		}

		// Reset anim & change anim
		if (FlxG.keys.justPressed.SPACE) changeAnim();
		else if (FlxG.keys.justPressed.S) changeAnim(-1);
		else if (FlxG.keys.justPressed.W) changeAnim(1);

		// Force frame
		var updatedFrame:Bool = false;
		if(updatedFrame = FlxG.keys.justPressed.Q) forceFrame--;
		else if(updatedFrame = FlxG.keys.justPressed.E) forceFrame++;

		if(updatedFrame) {
			if(forceFrame < 0) forceFrame = 0;
			else if(forceFrame >= maxFrame) forceFrame = maxFrame - 1;
			
			curFrameText.text = 'Force Frame: ${forceFrame + 1} / $maxFrame\n(Press Q/E to change)';
			splashes.forEachAlive(function(spr:FlxSprite) {
				spr.animation.curAnim.paused = true;
				spr.animation.curAnim.curFrame = forceFrame;
			});
		}

		// Change Mania
		if (FlxG.keys.justPressed.X) changeMania(1);
		else if (FlxG.keys.justPressed.Z) changeMania(-1);
	}

	function updateOffsetText() {
		selecArr = selectedArray();
		offsetsText.text = selecArr.toString();
	}

	var textureName:String = defaultTexture;
	var texturePath:String = '';
	var copiedArray:Array<Float> = null;
	function loadFrames() {
		texturePath = 'noteSplashes/' + textureName;
		splashes.forEachAlive((spr:FlxSprite) -> spr.frames = Paths.getSparrowAtlas(texturePath));
	
		NoteSplash.configs.clear();
		config = NoteSplash.precacheConfig(texturePath);
		if(config == null) config = NoteSplash.precacheConfig(NoteSplash.defaultNoteSplash);
		nameInputText.text = config.anim;
		stepperMinFps.value = config.minFps;
		stepperMaxFps.value = config.maxFps;

		reloadAnims();
	}

	function saveFile() {
		#if sys
		var maxLen:Int = maxAnims * EK.colArray.length;
		var curLen:Int = config.offsets.length;
		while(curLen > maxLen) {
			config.offsets.pop();
			curLen = config.offsets.length;
		}

		var strToSave:String = config.anim + '\n' + config.minFps + ' ' + config.maxFps;
		for (offGroup in config.offsets)
			strToSave += '\n' + offGroup[0] + ' ' + offGroup[1];

		var pathSplit:Array<String> = (Paths.getPath('images/$texturePath.png', IMAGE, true).split('.png')[0] + '.txt').split(':');
		var path:String = pathSplit[pathSplit.length - 1].trim();
		savedText.text = 'Saved to: $path';
		File.saveContent(path, strToSave);
		#else
		savedText.text = 'Can\'t save on this platform, too bad.';
		#end
	}
	
	public function UIEvent(id:String, sender:Dynamic) {
		if (id == PsychUINumericStepper.CHANGE_EVENT && (sender is PsychUINumericStepper)) {
			var nums:PsychUINumericStepper = cast sender;
			switch(nums.name) {
				case 'min_fps': if(nums.value > stepperMaxFps.value) stepperMaxFps.value = nums.value;
				case 'max_fps': if(nums.value < stepperMinFps.value) stepperMinFps.value = nums.value;
			}
			config.minFps = Std.int(stepperMinFps.value);
			config.maxFps = Std.int(stepperMaxFps.value);
		}
	}

	var maxAnims:Int = 0;
	function reloadAnims() {
		var loopContinue:Bool = true;
		splashes.forEachAlive((spr:FlxSprite) -> spr.animation.destroyAnimations());

		maxAnims = 0;
		while(loopContinue) {
			var animID:Int = maxAnims + 1;
			splashes.forEachAlive(function(spr:FlxSprite) {
				for (i in 0...EK.colArray.length) {
					var animName:String = 'note$i-$animID';
					if (!addAnimAndCheck(spr, animName, '${config.anim} ${EK.colArray[i]} $animID', 24, false)) {
						loopContinue = false;
						return;
					}
					spr.animation.play(animName, true);
				}
			});
			if(loopContinue) maxAnims++;
		}
		trace('maxAnims: $maxAnims');
		changeAnim();
	}

	var maxFrame:Int = 0;
	function changeAnim(change:Int = 0) {
		maxFrame = 0;
		forceFrame = -1;
		if (maxAnims > 0) {
			curAnim += change;
			if(curAnim > maxAnims) curAnim = 1;
			else if(curAnim < 1) curAnim = maxAnims;

			curAnimText.text = 'Current Animation: $curAnim / $maxAnims\n(Press W/S to change)';
			curFrameText.text = 'Force Frame Disabled\n(Press Q/E to change)';

			for (i in 0...maxNotes) {
				var spr:FlxSprite = splashes.members[i];
				spr.animation.play('note$i-$curAnim', true);
				
				if(maxFrame < spr.animation.curAnim.numFrames)
					maxFrame = spr.animation.curAnim.numFrames;
				
				spr.animation.curAnim.frameRate = FlxG.random.int(config.minFps, config.maxFps);
				var offs:Array<Float> = selectedArray(i);
				spr.offset.set(10 + offs[0], 10 + offs[1]);
			}
		} else {
			curAnimText.text = 'INVALID ANIMATION NAME';
			curFrameText.text = '';
		}
		updateOffsetText();
	}

	function changeSelection(change:Int = 0) {
		var max:Int = EK.keys(PlayState.mania);
		curSelected = FlxMath.wrap(curSelected + change, 0, max - 1);

		selection.x = setPosX(curSelected) - 20 * EK.scalesPixel[PlayState.mania];
		selection.y = setPosY() - 20 * EK.scalesPixel[PlayState.mania];
		selection.setGraphicSize(Std.int(150 * EK.scalesPixel[PlayState.mania]));
		selection.updateHitbox();
		updateOffsetText();
	}

	function selectedArray(sel:Int = -1) {
		if(sel < 0) sel = curSelected;
		var animID:Int = sel + ((curAnim - 1) * EK.keys(PlayState.mania));
		if(config.offsets[animID] == null) {
			while(config.offsets[animID] == null)
				config.offsets.push(config.offsets[FlxMath.wrap(animID, 0, config.offsets.length - 1)].copy());
		}
		return config.offsets[FlxMath.wrap(animID, 0, config.offsets.length - 1)];
	}

	function addAnimAndCheck(spr:FlxSprite, name:String, anim:String, ?framerate:Int = 24, ?loop:Bool = false) {
		spr.animation.addByPrefix(name, anim, framerate, loop);
		return spr.animation.getByName(name) != null;
	}

	function addStrumAndSplash() {
		maxNotes = EK.keys(PlayState.mania);
		for (i in 0...maxNotes) {
			var x:Float = setPosX(i);
			var y:Float = setPosY();
			var note:StrumNote = new StrumNote(x, y, i, 0);
			note.alpha = 0.75;
			note.playAnim('static');
			notes.add(note);

			var splash:FlxSprite = new FlxSprite(x, y);
			var spX:Float = x + EK.swidths[PlayState.mania] / 2 - Note.swagWidth / 2;
			var spY:Float = y + EK.swidths[PlayState.mania] / 2 - Note.swagWidth / 2;
			splash.setPosition(spX - Note.swagWidth * 0.95, spY - Note.swagWidth);
			splash.setGraphicSize(Std.int(splash.width * EK.scalesPixel[PlayState.mania]));
			splash.shader = note.rgbShader.parent.shader;
			splash.antialiasing = ClientPrefs.data.antialiasing;
			splashes.add(splash);
		}
	}

	function changeMania(change:Int = 0) {
		PlayState.mania += change;
		if(PlayState.mania < 0) PlayState.mania = EK.maxMania;
		else if(PlayState.mania > 8) PlayState.mania = 0;

		notes.forEachAlive((spr:StrumNote) -> spr.destroy());
		notes.clear();
		splashes.forEachAlive((spr:FlxSprite) -> spr.destroy());
		splashes.clear();

		addStrumAndSplash();

		curSelected = 0;
		loadFrames();
		changeSelection();
	}

	function setPosX(data:Int = 0):Float {
		var space:Float = 240 * EK.scalesPixel[PlayState.mania];
		return FlxG.width / 2 - space * PlayState.mania / 2 + space * data - EK.swidths[PlayState.mania] / 2;
	}

	function setPosY():Float {
		return 350 - EK.swidths[PlayState.mania] / 2;
	}
}