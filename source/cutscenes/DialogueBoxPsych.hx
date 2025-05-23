package cutscenes;

import haxe.Json;
import openfl.utils.Assets;
import objects.TypedAlphabet;
import cutscenes.DialogueCharacter;
import scripting.ScriptUtils;

typedef DialogueFile = {
	var dialogue:Array<DialogueLine>;
	var bubble:Null<String>;
}

typedef DialogueLine = {
	var portrait:Null<String>;
	var expression:Null<String>;
	var text:Null<String>;
	var boxState:Null<String>;
	var speed:Null<Float>;
	@:optional var sound:Null<String>;

	var events:Null<Array<DialogueEvent>>;
}

typedef DialogueEvent = {
	var type:String;
	var arguments:Null<Array<String>>;
}

class DialogueBoxPsych extends FlxSpriteGroup {
	public static var DEFAULT_TEXT_X:Int = 175;
	public static var DEFAULT_TEXT_Y:Int = 460;
	public static var LONG_TEXT_ADD:Int = 24;

	var scrollSpeed:Int = 4000;

	var offsetPos:Float = -600;
	var skipText:FlxText;

	var ignoreThisFrame:Bool = true; // First frame is reserved for loading dialogue images

	public var closeSound:String = 'dialogueClose';
	public var closeVolume:Float = 1;

	public function new(dialogueList:DialogueFile, ?song:String = null) {
		super();

		Paths.sound('dialogue'); // precache sounds
		Paths.sound('dialogueClose');

		if (song != null && song != '') {
			FlxG.sound.playMusic(Paths.music(song), 0);
			FlxG.sound.music.fadeIn(2);
		}

		this.createDialogueUI(dialogueList);
	}

	override function update(elapsed:Float) {
		if (ignoreThisFrame) {
			PlayState.instance.callOnHScript('onDialogueStart'); // It's here, because scripts might want to access PlayState.instance.psychDialogue (aka this)
			startNextDialog();

			ignoreThisFrame = false;
			super.update(elapsed);
			return;
		}

		if (!dialogueEnded) {
			bgFade.alpha += .5 * elapsed;
			if (bgFade.alpha > .5) bgFade.alpha = .5;

			var ret:Dynamic = PlayState.instance.callOnHScript('onDialogueConfirm');
			var back:Bool = Controls.justPressed('back');
			if (confirmDialogue || (Controls.justPressed('accept') || back) && ret != ScriptUtils.Function_Stop) {
				if (!typedText.finishedText && !back) {
					typedText.finishText();
					if (skipDialogueThing != null) skipDialogueThing();
				} else this.startNextDialog(back);
	
				FlxG.sound.play(Paths.sound(closeSound), closeVolume);
			} else this.onCharacterAnimationCheck();

			if (box.animation.curAnim != null && box.animation.curAnim.finished) this.onBoxAnimationFinished();
			if (lastCharacter != -1) this.onCharacterUpdate(elapsed);
		} else this.onDialogueEnded(elapsed); // Dialogue ending

		super.update(elapsed);
	}

	// --- DIALOG ---
	var dialogueLines:Array<DialogueLine> = null;
	var dialogueEnded:Bool = false;
	var currentDialogueIndex:Int = 0;
	var confirmDialogue:Bool = false;

	public var finishThing:Void->Void;
	public var nextDialogueThing:Void->Void = null;
	public var skipDialogueThing:Void->Void = null;

	function startNextDialog(back:Bool = false):Void {
		if (back || currentDialogueIndex >= dialogueLines.length) {
			this.onLastDialogueConsummed();
			return;
		}

		var dialogue:DialogueLine = this.fetchNextDialog();
		currentDialogueIndex++;

		if (dialogue.text.length == 0) {
			confirmDialogue = true;
			return;
		}

		confirmDialogue = false;

		var index:Int = this.findCharacterIndex(dialogue); // [0; ...]
		if (index == -1) index = 0;

		var char:Null<DialogueCharacter> = this.getCharacter(index);
		var boxType:String = textBoxTypes.contains(dialogue.boxState) ? dialogue.boxState : textBoxTypes[0];

		this.updateDialogueBox(char, index, boxType);

		// Set dialogue values
		this.updateDialogueValues(dialogue);

		// Play character animation
		this.updateDialogueCharacter(char, dialogue);

		if (nextDialogueThing != null)
			nextDialogueThing();

		if (dialogue.text == null || dialogue.text.length == 0)
			this.startNextDialog();
	}

	function updateDialogueValues(dialogue:DialogueLine):Void {
		typedText.text = dialogue.text;
		typedText.delay = dialogue.speed;
		typedText.sound = dialogue.sound;

		if (typedText.sound == null || typedText.sound.trim() == '')
			typedText.sound = 'dialogue';

		typedText.y = DEFAULT_TEXT_Y;
		if (typedText.length > 2) typedText.y -= LONG_TEXT_ADD;
	}

	function fetchNextDialog():DialogueLine {
		var curDialogue:DialogueLine = null;
		do {
			curDialogue = dialogueLines[currentDialogueIndex];
		} while (curDialogue == null);

		// Set empty text
		if (curDialogue.text == null)
			curDialogue.text = '';

		// Set default box state
		if (curDialogue.boxState == null)
			curDialogue.boxState = 'normal';

		// Set default speed
		if (curDialogue.speed == null || Math.isNaN(curDialogue.speed))
			curDialogue.speed = .05;

		if (curDialogue.events != null) {
			for (i in 0...curDialogue.events.length) {
				var event:DialogueEvent = curDialogue.events[i];
				PlayState.instance.callOnHScript('onDialogueEvent', [event.type, event.arguments]); // Call the current event
			}
		}

		return curDialogue;
	}

	function onDialogueEnded(elapsed:Float) {
		if (box != null && (box.animation.curAnim == null || box.animation.curAnim.curFrame <= 0)) {
			box.kill();
			remove(box);
			box.destroy();
			box = null;
		}

		if (bgFade != null) {
			bgFade.alpha -= 0.5 * elapsed;
			if (bgFade.alpha <= 0) {
				bgFade.kill();
				remove(bgFade);
				bgFade.destroy();
				bgFade = null;
			}
		}

		var shouldKillCharacters:Bool = box == null && bgFade == null;
		for (i in 0...dialogueCharacters.length) {
			var currentCharacter:DialogueCharacter = dialogueCharacters[i];
			if (currentCharacter == null) continue;

			switch (currentCharacter.jsonFile.dialogue_pos) {
				case 'left': currentCharacter.x -= scrollSpeed * elapsed;
				case 'center': currentCharacter.y += scrollSpeed * elapsed;
				case 'right': currentCharacter.x += scrollSpeed * elapsed;
			}
			currentCharacter.alpha -= elapsed * 10;

			if (!shouldKillCharacters) continue;

			dialogueCharacters.remove(currentCharacter);
			currentCharacter.kill();
			remove(currentCharacter);
			currentCharacter.destroy();
		}

		if (shouldKillCharacters) {
			finishThing();
			kill();
		}
	}

	function onLastDialogueConsummed():Void {
		dialogueEnded = true;

		if (box.animation.curAnim != null) {
			var animName:String = box.animation.curAnim.name;
			var checkArray:Array<String> = ['', 'center-'];

			for (i in 0...textBoxTypes.length) {
				for (j in 0...checkArray.length) {
					if (animName == checkArray[j] + textBoxTypes[i] || animName == checkArray[j] + textBoxTypes[i] + 'Open')
						box.animation.play(checkArray[j] + textBoxTypes[i] + 'Open', true);
				}
			}

			box.animation.curAnim.curFrame = box.animation.curAnim.frames.length - 1;
			box.animation.curAnim.reverse();
		}

		if (typedText != null) {
			typedText.kill();
			remove(typedText);
			typedText.destroy();
		}

		this.killAll(texts); // Kill all texts
		this.killAll(sprites); // Kill all sprites

		skipText.visible = false;
		if (shouldBoxRecenter) updateBoxOffsets(box);
		FlxG.sound.music.fadeOut(1, 0, (_:FlxTween) -> FlxG.sound.music.stop());
	}

	inline public static function parseDialogue(path:String):DialogueFile {
		return cast #if MODS_ALLOWED (FileSystem.exists(path)) ? Json.parse(File.getContent(path)) #else (Assets.exists(path, TEXT)) ? Json.parse(Assets.getText(path)) #end : dummy();
	}

	inline public static function dummy():DialogueFile {
		return {
			dialogue: [{
				expression: "talk",
				text: "DIALOGUE NOT FOUND",
				boxState: "normal",
				speed: 0.05,
				portrait: "bf",
				events: []
			}],
			bubble: 'speech_bubble'
		};
	}

	// --- BOX ---
	public var box:FlxSprite;

	var lastBoxType:String = '';
	var textBoxTypes:Array<String> = ['normal'];

	public var shouldBoxFlip:Bool = true;
	public var shouldBoxRecenter:Bool = true;

	function updateDialogueBox(char:Null<DialogueCharacter>, index:Int, boxType:String):Void {
		box.visible = true;

		// If the character is not valid
		if (char == null) return;

		var isDifferentCharacter:Bool = index != lastCharacter;
		var isDiffrentBoxType:Bool = boxType != lastBoxType;

		lastCharacter = index;
		lastBoxType = boxType;

		// If nothing has changed
		if (!isDifferentCharacter && !isDiffrentBoxType) return;

		var dialoguePosition:String = char.jsonFile.dialogue_pos;

		var extraSuffix:String = isDifferentCharacter ? 'Open' : '';
		var centerPrefix:String = dialoguePosition == 'center' ? 'center-' : '';

		box.animation.play(centerPrefix + boxType + extraSuffix, true);
		if (shouldBoxRecenter) updateBoxOffsets(box);

		if (isDifferentCharacter && shouldBoxFlip)
			box.flipX = (dialoguePosition == 'left');
	}

	function onBoxAnimationFinished():Void {
		for (i in 0...textBoxTypes.length) {
			var checkArray:Array<String> = ['', 'center-'];
			var animName:String = box.animation.curAnim.name;
			for (j in 0...checkArray.length) {
				if (animName == checkArray[j] + textBoxTypes[i] || animName == checkArray[j] + textBoxTypes[i] + 'Open')
					box.animation.play(checkArray[j] + textBoxTypes[i], true);
			}
		}

		if (shouldBoxRecenter) updateBoxOffsets(box);
	}

	public static function updateBoxOffsets(box:FlxSprite):Void { // Had to make it static because of the editors
		box.centerOffsets();
		box.updateHitbox();

		var offsetX:Int = 10;
		var offsetY:Int = 0;

		var animationName:String = box.animation.curAnim != null ? box.animation.curAnim.name : '';

		if (animationName.startsWith('angry')) {
			offsetX = 50;
			offsetY = 65;
		} else if (animationName.startsWith('center-angry')) {
			offsetX = 50;
			offsetY = 30;
		}

		box.offset.set(offsetX, offsetY);

		if (!box.flipX) box.offset.y += 10;
	}

	// --- CHARACTER ---
	public static var LEFT_CHAR_X:Float = -60;
	public static var RIGHT_CHAR_X:Float = -100;
	public static var DEFAULT_CHAR_Y:Float = 60;

	public var currentCharX:Float;
	public var currentCharY:Float;
	public var currentCharAlpha:Float;

	var dialogueCharacters:Array<DialogueCharacter> = [];
	var lastCharacter:Int = -1;

	function getCharacter(index:Int):Null<DialogueCharacter> {
		if (index < 0 || index >= dialogueCharacters.length)
			return null;

		return dialogueCharacters[index];
	}

	function findCharacterIndex(dialogue:DialogueLine):Int {
		for (i in 0...dialogueCharacters.length) {
			if (dialogueCharacters[i].curCharacter == dialogue.portrait) return i;
		}
		return -1;
	}

	function createCharacter(charToAdd:String):Void {
		var x:Float = LEFT_CHAR_X;
		var y:Float = DEFAULT_CHAR_Y;

		var char:DialogueCharacter = new DialogueCharacter(x + offsetPos, y, charToAdd);
		char.setGraphicSize(Std.int(char.width * DialogueCharacter.DEFAULT_SCALE * char.jsonFile.scale));
		char.updateHitbox();
		char.scrollFactor.set();
		char.alpha = .00001;
		add(char);

		var saveY:Bool = false;
		switch (char.jsonFile.dialogue_pos) {
			case 'center':
				char.x = FlxG.width / 2;
				char.x -= char.width / 2;
				y = char.y;
				char.y = FlxG.height + 50;
				saveY = true;
			case 'right':
				x = FlxG.width - char.width + RIGHT_CHAR_X;
				char.x = x - offsetPos;
		}
		x += char.jsonFile.position[0];
		y += char.jsonFile.position[1];
		char.x += char.jsonFile.position[0];
		char.y += char.jsonFile.position[1];
		char.startingPos = (saveY ? y : x);
		dialogueCharacters.push(char);
	}

	function createCharacters():Void {
		var charsList:Array<String> = [];
		for (i in 0...dialogueLines.length) {
			if (dialogueLines[i] == null) continue;

			var charToAdd:String = dialogueLines[i].portrait;
			if (charToAdd == null || charsList.contains(charToAdd)) continue;
			charsList.push(charToAdd);
			this.createCharacter(charToAdd);
		}
	}

	function updateDialogueCharacter(char:Null<DialogueCharacter>, dialogue:DialogueLine):Void {
		if (char == null) return;

		char.playAnim(dialogue.expression, typedText.finishedText); // Play animation depending on the expression
		if (char.animation.curAnim == null) return; // If no animation is played
		char.animation.curAnim.frameRate = FlxMath.bound(((dialogue.speed - .05) / 5) * 480, 12, 48); // [12; 48]
	}

	function onCharacterAnimationCheck():Void {
		var char:DialogueCharacter = dialogueCharacters[lastCharacter];
		if (char == null || char.animation.curAnim == null || !char.animation.finished) return;

		if (char.animationIsLoop() && typedText.finishedText)
			char.playAnim(char.animation.curAnim.name, true);
		else char.animation.curAnim.restart();
	}

	function onCharacterUpdate(elapsed:Float):Void {
		for (i in 0...dialogueCharacters.length) {
			var char:DialogueCharacter = dialogueCharacters[i];
			if (char == null) continue;

			if (i == lastCharacter)
				this.onCharacterMove('enter', char, elapsed, defaultCharacterEnter);
			else this.onCharacterMove('exit', char, elapsed, defaultCharacterExit);
		}
	}

	function onCharacterMove(tag:String, char:DialogueCharacter, elapsed:Float, defaultMovement:DialogueCharacter->Float->Void) {
		// Set current positions
		currentCharX = char.x;
		currentCharY = char.y;
		currentCharAlpha = char.alpha;

		// Call Update
		var ret:Dynamic = PlayState.instance.callOnHScript('onCharacterMove', [tag, char.curCharacter, char.startingPos, offsetPos, elapsed]);
		if (ret != ScriptUtils.Function_Stop) defaultMovement(char, elapsed);

		// Set positions
		char.setPosition(currentCharX, currentCharY);
		char.alpha = currentCharAlpha;
	}

	function defaultCharacterEnter(char:DialogueCharacter, elapsed:Float):Void {
		switch (char.jsonFile.dialogue_pos) {
			case 'left':
				currentCharX += scrollSpeed * elapsed;
				if (currentCharX > char.startingPos) currentCharX = char.startingPos;
			case 'center':
				currentCharY -= scrollSpeed * elapsed;
				if (currentCharY < char.startingPos) currentCharY = char.startingPos;
			case 'right':
				currentCharX -= scrollSpeed * elapsed;
				if (currentCharX < char.startingPos) currentCharX = char.startingPos;
		}

		currentCharAlpha += 3 * elapsed;
		if (currentCharAlpha > 1) currentCharAlpha = 1;
	}

	function defaultCharacterExit(char:DialogueCharacter, elapsed:Float):Void {
		switch (char.jsonFile.dialogue_pos) {
			case 'left':
				char.x -= scrollSpeed * elapsed;
				if (char.x < char.startingPos + offsetPos) char.x = char.startingPos + offsetPos;
			case 'center':
				char.y += scrollSpeed * elapsed;
				if (char.y > char.startingPos + FlxG.height) char.y = char.startingPos + FlxG.height;
			case 'right':
				char.x += scrollSpeed * elapsed;
				if (char.x > char.startingPos - offsetPos) char.x = char.startingPos - offsetPos;
		}

		currentCharAlpha -= 3 * elapsed;
		if (currentCharAlpha < .00001) currentCharAlpha = .00001;
	}

	// --- UI ---
	var bgFade:FlxSprite = null;
	var typedText:TypedAlphabet = null;
	var texts:Array<String> = [];
	var sprites:Array<String> = [];

	function createDialogueUI(dialogueList:DialogueFile):Void {
		// Background fade
		bgFade = new FlxSprite(-500, -500).makeGraphic(FlxG.width * 2, FlxG.height * 2);
		bgFade.scrollFactor.set();
		bgFade.visible = true;
		bgFade.alpha = 0;
		add(bgFade);

		dialogueLines = dialogueList.dialogue;
		this.createCharacters();

		// Box
		box = new FlxSprite();
		box.frames = Paths.getSparrowAtlas(dialogueList.bubble ?? 'speech_bubble');
		box.animation.addByPrefix('normal', 'speech bubble normal', 24);
		box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
		box.animation.addByPrefix('angry', 'AHH speech bubble', 24);
		box.animation.addByPrefix('angryOpen', 'speech bubble loud open', 24, false);
		box.animation.addByPrefix('center-normal', 'speech bubble middle', 24);
		box.animation.addByPrefix('center-normalOpen', 'Speech Bubble Middle Open', 24, false);
		box.animation.addByPrefix('center-angry', 'AHH Speech Bubble middle', 24);
		box.animation.addByPrefix('center-angryOpen', 'speech bubble Middle loud open', 24, false);
		box.animation.play('normal', true);
		box.visible = false;
		box.antialiasing = Settings.data.antialiasing;

		box.setPosition(70, 370);
		box.scrollFactor.set();
		box.setGraphicSize(Std.int(box.width * 0.9));
		box.updateHitbox();
		add(box);

		// Text
		typedText = new TypedAlphabet(DEFAULT_TEXT_X, DEFAULT_TEXT_Y);
		typedText.updateScale(.7, .7);
		typedText.onUpdate = (text:String) -> PlayState.instance.callOnHScript('onDialogueTextUpdate', [text]);
		add(typedText);

		skipText = new FlxText(FlxG.width - 320, FlxG.height - 30, 300, Language.getPhrase('dialogue_skip', 'Press BACK to Skip'), 16);
		skipText.setFormat(null, 16, FlxColor.WHITE, RIGHT, OUTLINE_FAST, FlxColor.BLACK);
		skipText.borderSize = 2;
		add(skipText);
	}

	public function addText(tag:String):Void {
		texts.push(tag);
		add(PlayState.instance.getObject(tag));
	}

	public function addSprite(tag:String, front:Bool = false):Void {
		var obj:FlxSprite = PlayState.instance.getObject(tag);
		if (front) add(obj);
		else insert(0, obj);
		sprites.push(tag);
	}

	function killAll(tags:Array<String>):Void {
		for (i in 0...tags.length) {
			// Get tag
			var tag:String = tags[i];

			// Get sprite
			var sprite:FlxSprite = PlayState.instance.getObject(tag);
			if (sprite == null) continue;

			// If exist, kill
			sprite.kill();
			remove(sprite);
			sprite.destroy();
		}
	}
}