package states;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import ui.Alphabet;
import ui.AttachedSprite;
import game.HealthIcon;
import utils.CoolUtil;

class CreditsState extends MusicBeatState
{
	// Title, Variable, Description, Color
	static var titles(default, never):Array<Array<String>> = [
		['Credits Sections'],
		['Psych Engine Team',		'psych',			'Developers of Psych Engine',						'D662EB'],
		["Funkin' Crew",			'funkin',			'The only cool kickers of Friday Night Funkin\'',	'FD40AB'],
		["Vs Dave and Bambi Team",	'daveandbambi',		'Developers of Dave and Bambi',						'FD40AB'],
		["Psych Engine Extra Keys",	'psychek',			'Developers of Psych EK',							'FD40AB'],
		['']
	];

	// Name - Icon name - Description - Link - BG Color
	static var psych(default, never):Array<Array<String>> = [
		['Psych Engine Team'],
		['Shadow Mario',		'shadowmario',		'Main Programmer of Psych Engine',								'https://twitter.com/Shadow_Mario_',		'444444'],
		['Riveren',				'riveren',			'Main Artist/Animator of Psych Engine',							'https://twitter.com/riverennn',			'B42F71'],
		[''],
		['Former Engine Members'],
		['shubs',				'shubs',			'Ex-Programmer of Psych Engine',								'https://twitter.com/yoshubs',				'5E99DF'],
		['bb-panzu',			'bb',				'Ex-Programmer of Psych Engine',								'https://twitter.com/bbsub3',				'3E813A'],
		[''],
		['Engine Contributors'],
		['iFlicky',				'flicky',			'Composer of Psync and Tea Time\nMade the Dialogue Sounds',		'https://twitter.com/flicky_i',				'9E29CF'],
		['SqirraRNG',			'sqirra',			'Crash Handler and Base code for\nChart Editor\'s Waveform',	'https://twitter.com/gedehari',				'E1843A'],
		['EliteMasterEric',		'mastereric',		'Runtime Shaders support',										'https://twitter.com/EliteMasterEric',		'FFBD40'],
		['Gabriela',			'gabriela',			'Playback Rate Modifier\nand other PRs',						'https://twitter.com/BeastlyGabi',			'5E99DF'],
		['PolybiusProxy',		'proxy',			'MP4 Video Loader Library (hxCodec)',							'https://twitter.com/polybiusproxy',		'DCD294'],
		['KadeDev',				'kade',				'Fixed some cool stuff on Chart Editor\nand other PRs',			'https://twitter.com/kade0912',				'64A250'],
		['Keoiki',				'keoiki',			'Note Splash Animations and Latin Alphabet',					'https://twitter.com/Keoiki_',				'D2D2D2'],
		['superpowers04', 		'superpowers04', 	'linc_luaJIT Fork\n and lua reworks', 							'https://github.com/superpowers04',			'B957ED'],
		['Smokey',				'smokey',			'Sprite Atlas Support',											'https://twitter.com/Smokey_5_',			'483D92'],
		['Raltyro',				'raltyro',			'Bunch of lua fixes, Owner of Psike Engine',					'https://twitter.com/raltyro',				'F3F3F3'],
		['UncertainProd',		'prod',				'Sampler2D in Runtime Shaders',									'https://github.com/UncertainProd',			'D2D2D2'],
		['ACrazyTown',			'acrazytown',		'Optimized PNGs',												'https://twitter.com/acrazytown',			'A03E3D'],
	];

	static var funkin(default, never):Array<Array<String>> = [
		["Funkin' Crew"],
		['ninjamuffin99',		'ninjamuffin99',	"Programmer of Friday Night Funkin'",							'https://twitter.com/ninja_muffin99',		'F73838'],
		['PhantomArcade',		'phantomarcade',	"Animator of Friday Night Funkin'",								'https://twitter.com/PhantomArcade3K',		'FFBB1B'],
		['evilsk8r',			'evilsk8r',			"Artist of Friday Night Funkin'",								'https://twitter.com/evilsk8r',				'53E52C'],
		['kawaisprite',			'kawaisprite',		"Composer of Friday Night Funkin'",								'https://twitter.com/kawaisprite',			'6475F3']
	];

	static var daveandbambi(default, never):Array<Array<String>> = [
		['Vs Dave and Bambi Team'],
		['MoldyGH',				'MoldyGH',			'Creator / Main Dev',				                        	'https://twitter.com/moldy_gh',		    	'FF0000'],
		['MTM101',				'MTM10',			'Secondary Dev',				                        		'https://twitter.com/OfficialMTM101',		'FF0000'],
		['rapparep lol',      	'rapparep',			'Main Artist',				                            		'https://twitter.com/rappareplol',			'FF0000'],
		['TheBuilderXD',      	'TheBuilderXD',		'Page Manager, Tristan Sprite Creator, and more',       		'https://twitter.com/TheBuilderXD',			'FF0000'],
		['Erizur',            	'Erizur',			'Programmer, Week Icon Artist',                       			'https://twitter.com/am_erizur',			'FF0000'],
		['Pointy',           	'pointy',			'Artist & Charter',                           					'https://twitter.com/PointyyESM',			'FF0000'], 
		['Zmac',           		'Zmac',				'3D Backgrounds, Intro text help',                           	'',											'FF0000'], 
		['Billy Bobbo',         'billy',			'Moral Support & Idea Suggesting',                     			'https://twitter.com/BillyBobboLOL',		'FF0000'],
		['Steph45',           	'Steph45',			'Minor programming, Moral support',                     		'https://twitter.com/Stats451',				'FF0000'],
		['T5mpler',           	'T5mpler',			'Former Programmer & Supporter',                           		'https://twitter.com/RealT5mpler',			'FF0000']
	];

	static var psychek(default, never):Array<Array<String>> = [
		['Psych Engine Extra Keys'],
		['tposejank', 			'tposejank',		'Main Programmer of Psych Engine EK', 							'https://twitter.com/tpose_jank', 			'B9AF27'],
		['srPerez', 			'perez', 			'1-9 keys art', 												'https://twitter.com/newsrperez',			'FF9E00'],
		['Leather128', 			'leather', 			'12 - 16 keys art + coder', 									'https://twitter.com/newsrperez',			'FF9E00'],
	];

	public static var prevSelected:Int = 0;
	public var curSelected:Int = -1;

	var grpOptions:FlxTypedGroup<Alphabet>;
	var sections:Array<Array<String>> = [];

	var bg:FlxSprite;
	var descText:FlxText;
	var descBox:AttachedSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	var offsetThing:Float = -75;

	override function create() {
		#if discord_rpc
		Discord.changePresence("In the Credits", null);
		#end

		sections = [for (title in titles) title];

		persistentUpdate = true;
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);
		bg.screenCenter();
		
		add(grpOptions = new FlxTypedGroup<Alphabet>());

		#if MODS_ALLOWED
		var activeMods = Mods.getActiveModDirectories(true);
		pushModCredits();
		for (mod in activeMods)
			pushModCredits(mod);

		if (modCredits.length > 0) {
			sections.push(['Modpack Credits Sections']);
			modSectionsBound = sections.length;
		}
		for (mod in modCredits)
			sections.push(mod);
		#end

		if (curSelected > sections.length || curSelected < 0)
			curSelected = -1;

		for (i in 0...sections.length)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(FlxG.width / 2, 335, sections[i][0], true);
			optionText.isMenuItem = true;
			optionText.changeX = false;
			optionText.targetY = i;
			optionText.alignment = CENTERED;

			optionText.distancePerItem.y /= 1.2;

			if (!isSelectable)
				optionText.startPosition.y -= 47;

			optionText.snapToPosition();
			grpOptions.add(optionText);

			if(isSelectable && curSelected == -1)
				curSelected = i;
		}

		descBox = new AttachedSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.addPoint.set(-10, -10);
		descBox.alphaMult = 0.6;
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, FlxG.height + offsetThing - 25, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		descText.scrollFactor.set();
		descBox.sprTracker = descText;
		add(descText);

		bg.color = CoolUtil.colorFromString(sections[curSelected][4]);
		intendedColor = bg.color;
		changeSelection();
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume = FlxMath.bound(FlxG.sound.music.volume + (.5 * elapsed), 0, .7);

		if(!quitting)
		{
			if(sections.length > 1)
			{
				var shiftMult:Int = 1;
				if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

				var upP = controls.UI_UP_P;
				var downP = controls.UI_DOWN_P;

				if (upP) {
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (downP) {
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}
			}

			if(controls.ACCEPT && sections[curSelected][1] != null) {
				if(colorTween != null) colorTween.cancel();

				CreditSectionState.curCSection = sections[curSelected][1];

				#if MODS_ALLOWED
				CreditSectionState.CSectionisMod = modSectionsBound > 0 && curSelected >= modSectionsBound;
				#else
				CreditSectionState.CSectionisMod = false;
				#end

				prevSelected = curSelected;
				MusicBeatState.switchState(new CreditSectionState());
				quitting = true;
			}

			if (controls.BACK)
			{
				if(colorTween != null) colorTween.cancel();
				FlxG.sound.play(Paths.sound('cancelMenu'), .7);
				MusicBeatState.switchState(new MainMenuState());
				quitting = true;
			}
		}

		super.update(elapsed);
	}

	var moveTween:FlxTween = null;
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do {
			curSelected = FlxMath.wrap(curSelected + change, 0, sections.length - 1);
		} while(unselectableCheck(curSelected));

		var newColor:Int = CoolUtil.colorFromString(sections[curSelected][4]);
		if(newColor != intendedColor) {
			if (colorTween != null) colorTween.cancel();
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		var bullShit:Int = 0;
		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit - 1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
				}
			}
		}

		descText.text = sections[curSelected][2];
		descText.y = FlxG.height - descText.height + offsetThing - 30;

		if(moveTween != null) moveTween.cancel();
		moveTween = FlxTween.tween(descText, {y : descText.y + 45}, 0.25, {ease: FlxEase.sineOut});

		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
	}

	#if MODS_ALLOWED
	static var modDescription = 'Credits Section for the mod "%s"';
	var modSectionsBound:Int = -1;

	var modCredits:Array<Array<String>> = [];
	function pushModCredits(?folder:String = null):Void {
		var creditsFile:String = Paths.mods((folder != null ? '$folder/' : '') + 'data/credits.txt');
		if (!FileSystem.exists(creditsFile)) return;

		var arr:Array<String> = File.getContent(creditsFile).split('\n');
		if (arr.length > 0) {
			var metadata = new ModsMenuState.ModMetadata(folder);
			var name:String = metadata.name;
			var color:FlxColor = metadata.color;

			modCredits.push([name, folder, modDescription.replace('%s', name), color.toHexString(false, false)]);
		}
	}
	#end

	function unselectableCheck(num:Int):Bool {
		return sections[num].length <= 1;
	}
}

class CreditSectionState extends MusicBeatState {
	public static var curCSection:String = 'psych';
	public static var CSectionisMod:Bool = false;
	
	var curSelected:Int = -1;
	var prevModDir:String;

	var grpOptions:FlxTypedGroup<Alphabet>;
	var creditsStuff:Array<Array<String>> = [];

	var bg:FlxSprite;
	var descText:FlxText;
	var intendedColor:Int;
	var colorTween:FlxTween;
	var descBox:AttachedSprite;

	final offsetThing:Float = -75;

	override function create()
	{
		#if discord_rpc
		Discord.changePresence("In the Menus", null);
		#end
		prevModDir = Mods.currentModDirectory;
		persistentUpdate = true;

		initializeList();
		if (CSectionisMod) Mods.currentModDirectory = curCSection;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.screenCenter();
		add(bg);

		add(grpOptions = new FlxTypedGroup<Alphabet>());

		var prefix:String = CSectionisMod ? '' : curCSection + '/';
		for (i in 0...creditsStuff.length)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(FlxG.width / 2, 300, creditsStuff[i][0], !isSelectable);
			optionText.isMenuItem = true;
			optionText.targetY = i;
			optionText.changeX = false;
			optionText.distancePerItem.y /= 1.1;
			grpOptions.add(optionText);

			if(isSelectable) {
				if(creditsStuff[i][5] != null)
					Mods.currentModDirectory = creditsStuff[i][5];

				var icon:HealthIcon = new HealthIcon(false, true);
				if (!icon.changeIcon(creditsStuff[i][1], curCSection, false))
					icon.changeIcon(creditsStuff[i][1], getSimilarIcon(creditsStuff[i][1]));

				icon.iconType = 'center';
				icon.offset.y = -30;
				icon.updateHitbox();
				icon.sprTracker = optionText;
				icon.ID = i;

				// using a FlxGroup is too much fuss!
				add(icon);
				Mods.currentModDirectory = CSectionisMod ? curCSection : '';

				if(curSelected == -1) curSelected = i;
			} else {
				optionText.startPosition.y -= 28;
				optionText.alignment = CENTERED;
			}
			optionText.snapToPosition();
		}

		descBox = new AttachedSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.addPoint.set(-10, -10);
		descBox.alphaMult = 0.6;
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, FlxG.height + offsetThing - 25, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER/*, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK*/);
		descText.scrollFactor.set();
		descBox.sprTracker = descText;
		add(descText);

		bg.color = CoolUtil.colorFromString(creditsStuff[curSelected][4]);
		intendedColor = bg.color;
		changeSelection();
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume = FlxMath.bound(FlxG.sound.music.volume + (.5 * elapsed), 0, .7);

		if(!quitting)
		{
			if(creditsStuff.length > 1)
			{
				var shiftMult:Int = 1;
				if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

				var upP = controls.UI_UP_P;
				var downP = controls.UI_DOWN_P;

				if (upP) {
					changeSelection(-shiftMult);
					holdTime = 0;
				}

				if (downP) {
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP) {
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}
				}
			}

			if(controls.ACCEPT && (creditsStuff[curSelected][3] == null || creditsStuff[curSelected][3].length > 4)) {
				CoolUtil.browserLoad(creditsStuff[curSelected][3]);
			}

			if(controls.BACK) {
				if(colorTween != null) colorTween.cancel();
				FlxG.sound.play(Paths.sound('cancelMenu'));
				
				var state:CreditsState = new CreditsState();
				state.curSelected = CreditsState.prevSelected;
				MusicBeatState.switchState(state);
				quitting = true;
			}
		}

		for (item in grpOptions.members) {
			if(!item.bold) {
				var lerpVal:Float = FlxMath.bound(elapsed * 12, 0, 1);
				if(item.targetY == 0) {
					var lastX:Float = item.x;
					item.screenCenter(X);
					item.x = FlxMath.lerp(lastX, item.x - 70, lerpVal);
				} else item.x = FlxMath.lerp(item.x, 200 + -40 * Math.abs(item.targetY), lerpVal);
			}
		}
		super.update(elapsed);
	}

	override function destroy() {
		Mods.currentModDirectory = prevModDir;
		super.destroy();
	}

	var moveTween:FlxTween = null;
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		do {
			curSelected = FlxMath.wrap(curSelected + change, 0, creditsStuff.length - 1);
		} while(unselectableCheck(curSelected));

		var newColor:Int = CoolUtil.colorFromString(creditsStuff[curSelected][4]);
		if(newColor != intendedColor) {
			if(colorTween != null) colorTween.cancel();
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
				}
			}
		}

		descText.text = creditsStuff[curSelected][2];
		descText.y = FlxG.height - descText.height + offsetThing - 30;

		if(moveTween != null) moveTween.cancel();
		moveTween = FlxTween.tween(descText, {y : descText.y + 45}, 0.25, {ease: FlxEase.sineOut});

		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
	}

	function initializeList() {
		#if MODS_ALLOWED
		if (CSectionisMod) initializeModList(curCSection);
		#end

		if (!CSectionisMod) {
			var dyn:Dynamic = Reflect.field(CreditsState, curCSection);
			var field:Array<Array<String>> = null;
			if (Std.isOfType(dyn, Array)) {
				field = cast dyn;
				if (field == null || field.length <= 0 || !Std.isOfType(field[0], Array) || !Std.isOfType(field[0][0], String))
					field = null;
			}

			if (field == null || field.length <= 0) {
				switchToDefaultSection();
				field = cast Reflect.field(CreditsState, curCSection);
			}

			for (v in field)
				creditsStuff.push(v);
		}
	}

	#if MODS_ALLOWED
	function initializeModList(?folder:String = null) {
		var creditsFile:String = Paths.mods((folder != null ? folder + '/' : '') + 'data/credits.txt');
		if (!FileSystem.exists(creditsFile)) return switchToDefaultSection();

		var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
		for (v in firstarray) {
			var arr:Array<String> = v.replace('\\n', '\n').split("::");
			if(arr.length >= 5) arr.push(folder);
			creditsStuff.push(arr);
		}
		if (creditsStuff.length <= 0) return switchToDefaultSection();
	}
	#end

	function switchToDefaultSection() {
		curCSection = 'psych';
		CSectionisMod = false;
	}

	function getSimilarIcon(icon:String):String {
		@:privateAccess var titles = CreditsState.titles;

		var section:Array<String>;
		var v:String;
		for (i in 0...titles.length) {
			section = titles[i];
			if (section.length <= 1 || section[1] == 'mod') continue;

			v = section[1];

			var dyn:Dynamic = Reflect.field(CreditsState, v);
			var field:Array<Array<String>> = null;
			if (Std.isOfType(dyn, Array)) {
				field = cast dyn;
				if (field == null || field.length <= 0 || !Std.isOfType(field[0], Array) || !Std.isOfType(field[0][0], String))
					field = null;
			}
			if (field == null || field.length <= 0) continue;

			for (i in 0...field.length)
				if (icon == field[i][1] && HealthIcon.returnGraphic(icon, v, false, true) != null) return v;
		}

		return null;
	}

	function unselectableCheck(num:Int):Bool {
		return creditsStuff[num].length <= 1;
	}
}