package states;

import flixel.util.FlxSpriteUtil;
import openfl.display.BitmapData;

class ModsMenuState extends MusicBeatState {
	var bg:FlxSprite;
	var icon:FlxSprite;
	var modName:Alphabet;
	var modDesc:FlxText;
	var modRestartText:FlxText;
	var modsList:ModsList = null;

	var bgList:FlxSprite;
	var buttonReload:MenuButton;

	var buttonEnableAll:MenuButton;
	var buttonDisableAll:MenuButton;
	var buttons:Array<MenuButton> = [];
	var settingsButton:MenuButton;

	var bgTitle:FlxSprite;
	var bgDescription:FlxSprite;
	var bgButtons:FlxSprite;

	var modsGroup:FlxTypedGroup<ModItem>;
	var curSelectedMod:Int = 0;

	var hoveringOnMods:Bool = true;
	var curSelectedButton:Int = 0; ///-1 = Enable/Disable All, -2 = Reload
	var modNameInitialY:Float = 0;

	var noModsSine:Float = 0;
	var noModsTxt:FlxText;

	var startMod:String = null;

	public function new(startMod:String = null) {
		this.startMod = startMod;
		super();
	}
	override function create() {
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		persistentUpdate = false;

		modsList = Mods.parseList();
		Mods.loadTopMod();

		#if desktop DiscordClient.changePresence("In the Mod Menus"); #end

		bg = new FlxSprite(Paths.image('menuDesat'));
		bg.color = 0xFF665AFF;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.gameCenter();

		bgList = FlxSpriteUtil.drawRoundRect(new FlxSprite(40, 40).makeGraphic(340, 440, FlxColor.TRANSPARENT), 0, 0, 340, 440, 15, 15, FlxColor.BLACK);
		bgList.alpha = .6;

		modsGroup = new FlxTypedGroup<ModItem>();

		for (i => mod in modsList.all) {
			if (startMod == mod) curSelectedMod = i;

			var modItem:ModItem = new ModItem(mod);
			if (modsList.disabled.contains(mod)) {
				modItem.icon.color = 0xFFFF6666;
				modItem.text.color = FlxColor.GRAY;
			}
			modsGroup.add(modItem);
		}

		var mod:ModItem = modsGroup.members[curSelectedMod];
		if (mod != null) bg.color = mod.bgColor;

		var buttonX:Float = bgList.x;
		var buttonWidth:Int = Std.int(bgList.width);
		var buttonHeight:Int = 80;

		add(buttonReload = new MenuButton(buttonX, bgList.y + bgList.height + 20, buttonWidth, buttonHeight, "RELOAD", reload));
		
		var myY:Float = buttonReload.y + buttonReload.bg.height + 20;

		buttonEnableAll = new MenuButton(buttonX, myY, buttonWidth, buttonHeight, "ENABLE ALL", () -> {
			buttonEnableAll.ignoreCheck = false;
			for (mod in modsGroup.members) {
				if (modsList.disabled.contains(mod.folder)) {
					modsList.disabled.remove(mod.folder);
					modsList.enabled.push(mod.folder);
					mod.icon.color = mod.text.color = FlxColor.WHITE;
				}
			}
			updateModDisplayData();
			checkToggleButtons();
			FlxG.sound.play(Paths.sound('scrollMenu'), .6);
		});
		buttonEnableAll.bg.color = FlxColor.GREEN;
		buttonEnableAll.focusChangeCallback = (focus:Bool) -> if (!focus) buttonEnableAll.bg.color = FlxColor.GREEN;
		add(buttonEnableAll);

		buttonDisableAll = new MenuButton(buttonX, myY, buttonWidth, buttonHeight, Language.getPhrase('disable_all_button', 'DISABLE ALL'), () -> {
			buttonDisableAll.ignoreCheck = false;
			for (mod in modsGroup.members) {
				if (modsList.enabled.contains(mod.folder)) {
					modsList.enabled.remove(mod.folder);
					modsList.disabled.push(mod.folder);
					mod.icon.color = 0xFFFF6666;
					mod.text.color = FlxColor.GRAY;
				}
			}
			updateModDisplayData();
			checkToggleButtons();
			FlxG.sound.play(Paths.sound('scrollMenu'), .6);
		});
		buttonDisableAll.bg.color = 0xFFFF6666;
		buttonDisableAll.focusChangeCallback = (focus:Bool) -> if (!focus) buttonDisableAll.bg.color = 0xFFFF6666;
		add(buttonDisableAll);
		checkToggleButtons();

		if (modsList.all.length < 1) {
			buttonDisableAll.visible = buttonDisableAll.enabled = false;
			buttonEnableAll.visible = true;

			var myX:Float = bgList.x + bgList.width + 20;
			noModsTxt = new FlxText(myX, 0, FlxG.width - myX - 20, Language.getPhrase('no_mods_installed', 'NO MODS INSTALLED\nPRESS BACK TO EXIT OR INSTALL A MOD'), 48);
			noModsTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
			noModsTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
			add(noModsTxt);
			noModsTxt.gameCenter(Y);

			var txt:FlxText = new FlxText(bgList.x + 15, bgList.y + 15, bgList.width - 30, Language.getPhrase('no_mods_found', "No Mods found."), 16);
			txt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE);
			add(txt);

			FlxG.autoPause = false;
			changeSelectedMod();
			return super.create();
		}

		bgTitle = FlxSpriteUtil.drawRoundRectComplex(new FlxSprite(bgList.x + bgList.width + 20, 40).makeGraphic(840, 180, FlxColor.TRANSPARENT), 0, 0, 840, 180, 15, 15, 0, 0, FlxColor.BLACK);
		bgTitle.alpha = 0.6;
		add(bgTitle);

		icon = new FlxSprite(bgTitle.x + 15, bgTitle.y + 15);
		add(icon);

		modNameInitialY = icon.y + 80;
		modName = new Alphabet(icon.x + 165, modNameInitialY);
		modName.scaleY = .8;
		add(modName);

		bgDescription = FlxSpriteUtil.drawRoundRectComplex(new FlxSprite(bgTitle.x, bgTitle.y + 200).makeGraphic(840, 450, FlxColor.TRANSPARENT), 0, 0, 840, 450, 0, 0, 15, 15, FlxColor.BLACK);
		bgDescription.alpha = .6;
		add(bgDescription);
		
		modDesc = new FlxText(bgDescription.x + 15, bgDescription.y + 15, bgDescription.width - 30, "", 24);
		modDesc.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE);
		add(modDesc);

		var myHeight:Int = 100;
		modRestartText = new FlxText(bgDescription.x + 15, bgDescription.y + bgDescription.height - myHeight - 25, bgDescription.width - 30, Language.getPhrase('mod_restart', '* Moving or Toggling On/Off this Mod will restart the game.'), 16);
		modRestartText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT);
		add(modRestartText);

		bgButtons = FlxSpriteUtil.drawRoundRectComplex(new FlxSprite(bgDescription.x, bgDescription.y + bgDescription.height - myHeight).makeGraphic(840, myHeight, FlxColor.TRANSPARENT), 0, 0, 840, myHeight, 0, 0, 15, 15, FlxColor.WHITE);
		bgButtons.color = FlxColor.BLACK;
		bgButtons.alpha = 0.2;
		add(bgButtons);

		var buttonsX:Float = bgButtons.x + 320;
		var buttonsY:Float = bgButtons.y + 10;

		var button:MenuButton = new MenuButton(buttonsX, buttonsY, 80, 80, Paths.image('modsMenuButtons'), () -> moveModToPosition(0), 54, 54); //Move to the top
		button.icon.animation.add('icon', [0]);
		button.icon.animation.play('icon', true);
		add(button);
		buttons.push(button);

		var button:MenuButton = new MenuButton(buttonsX + 100, buttonsY, 80, 80, Paths.image('modsMenuButtons'), () -> moveModToPosition(curSelectedMod - 1), 54, 54); //Move up
		button.icon.animation.add('icon', [1]);
		button.icon.animation.play('icon', true);
		add(button);
		buttons.push(button);

		var button:MenuButton = new MenuButton(buttonsX + 200, buttonsY, 80, 80, Paths.image('modsMenuButtons'), () -> moveModToPosition(curSelectedMod + 1), 54, 54); //Move down
		button.icon.animation.add('icon', [2]);
		button.icon.animation.play('icon', true);
		add(button);
		buttons.push(button);
		
		if (modsList.all.length < 2) for (button in buttons) button.enabled = false;

		settingsButton = new MenuButton(buttonsX + 300, buttonsY, 80, 80, Paths.image('modsMenuButtons'), () -> { //Settings
			var curMod:ModItem = modsGroup.members[curSelectedMod];
			if (curMod != null && curMod.settings != null && curMod.settings.length > 0)
				openSubState(new options.ModSettingsSubState(curMod.settings, curMod.folder, curMod.name));
		}, 54, 54);
		settingsButton.icon.animation.add('icon', [3]);
		settingsButton.icon.animation.play('icon', true);
		add(settingsButton);
		buttons.push(settingsButton);

		if (modsGroup.members[curSelectedMod].settings == null || modsGroup.members[curSelectedMod].settings.length < 1)
			settingsButton.enabled = false;

		var button:MenuButton = new MenuButton(buttonsX + 400, buttonsY, 80, 80, Paths.image('modsMenuButtons'), () -> { //On/Off
			var curMod:ModItem = modsGroup.members[curSelectedMod];
			var mod:String = curMod.folder;
			if (!modsList.disabled.contains(mod)) { //Enable
				modsList.enabled.remove(mod);
				modsList.disabled.push(mod);
			} else { //Disable
				modsList.disabled.remove(mod);
				modsList.enabled.push(mod);
			}
			curMod.icon.color = modsList.disabled.contains(mod) ? 0xFFFF6666 : FlxColor.WHITE;
			curMod.text.color = modsList.disabled.contains(mod) ? FlxColor.GRAY : FlxColor.WHITE;

			if (curMod.mustRestart) waitingToRestart = true;
			updateModDisplayData();
			checkToggleButtons();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		}, 54, 54);
		button.icon.animation.add('icon', [4]);
		button.icon.animation.play('icon', true);
		add(button);
		buttons.push(button);
		button.focusChangeCallback = (focus:Bool) -> if (!focus) button.bg.color = modsList.enabled.contains(modsGroup.members[curSelectedMod].folder) ? FlxColor.GREEN : 0xFFFF6666;

		if (modsList.all.length < 1) {
			for (btn in buttons) btn.enabled = false;
			button.focusChangeCallback = null;
		}
		
		add(bgList);
		add(modsGroup);

		changeSelectedMod();
		super.create();
	}
	
	var nextAttempt:Float = 1;
	var holdingMod:Bool = false;
	var mouseOffsets:FlxPoint = FlxPoint.get();
	var holdingElapsed:Float = 0;
	var gottaClickAgain:Bool = false;

	var holdTime:Float = 0;

	override function update(elapsed:Float) {
		final backJustPressed:Bool = Controls.justPressed('back');
		final acceptJustPressed:Bool = Controls.justPressed('accept');
		final upJustPressed:Bool = Controls.justPressed('ui_up');
		final downJustPressed:Bool = Controls.justPressed('ui_down');
		final rightJustPressed:Bool = Controls.justPressed('ui_right');

		if (backJustPressed && hoveringOnMods) {
			saveTxt();

			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (waitingToRestart) {
				TitleState.seenIntro = false;
				FlxG.sound.music.fadeOut(.3);
				if (FreeplayState.vocals != null) {
					FreeplayState.vocals.fadeOut(.3);
					FreeplayState.vocals = null;
				}
				FlxG.camera.fade(FlxColor.BLACK, .5, false, FlxG.resetGame);
			} else FlxG.switchState(() -> new MainMenuState());

			persistentUpdate = false;
			FlxG.autoPause = ClientPrefs.data.autoPause;
			FlxG.mouse.visible = false;
			return;
		}

		if (Math.abs(FlxG.mouse.deltaX) > 10 || Math.abs(FlxG.mouse.deltaY) > 10) {
			if (!FlxG.mouse.visible) FlxG.mouse.visible = true;
		}

		if (Controls.released('ui_down') || Controls.released('ui_up')) holdTime = 0;

		if (modsList.all.length > 0) {
			var lastMode:Bool = hoveringOnMods;
			if (modsList.all.length > 1) {
				if (FlxG.mouse.justPressed) {
					for (i in centerMod - 2...centerMod + 3) {
						var mod:ModItem = modsGroup.members[i];
						if (mod != null && mod.visible && FlxG.mouse.overlaps(mod)) {
							hoveringOnMods = true;
							var button:MenuButton = getButton();
							button.ignoreCheck = button.onFocus = false;
							mouseOffsets.set(FlxG.mouse.x - mod.x, FlxG.mouse.y - mod.y);
							curSelectedMod = i;
							changeSelectedMod();
							break;
						}
					}
					hoveringOnMods = true;
					var button:MenuButton = getButton();
					button.ignoreCheck = button.onFocus = false;
					gottaClickAgain = false;
				}

				if (hoveringOnMods) {
					var shiftMult:Int = (FlxG.keys.pressed.SHIFT) ? 4 : 1;
					if (downJustPressed || upJustPressed) changeSelectedMod(downJustPressed ? shiftMult : -shiftMult);
					else if (FlxG.mouse.wheel != 0) changeSelectedMod(-FlxG.mouse.wheel * shiftMult, true);
					else if (FlxG.keys.justPressed.HOME || FlxG.keys.justPressed.END) {
						if (FlxG.keys.justPressed.END) curSelectedMod = modsList.all.length - 1;
						else curSelectedMod = 0;
						changeSelectedMod();
					} else if (upJustPressed || Controls.justPressed('ui_down')) {
						var lastHoldTime:Float = holdTime;
						holdTime += elapsed;
						if (holdTime > 0.5 && Math.floor(lastHoldTime * 8) != Math.floor(holdTime * 8)) changeSelectedMod(shiftMult * (upJustPressed ? -1 : 1));
					} else if (FlxG.mouse.pressed && !gottaClickAgain) {
						var curMod:ModItem = modsGroup.members[curSelectedMod];
						if (curMod != null) {
							if (!holdingMod && FlxG.mouse.justMoved && FlxG.mouse.overlaps(curMod)) holdingMod = true;

							if (holdingMod) {
								var moved:Bool = false;
								for (i in centerMod - 2...centerMod + 3) {
									var mod:ModItem = modsGroup.members[i];
									if (mod != null && mod.visible && FlxG.mouse.overlaps(mod) && curSelectedMod != i) {
										moveModToPosition(i);
										moved = true;
										break;
									}
								}
								
								if (!moved) {
									var factor:Float = -1;
									if (FlxG.mouse.y < bgList.y) factor = Math.abs(Math.max(0.2, Math.min(0.5, 0.5 - (bgList.y - FlxG.mouse.y) / 100)));
									else if (FlxG.mouse.y > bgList.y + bgList.height) factor = Math.abs(Math.max(0.2, Math.min(0.5, 0.5 - (FlxG.mouse.y - bgList.y - bgList.height) / 100)));
		
									if (factor >= 0) {
										holdingElapsed += elapsed;
										if (holdingElapsed >= factor) {
											holdingElapsed = 0;
											var newPos:Int = curSelectedMod;
											if (FlxG.mouse.y < bgList.y) newPos--;
											else newPos++;
											moveModToPosition(Std.int(Math.max(0, Math.min(modsGroup.length - 1, newPos))));
										}
									}
								}
								curMod.setPosition(FlxG.mouse.x - mouseOffsets.x, FlxG.mouse.y - mouseOffsets.y);
							}
						}
					} else if (FlxG.mouse.justReleased && holdingMod) {
						holdingMod = false;
						holdingElapsed = 0;
						updateItemPositions();
					}
				}
			}

			if (lastMode == hoveringOnMods) {
				if (hoveringOnMods) {
					if (rightJustPressed) {
						hoveringOnMods = false;
						var button:MenuButton = getButton();
						button.ignoreCheck = button.onFocus = false;
						curSelectedButton = 0;
						changeSelectedButton();
					}
				} else {
					if (backJustPressed) {
						hoveringOnMods = true;
						var button:MenuButton = getButton();
						button.ignoreCheck = button.onFocus = false;
						changeSelectedMod();
					} else if (acceptJustPressed) getButton().onClick();
					else if (curSelectedButton < 0) {
						if (upJustPressed) {
							switch(curSelectedButton) {
								case -2:
									curSelectedMod = 0;
									hoveringOnMods = true;
									var button:MenuButton = getButton();
									button.ignoreCheck = button.onFocus = false;
									changeSelectedMod();
								case -1: changeSelectedButton(-1);
							}
						} else if (downJustPressed) {
							switch(curSelectedButton) {
								case -2: changeSelectedButton(1);
								case -1:
									curSelectedMod = 0;
									hoveringOnMods = true;
									var button:MenuButton = getButton();
									button.ignoreCheck = button.onFocus = false;
									changeSelectedMod();
							}
						} else if (rightJustPressed) {
							var button:MenuButton = getButton();
							button.ignoreCheck = button.onFocus = false;
							curSelectedButton = 0;
							changeSelectedButton();
						}
					} else if (Controls.justPressed('ui_left') || rightJustPressed) {
						changeSelectedButton(rightJustPressed ? 1 : -1);
					}
				}
			}
		} else {
			noModsSine += 180 * elapsed;
			noModsTxt.alpha = 1 - Math.sin((Math.PI * noModsSine) / 180);
			
			// Keep refreshing mods list every 2 seconds until you add a mod on the folder
			nextAttempt -= elapsed;
			if (nextAttempt < 0) {
				nextAttempt = 1;
				@:privateAccess
				Mods.updateModList();
				modsList = Mods.parseList();
				if (modsList.all.length > 0) {
					trace('${modsList.all.length} mod(s) found! reloading');
					reload();
				}
			}
		}
		super.update(elapsed);
	}

	function changeSelectedButton(add:Int = 0) {
		var max:Int = buttons.length - 1;
		
		var button:MenuButton = getButton();
		button.ignoreCheck = button.onFocus = false;

		curSelectedButton += add;
		if (curSelectedButton < -2) curSelectedButton = -2;
		else if (curSelectedButton > max) curSelectedButton = max;

		var button:MenuButton = getButton();
		button.ignoreCheck = button.onFocus = true;

		var curMod:ModItem = modsGroup.members[curSelectedMod];
		if (curMod != null) curMod.selectBg.visible = false;
		if (curSelectedButton < 0) {
			bgButtons.color = FlxColor.BLACK;
			bgButtons.alpha = 0.2;
		} else {
			bgButtons.color = FlxColor.WHITE;
			bgButtons.alpha = 0.8;
		}

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function getButton():MenuButton {
		switch(curSelectedButton) {
			case -2: return buttonReload;
			case -1: return buttonEnableAll.enabled ? buttonEnableAll : buttonDisableAll;
		}

		if (modsList.all.length < 1) return buttonReload; //prevent possible crash from my irresponsibility
		return buttons[Std.int(Math.max(0, Math.min(buttons.length - 1, curSelectedButton)))];
	}

	function changeSelectedMod(add:Int = 0, isMouseWheel:Bool = false) {
		var max:Int = modsList.all.length - 1;
		if (max < 0) return;

		if (hoveringOnMods) {
			var button:MenuButton = getButton();
			button.ignoreCheck = button.onFocus = false;
		}

		var lastSelected = curSelectedMod;
		curSelectedMod += add;

		var limited:Bool = false;
		if (curSelectedMod < 0) {
			curSelectedMod = 0;
			limited = true;
		} else if (curSelectedMod > max) {
			curSelectedMod = max;
			limited = true;
		}
		
		if (!isMouseWheel && limited && Math.abs(add) == 1) {
			if (add < 0) { // pressed up on first mod
				curSelectedMod = lastSelected;
				hoveringOnMods = false;
				curSelectedButton = -1;
				changeSelectedButton();
				return;
			} else { // pressed down on last mod
				curSelectedMod = lastSelected;
				hoveringOnMods = false;
				curSelectedButton = -2;
				changeSelectedButton();
				return;
			}
		}
		
		holdingMod = false;
		holdingElapsed = 0;
		gottaClickAgain = true;
		updateModDisplayData();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		
		if (hoveringOnMods) {
			var curMod:ModItem = modsGroup.members[curSelectedMod];
			if (curMod != null) curMod.selectBg.visible = true;
			bgButtons.color = FlxColor.BLACK;
			bgButtons.alpha = 0.2;
		}
	}

	function updateModDisplayData() {
		var curMod:ModItem = modsGroup.members[curSelectedMod];
		if (curMod == null) return;

		FlxTween.cancelTweensOf(bg);
		FlxTween.color(bg, 1, bg.color, curMod.bgColor);

		if (Math.abs(centerMod - curSelectedMod) > 2) {
			if (centerMod < curSelectedMod)
				centerMod = curSelectedMod - 2;
			else centerMod = curSelectedMod + 2;
		}
		updateItemPositions();

		icon.loadGraphic(curMod.icon.graphic, true, 150, 150);
		icon.antialiasing = curMod.icon.antialiasing;

		if (curMod.totalFrames > 0) {
			icon.animation.add("icon", [for (i in 0...curMod.totalFrames) i], curMod.iconFps);
			icon.animation.play("icon");
			icon.animation.curAnim.curFrame = curMod.icon.animation.curAnim.curFrame;
		}

		if (modName.scaleX != 0.8) modName.updateScale(.8, .8);
		modName.text = curMod.name;
		var newScale = Math.min(620 / (modName.width / .8), .8);
		modName.updateScale(newScale, Math.min(newScale * 1.35, .8));
		modName.y = modNameInitialY - (modName.height / 2);
		modRestartText.visible = curMod.mustRestart;
		modDesc.text = curMod.desc;

		for (button in buttons) if (button.focusChangeCallback != null) button.focusChangeCallback(button.onFocus);
		settingsButton.enabled = (curMod.settings != null && curMod.settings.length > 0);
	}

	var centerMod:Int = 2;
	function updateItemPositions() {
		var maxVisible:Float = Math.max(4, centerMod + 2);
		var minVisible:Float = Math.max(0, centerMod - 2);
		for (i => mod in modsGroup.members) {
			if (mod == null) {
				Logs.trace('Mod #$i is null, maybe it was ${modsList.all[i]}', WARNING);
				continue;
			}

			mod.visible = (i >= minVisible && i <= maxVisible);
			mod.setPosition(bgList.x + 5, bgList.y + (86 * (i - centerMod + 2)) + 5);
			
			mod.alpha = .6;
			if (i == curSelectedMod) mod.alpha = 1;
			mod.selectBg.visible = (i == curSelectedMod && hoveringOnMods);
		}
	}

	var waitingToRestart:Bool = false;
	function moveModToPosition(?mod:String = null, position:Int = 0) {
		mod ??= modsList.all[curSelectedMod];
		if (position >= modsList.all.length) position = 0;
		else if (position < 0) position = modsList.all.length - 1;

		trace('Moved mod $mod to position $position');
		var id:Int = modsList.all.indexOf(mod);
		if (position == id) return;

		var curMod:ModItem = modsGroup.members[id];
		if (curMod == null) return;

		if (curMod.mustRestart || modsGroup.members[position].mustRestart) waitingToRestart = true;

		modsGroup.remove(curMod, true);
		modsList.all.remove(mod);
		modsGroup.insert(position, curMod);
		modsList.all.insert(position, mod);

		curSelectedMod = position;
		updateModDisplayData();
		updateItemPositions();
		
		if (!hoveringOnMods) {
			var curMod:ModItem = modsGroup.members[curSelectedMod];
			if (curMod != null) curMod.selectBg.visible = false;
		}
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function checkToggleButtons() {
		buttonEnableAll.visible = buttonEnableAll.enabled = modsList.disabled.length > 0;
		buttonDisableAll.visible = buttonDisableAll.enabled = !buttonEnableAll.visible;
	}

	function reload() {
		saveTxt();
		FlxG.autoPause = ClientPrefs.data.autoPause;
		MusicBeatState.skipNextTransIn = MusicBeatState.skipNextTransOut = true;
		var curMod:ModItem = modsGroup.members[curSelectedMod];
		FlxG.switchState(() -> new ModsMenuState(curMod?.folder));
	}
	
	function saveTxt() {
		var fileStr:String = '';
		for (mod in modsList.all) {
			if (mod.trim().length < 1) continue;
			if (fileStr.length > 0) fileStr += '\n';

			var on:String = '1';
			if (modsList.disabled.contains(mod)) on = '0';
			fileStr += '$mod|$on';
		}
		File.saveContent('modsList.txt', fileStr);
		Mods.parseList();
		Mods.loadTopMod();
	}

	override function destroy() {
		mouseOffsets = flixel.util.FlxDestroyUtil.put(mouseOffsets);
		super.destroy();
	}
}

class ModItem extends FlxSpriteGroup {
	public var selectBg:FlxSprite;
	public var icon:FlxSprite;
	public var text:FlxText;
	public var totalFrames:Int = 0;

	// options
	public var name:String = 'Unknown Mod';
	public var desc:String = 'No description provided.';
	public var iconFps:Int = 10;
	public var bgColor:FlxColor = 0xFF665AFF;
	public var pack:Dynamic = null;
	public var folder:String = 'unknownMod';
	public var mustRestart:Bool = false;
	public var settings:Array<Dynamic> = null;

	public function new(folder:String) {
		super();

		this.folder = folder;
		pack = Mods.getPack(folder);

		var path:String = Paths.mods('$folder/data/settings.json');
		if (FileSystem.exists(path)) {
			try {
				settings = tjson.TJSON.parse(File.getContent(path));
			} catch(e:Dynamic) {
				var errorTitle:String = 'Mod name: ' + Mods.currentModDirectory;
				var errorMsg:String = 'An error occurred: $e';
				utils.system.NativeUtil.showMessageBox(errorMsg, errorTitle);
				Logs.trace('$errorTitle - $errorMsg', ERROR);
			}
		}

		selectBg = new FlxSprite().makeGraphic(1, 1);
		selectBg.alpha = 0.8;
		selectBg.visible = false;
		add(selectBg);

		icon = new FlxSprite(5, 5);
		icon.antialiasing = ClientPrefs.data.antialiasing;
		add(icon);

		text = new FlxText(95, 38, 230, "", 16);
		text.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		text.borderSize = 2;
		text.y -= Std.int(text.height / 2);
		add(text);

		var isPixel:Bool = false;
		var file:String = Paths.mods('$folder/pack.png');
		if (!FileSystem.exists(file)) {
			file = Paths.mods('$folder/pack-pixel.png');
			isPixel = true;
		}

		var bmp:BitmapData = null;
		if (FileSystem.exists(file)) bmp = BitmapData.fromFile(file);
		else isPixel = false;

		if (FileSystem.exists(file)) {
			icon.loadGraphic(Paths.cacheBitmap(file, bmp), true, 150, 150);
			if (isPixel) icon.antialiasing = false;
		} else icon.loadGraphic(Paths.image('unknownMod'), true, 150, 150);
		icon.scale.set(.5, .5);
		icon.updateHitbox();
		
		this.name = folder;
		if (pack != null) {
			if (pack.name != null) this.name = pack.name;
			if (pack.description != null) this.desc = pack.description;
			if (pack.iconFramerate != null) this.iconFps = pack.iconFramerate;
			if (pack.color != null) this.bgColor = FlxColor.fromRGB(pack.color[0] ?? 170, pack.color[1] ?? 0, pack.color[2] ?? 255);
			this.mustRestart = (pack.restart == true);
		}
		text.text = this.name;

		if (bmp != null) {
			totalFrames = Math.floor(bmp.width / 150) * Math.floor(bmp.height / 150);
			icon.animation.add("icon", [for (i in 0...totalFrames) i], iconFps);
			icon.animation.play("icon");
		}
		selectBg.scale.set(width + 5, height + 5);
		selectBg.updateHitbox();
	}
}

class MenuButton extends FlxSpriteGroup {
	public var bg:FlxSprite;
	public var textOn:Alphabet;
	public var textOff:Alphabet;
	public var icon:FlxSprite;
	public var onClick:Void->Void = null;
	public var enabled(default, set):Bool = true;
	public function new(x:Float, y:Float, width:Int, height:Int, ?text:String = null, ?img:flixel.graphics.FlxGraphic = null, onClick:Void->Void = null, animWidth:Int = 0, animHeight:Int = 0) {
		super(x, y);
		
		bg = FlxSpriteUtil.drawRoundRect(new FlxSprite().makeGraphic(width, height, FlxColor.TRANSPARENT), 0, 0, width, height, 15, 15);
		bg.color = FlxColor.BLACK;
		add(bg);

		if (text != null) {
			textOn = new Alphabet(0, 0, "", NORMAL);
			textOn.updateScale(.6, .6);
			textOn.text = text;
			textOn.alpha = 0.6;
			textOn.visible = false;
			centerOnBg(textOn);
			textOn.y -= 30;
			add(textOn);
			
			textOff = new Alphabet();
			textOff.updateScale(.52, .52);
			textOff.text = text;
			textOff.alpha = 0.6;
			centerOnBg(textOff);
			add(textOff);
		} else if (img != null) {
			icon = new FlxSprite();
			if (animWidth > 0 || animHeight > 0) icon.loadGraphic(img, true, animWidth, animHeight);
			else icon.loadGraphic(img);
			centerOnBg(icon);
			add(icon);
		}

		this.onClick = onClick;
		setButtonVisibility(false);
	}

	public var focusChangeCallback:Bool->Void = null;
	public var onFocus(default, set):Bool = false;
	public var ignoreCheck:Bool = false;
	var _needACheck:Bool = false;
	override function update(elapsed:Float) {
		super.update(elapsed);

		if (!enabled) {
			onFocus = false;
			return;
		}

		if (!ignoreCheck && FlxG.mouse.justMoved && FlxG.mouse.visible)
			onFocus = FlxG.mouse.overlaps(this);

		if (onFocus && onClick != null && FlxG.mouse.justPressed)
			onClick();

		if (_needACheck) {
			_needACheck = false;
			setButtonVisibility(FlxG.mouse.overlaps(this));
		}
	}

	function set_onFocus(newValue:Bool) {
		var lastFocus:Bool = onFocus;
		onFocus = newValue;
		if (onFocus != lastFocus && enabled) setButtonVisibility(onFocus);
		return newValue;
	}

	function set_enabled(newValue:Bool) {
		enabled = newValue;
		setButtonVisibility(false);
		alpha = enabled ? 1 : 0.4;

		_needACheck = enabled;
		return newValue;
	}

	public function setButtonVisibility(focusVal:Bool) {
		alpha = 1;
		bg.color = focusVal ? FlxColor.WHITE : FlxColor.BLACK;
		bg.alpha = focusVal ? .8 : .6;

		var focusAlpha:Float = focusVal ? 1 : .6;
		if (textOn != null && textOff != null) {
			textOn.alpha = textOff.alpha = focusAlpha;
			textOn.visible = focusVal;
			textOff.visible = !focusVal;
		} else if (icon != null) {
			icon.alpha = focusAlpha;
			icon.color = focusVal ? FlxColor.BLACK : FlxColor.WHITE;
		}

		if (!enabled) alpha = 0.4;
		if (focusChangeCallback != null) focusChangeCallback(focusVal);
	}

	public function centerOnBg(spr:FlxSprite) {
		spr.x = (bg.width - spr.width) / 2;
		spr.y = (bg.height - spr.height) / 2;
	}
}