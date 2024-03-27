package states;

import objects.AttachedSprite;
import utils.FlxInterpolateColor;

class CreditsState extends MusicBeatState {
	// Title, Variable, Description, Color
	static var titles(default, never):Array<Array<String>> = [
		['Credits Sections'],
		['Psych Engine',				'psych',			'Developers of Psych Engine',						'D662EB'],
		["Funkin' Crew",				'funkin',			'The only cool kickers of Friday Night Funkin\'',	'FD40AB'],
		["Vs Dave and Bambi Team",		'daveandbambi',		'Developers of Dave and Bambi',						'216AFF'],
		["Baby Shark\'s Big Funkin Team",	'babyshark',	'Developers of Baby Shark\'s Big Funkin',			'F8CB23'],
		['']
	];

	// Name - Icon name - Description - Link - BG Color
	static var psych(default, never):Array<Array<String>> = [
		['Psych Engine Team'],
		['Shadow Mario',		'shadowmario',		'Main Programmer and Head of Psych Engine',						'https://twitter.com/Shadow_Mario_',		'444444'],
		['Riveren',				'riveren',			'Main Artist/Animator of Psych Engine',							'https://twitter.com/riverennn',			'14967B'],
		[''],
		['Former Engine Members'],
		['bb-panzu',			'bb',				'Ex-Programmer of Psych Engine',								'https://twitter.com/bbsub3',				'3E813A'],
		['shubs', 				'', 				'Ex-Programmer of Psych Engine\nI don\'t support them.', 		'', 										'A1A1A1'],
		['Keoiki',				'keoiki',			'Ex-Artist and Note Splash Animations and Latin Alphabet', 		'https://twitter.com/Keoiki_',				'D2D2D2'],
		[''],
		['Engine Contributors'],
		['CrowPlexus', 			'crowplexus', 		'Major Help and Other PRs', 									'https://twitter.com/crowplexus', 			'A1A1A1'],
		['iFlicky',				'flicky',			'Composer of Psync and Tea Time\nMade the Dialogue Sounds',		'https://twitter.com/flicky_i',				'9E29CF'],
		['SqirraRNG',			'sqirra',			'Crash Handler and Base code for\nChart Editor\'s Waveform',	'https://twitter.com/gedehari',				'E1843A'],
		['EliteMasterEric',		'mastereric',		'Runtime Shaders support',										'https://twitter.com/EliteMasterEric',		'FFBD40'],
		['Gabriela',			'gabriela',			'Playback Rate Modifier\nand other PRs',						'https://twitter.com/BeastlyGabi',			'5E99DF'],
		['MAJigsaw77',			'jigsaw',			'MP4 Video and Discord Library (hxvlc) and hxdiscord_rpc',		'https://twitter.com/MAJigsaw77',			'FFFFFF'],
		['KadeDev',				'kade',				'Fixed Chart Editor\nand other PRs, Kade Engine Dev',			'https://twitter.com/kade0912',				'64A250'],
		['superpowers04', 		'superpowers04', 	'linc_luaJIT Fork\n and lua reworks', 							'https://github.com/superpowers04',			'B957ED'],
		['Raltyro',				'raltyro',			'Bunch of lua fixes, Owner of Psike Engine',					'https://twitter.com/raltyro',				'F3F3F3'],
		['UncertainProd',		'prod',				'Sampler2D in Runtime Shaders',									'https://github.com/UncertainProd',			'D2D2D2'],
		['ACrazyTown',			'acrazytown',		'Optimized PNGs',												'https://twitter.com/acrazytown',			'A03E3D'],
		['CheemsAndFriends', 	'face', 			'Creator of FlxAnimate\n(Icon will be added later)', 			'https://twitter.com/CheemsnFriendos', 		'A1A1A1'],
		[''],
		['Extra Keys Team'],
		['Magman03k7', 			'',					'Main Programmer of Psych Engine EK', 							'https://github.com/Magman03k7', 			'B9AF27'],
		['SrPerez', 			'perez', 			'1-9 keys art', 												'https://twitter.com/newsrperez',			'FF9E00'],
		[''],
		['Special Thanks'],
		['Denpa Engine',		'denpa',			'The Freeplay Section code used for this engine',				'https://github.com/UmbratheUmbreon/PublicDenpaEngine',			'FF9300'],
	];

	static var funkin(default, never):Array<Array<String>> = [
		["Funkin' Crew"],
		['ninjamuffin99', 		'ninjamuffin99', 	"Programmer of Friday Night Funkin'", 							'https://twitter.com/ninja_muffin99', 		'F73838'],
		['PhantomArcade',		'phantomarcade',	"Animator of Friday Night Funkin'",								'https://twitter.com/PhantomArcade3K',		'FFBB1B'],
		['evilsk8r',			'evilsk8r',			"Artist of Friday Night Funkin'",								'https://twitter.com/evilsk8r',				'53E52C'],
		['kawaisprite',			'kawaisprite',		"Composer of Friday Night Funkin'",								'https://twitter.com/kawaisprite',			'6475F3']
	];

	static var daveandbambi(default, never):Array<Array<String>> = [
		['Vs Dave and Bambi Team'],
		['MoldyGH',				'MoldyGH',			'Creator / Main Dev',				                        	'https://twitter.com/moldy_gh',		    	'FF2626'],
		['MTM101',				'MTM10',			'Secondary Dev',				                        		'https://twitter.com/OfficialMTM101',		'FF00FF'],
		['rapparep lol',      	'rapparep',			'Main Artist',				                            		'https://twitter.com/rappareplol',			'FF0000'],
		['TheBuilderXD',      	'TheBuilderXD',		'Page Manager, Tristan Sprite Creator, and more',       		'https://twitter.com/TheBuilderXD',			'CC6600'],
		['Erizur',            	'Erizur',			'Programmer, Week Icon Artist',                       			'https://twitter.com/am_erizur',			'FFFFFF'],
		['Pointy',           	'pointy',			'Artist & Charter',                           					'https://twitter.com/PointyyESM',			'0700FE'], 
		['Zmac',           		'Zmac',				'3D Backgrounds, Intro text help',                           	'https://www.youtube.com/@ZmacRavioli',		'FFFFFF'], 
		['Billy Bobbo',         'billy',			'Moral Support & Idea Suggesting',                     			'https://twitter.com/BillyBobboLOL',		'FF0000'],
		['Steph45',           	'Steph45',			'Minor programming, Moral support',                     		'https://twitter.com/Stats451',				'FFF729'],
		['T5mpler',           	'T5mpler',			'Programmer & Supporter',                           			'https://twitter.com/RealT5mpler',			'363B59'],
		[''],
		['Golden Apple'],
		['Sky!',           		'Sky',				'Creator, Charter, Composer, Artist, Programmer',               'https://twitter.com/SkyFactorial',			'5C89BF'],
		['Lancey',           	'lancey',			'Artist',               										'https://twitter.com/Lancey170',			'00FF5E'],
		['Ruby',           		'Ruby',				'Composer, Artist',               								'https://twitter.com/RubysArt_',			'5A00BD'],
	];

	static var babyshark(default, never):Array<Array<String>> = [
		['Baby Shark\'s Big Funkin Team'],
		['Altertoriel', 		'altertoriel',		'Main Developer', 													'https://twitter.com/Altertoriel2', 	'B9AF27'],
		['Pinkfong', 			'pinkfong', 		'Creator of Baby Shark', 											'https://pinkfong.com',					'F93FA2'],
		['Nickelodeon', 		'nickelodeon', 		'Creator of Baby Shark\'s Big Show / Baby Shark Ollie and William', 'https://www.nick.com',					'F57C13'],
	];

	public static var prevSelected:Int = 0;
	public var curSelected:Int = -1;

	var grpOptions:FlxTypedGroup<Alphabet>;
	var sections:Array<Array<String>> = [];

	var bg:FlxSprite;
	var descText:FlxText;
	var descBox:AttachedSprite;
	var interpColor:FlxInterpolateColor;

	final offsetThing:Float = -75;

	override function create() {
		#if DISCORD_ALLOWED DiscordClient.changePresence("In the Credits"); #end

		sections = [for (title in titles) title];

		persistentUpdate = true;
		bg = new FlxSprite(Paths.image('menuDesat'));
		add(bg);
		bg.screenCenter();
		
		add(grpOptions = new FlxTypedGroup<Alphabet>());

		#if MODS_ALLOWED
		var activeMods = Mods.getActiveModDirectories(true);
		pushModCredits();
		for (mod in activeMods) pushModCredits(mod);

		if (modCredits.length > 0) {
			sections.push(['Modpack Credits Sections']);
			modSectionsBound = sections.length;
		}
		for (mod in modCredits) sections.push(mod);
		#end

		if (curSelected > sections.length || curSelected < 0)
			curSelected = -1;

		for (i in 0...sections.length) {
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(FlxG.width / 2, 335, sections[i][0]);
			optionText.isMenuItem = true;
			optionText.changeX = false;
			optionText.targetY = i;
			optionText.alignment = CENTERED;

			optionText.distancePerItem.y /= 1.2;

			if (!isSelectable) optionText.startPosition.y -= 47;

			optionText.snapToPosition();
			grpOptions.add(optionText);

			if(isSelectable && curSelected == -1) curSelected = i;
		}

		descBox = new AttachedSprite();
		descBox.makeGraphic(1, 1, 0x99000000);
		descBox.addPoint.set(-10, -10);
		add(descBox);

		descText = new FlxText(50, FlxG.height + offsetThing - 25, 1180, "", 32);
		descText.setFormat(Paths.font("babyshark.ttf"), 32, FlxColor.WHITE, CENTER);
		descText.scrollFactor.set();
		descBox.sprTracker = descText;
		add(descText);

		interpColor = new FlxInterpolateColor(bg.color);
		changeSelection();
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float) {
		if (FlxG.sound.music.volume < .7) FlxG.sound.music.volume = FlxMath.bound(FlxG.sound.music.volume + (.5 * elapsed), 0, .7);

		if(!quitting) {
			if(sections.length > 1) {
				var shiftMult:Int = 1;
				if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

				if (controls.UI_UP_P || controls.UI_DOWN_P) {
					changeSelection(controls.UI_UP_P ? -shiftMult : shiftMult);
					holdTime = 0;
				}

				if(FlxG.mouse.wheel != 0) {
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-FlxG.mouse.wheel);
				}

				if(controls.UI_DOWN || controls.UI_UP) {
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}
			}

			interpColor.fpsLerpTo(CoolUtil.colorFromString(sections[curSelected][3]), .0625);
			bg.color = interpColor.color;

			if(controls.ACCEPT && sections[curSelected][1] != null) {
				CreditSectionState.curCSection = sections[curSelected][1];
				CreditSectionState.cSectionisMod = #if MODS_ALLOWED modSectionsBound > 0 && curSelected >= modSectionsBound #else false #end;

				prevSelected = curSelected;
				FlxG.switchState(() -> new CreditSectionState());
				quitting = true;
			}

			if (controls.BACK) {
				FlxG.sound.play(Paths.sound('cancelMenu'), .7);
				FlxG.switchState(() -> new MainMenuState());
				quitting = true;
			}
		}

		super.update(elapsed);
	}

	var moveTween:FlxTween = null;
	function changeSelection(change:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do {
			curSelected = FlxMath.wrap(curSelected + change, 0, sections.length - 1);
		} while(unselectableCheck(curSelected));

		for (num => item in grpOptions.members) {
			item.targetY = num - curSelected;
			if(!unselectableCheck(num)) item.alpha = (item.targetY == 0 ? 1 : .6);
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
			var metadata = new ModsMenuState.ModItem(folder);
			var name:String = metadata.name;
			var color:FlxColor = metadata.color;

			modCredits.push([name, folder, modDescription.replace('%s', name), color.toHexString(false, false)]);
		}
	}
	#end

	inline function unselectableCheck(num:Int):Bool return sections[num].length <= 1;
}

class CreditSectionState extends MusicBeatState {
	public static var curCSection:String = 'psych';
	public static var cSectionisMod:Bool = false;
	
	var curSelected:Int = -1;
	var prevModDir:String;

	var grpOptions:FlxTypedGroup<Alphabet>;
	var creditsStuff:Array<Array<String>> = [];

	var bg:FlxSprite;
	var descText:FlxText;
	var interpColor:FlxInterpolateColor;
	var descBox:AttachedSprite;

	final offsetThing:Float = -75;

	override function create() {
		#if DISCORD_ALLOWED DiscordClient.changePresence("In the Menus"); #end
		prevModDir = Mods.currentModDirectory;
		persistentUpdate = true;

		initializeList();
		if (cSectionisMod) Mods.currentModDirectory = curCSection;

		bg = new FlxSprite(Paths.image('menuDesat'));
		bg.screenCenter();
		add(bg);

		add(grpOptions = new FlxTypedGroup<Alphabet>());

		for (i in 0...creditsStuff.length) {
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(FlxG.width / 2, 300, creditsStuff[i][0], !isSelectable);
			optionText.isMenuItem = true;
			optionText.targetY = i;
			optionText.changeX = false;
			optionText.snapToPosition();
			grpOptions.add(optionText);

			if(isSelectable) {
				if(creditsStuff[i][5] != null)
					Mods.currentModDirectory = creditsStuff[i][5];

				var str:String = 'credits/missing_icon';
				if(creditsStuff[i][1] != null && creditsStuff[i][1].length > 0) {
					var fileName = 'credits/' + creditsStuff[i][1];
					if (Paths.fileExists('images/$fileName.png', IMAGE)) str = fileName;
					else if (Paths.fileExists('images/$fileName-pixel.png', IMAGE)) str = fileName + '-pixel';
				}

				var icon:AttachedSprite = new AttachedSprite(str);
				if(str.endsWith('-pixel')) icon.antialiasing = false;
				icon.addPoint.x = optionText.width + 10;
				icon.sprTracker = optionText;

				// using a FlxGroup is too much fuss!
				add(icon);
				Mods.currentModDirectory = cSectionisMod ? curCSection : '';

				if(curSelected == -1) curSelected = i;
			} else optionText.alignment = CENTERED;
		}

		descBox = new AttachedSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.addPoint.set(-10, -10);
		descBox.alphaMult = .6;
		descBox.alpha = .6;
		add(descBox);

		descText = new FlxText(50, FlxG.height + offsetThing - 25, 1180, "", 32);
		descText.setFormat(Paths.font("babyshark.ttf"), 32, FlxColor.WHITE, CENTER);
		descText.scrollFactor.set();
		descBox.sprTracker = descText;
		add(descText);

		interpColor = new FlxInterpolateColor(bg.color);
		changeSelection();
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float) {
		if (FlxG.sound.music.volume < .7) FlxG.sound.music.volume = .5 * elapsed;

		if(!quitting) {
			if(creditsStuff.length > 1) {
				var shiftMult:Int = 1;
				if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

				if (controls.UI_UP_P || controls.UI_DOWN_P) {
					changeSelection(controls.UI_UP_P ? -shiftMult : shiftMult);
					holdTime = 0;
				}

				if(FlxG.mouse.wheel != 0) {
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel);
				}

				if(controls.UI_DOWN || controls.UI_UP) {
					var checkLastHold:Int = Math.floor((holdTime - .5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - .5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}
			}

			interpColor.fpsLerpTo(CoolUtil.colorFromString(creditsStuff[curSelected][4]), .0625);
			bg.color = interpColor.color;

			if(controls.ACCEPT && (creditsStuff[curSelected][3] == null || creditsStuff[curSelected][3].length > 4))
				CoolUtil.browserLoad(creditsStuff[curSelected][3]);

			if(controls.BACK) {
				FlxG.sound.play(Paths.sound('cancelMenu'));
				
				var state:CreditsState = new CreditsState();
				state.curSelected = CreditsState.prevSelected;
				FlxG.switchState(() -> state);
				quitting = true;
			}
		}

		for (item in grpOptions.members) {
			if(!item.bold) {
				var lerpVal:Float = Math.exp(-elapsed * 12);
				if(item.targetY == 0) {
					var lastX:Float = item.x;
					item.screenCenter(X).x = FlxMath.lerp(item.x - 70, lastX, lerpVal);
				} else item.x = FlxMath.lerp(200 + -40 * Math.abs(item.targetY), item.x, lerpVal);
			}
		}
		super.update(elapsed);
	}

	override function destroy() {
		Mods.currentModDirectory = prevModDir;
		super.destroy();
	}

	var moveTween:FlxTween = null;
	function changeSelection(change:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'));
		do {
			curSelected = FlxMath.wrap(curSelected + change, 0, creditsStuff.length - 1);
		} while(unselectableCheck(curSelected));

		for (num => item in grpOptions.members) {
			item.targetY = num - curSelected;
			if(!unselectableCheck(num)) {
				item.alpha = 0.6;
				if (item.targetY == 0) item.alpha = 1;
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
		#if MODS_ALLOWED if (cSectionisMod) initializeModList(curCSection); #end

		if (!cSectionisMod) {
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

			for (v in field) creditsStuff.push(v);
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
		cSectionisMod = false;
	}

	inline function unselectableCheck(num:Int):Bool return creditsStuff[num].length <= 1;
}