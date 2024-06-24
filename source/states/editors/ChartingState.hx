package states.editors;

import objects.HealthIcon;
import objects.StrumNote;
import objects.Note;
import objects.Character;
import objects.AttachedSprite;
import objects.AttachedFlxText;
import backend.Song;
import utils.MathUtil;
import substates.Prompt;

import flixel.FlxObject;
import flixel.addons.display.FlxGridOverlay;
import flixel.util.FlxSort;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import openfl.geom.Rectangle;
import lime.media.AudioBuffer;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.Json;

@:access(openfl.media.Sound.__buffer)
@:access(flixel.sound.FlxSound._sound)
class ChartingState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent {
	public static var noteTypeList:Array<String> = [ //Used for backwards compatibility with 0.1 - 0.3.2 charts, though, you should add your hardcoded custom note types here too.
		'',
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];
	public var ignoreWarnings = false;
	var curNoteTypes:Array<String> = [];
	var eventStuff:Array<Dynamic> = [
		['', "Nothing. Yep, that's right."],
		['Dadbattle Spotlight', "Used in Dad Battle,\nValue 1: 0/1 = ON/OFF,\n2 = Target Dad\n3 = Target BF"],
		['Hey!', "Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s"],
		['Set GF Speed', "Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"],
		['Philly Glow', "Exclusive to Week 3\nValue 1: 0/1/2 = OFF/ON/Reset Gradient\n \nNo, i won't add it to other weeks."],
		['Kill Henchmen', "For Mom's songs, don't use this please, i love them :("],
		['Add Camera Zoom', "Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default."],
		['Set Camera Zoom', "Used to set the default camera zoom to a constant value\nValue 1: Camera zoom set (Default: 1.05)\nValue 2: UI zoom set (Default: 1)\nLeave the values blank if you want to use Default."],
		['Play Animation', "Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"],
		['Camera Follow Pos', "Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."],
		['Alt Idle Animation', "Sets a specified postfix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New suffix (Leave it blank to disable)"],
		['Screen Shake', "Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."],
		['Change Character', "Value 1: Character to change (Dad, BF, GF)\nValue 2: New character's name"],
		['Change Scroll Speed', "Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."],
		['Set Property', "Value 1: Variable name\nValue 2: New value\n\nIf the Value is boolean add ', bool' in Value 1\nExample: boyfriend.visible, bool"],
		['Play Sound', "Value 1: Sound file name\nValue 2: Volume (Default: 1), ranges from 0 to 1"],
	];

	var _file:FileReference;
	var UI_box:PsychUIBox;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	*/
	public static var curSec:Int = 0;
	static var lastSong:String = '';

	public var zoomFactorTxt:String = "1 / 1";

	var bpmTxt:FlxText;
	var camPos:FlxObject;
	var strumLine:FlxSprite;
	var quant:AttachedSprite;
	var strumLineNotes:FlxTypedGroup<StrumNote>;

	public static var GRID_SIZE:Int = 40;
	final CAM_OFFSET:Int = 360;

	var dummyArrow:FlxSprite;

	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedNoteType:FlxTypedGroup<FlxText>;

	var nextRenderedSustains:FlxTypedGroup<FlxSprite>;
	var nextRenderedNotes:FlxTypedGroup<Note>;

	var gridBG:FlxSprite;
	var nextGridBG:FlxSprite;

	var curEventSelected:Int = 0;
	var _song:SwagSong;
	/**
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic> = null;

	var playbackSpeed:Float = 1;

	var lastNoteData:Float;
	var lastNoteStrum:Float;

	var vocals:FlxSound = null;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	var value1InputText:PsychUIInputText;
	var value2InputText:PsychUIInputText;

	var currentSongName:String;

	final zoomList:Array<Float> = [.25, .5, 1, 2, 3, 4, 6, 8, 12, 16, 24];
	var curZoom:Int = 2;

	var waveformSprite:FlxSprite;
	var gridLayer:FlxTypedGroup<FlxSprite>;

	var helpBg:FlxSprite;
	var helpTexts:FlxSpriteGroup;

	public static var quantization:Int = 16;
	public static var curQuant = 3;

	var quantizations:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];

	public static var vortex:Bool = false;
	var mouseQuant:Bool = false;
	override function create() {
		Paths.clearUnusedMemory();

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else {
			Difficulty.resetList();

			_song = {
				song: 'Tutorial',
				notes: [],
				events: [],
				bpm: 100.,
				needsVoices: true,
				player1: 'bf',
				player2: 'gf',
				gfVersion: 'gf',
				speed: 1,
				stage: 'stage',
				mania: EK.defaultMania
			};
			addSection();
			PlayState.SONG = _song;
		}
		if (_song.mania == null || (_song.mania < EK.minMania || _song.mania > EK.maxMania)) _song.mania = EK.defaultMania;
		PlayState.mania = _song.mania;

		#if DISCORD_ALLOWED DiscordClient.changePresence("Chart Editor", _song.song.replace('-', ' ')); #end

		vortex = FlxG.save.data.chart_vortex;
		ignoreWarnings = FlxG.save.data.ignoreWarnings;
		var bg:FlxSprite = new FlxSprite(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set();
		bg.color = 0xFF222222;
		add(bg);

		add(gridLayer = new FlxTypedGroup<FlxSprite>());

		waveformSprite = new FlxSprite(GRID_SIZE).makeGraphic(1, 1, FlxColor.BLACK);
		waveformSprite.antialiasing = false;
		add(waveformSprite);

		var eventIcon:FlxSprite = new FlxSprite(-GRID_SIZE - 5, -90, Paths.image('eventArrow'));
		leftIcon = new HealthIcon('bf');
		rightIcon = new HealthIcon('dad');

		eventIcon.scrollFactor.set(1, 1);
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		eventIcon.setGraphicSize(30, 30);
		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		add(eventIcon);
		add(leftIcon);
		add(rightIcon);

		reloadIconPosition();

		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedNoteType = new FlxTypedGroup<FlxText>();

		nextRenderedSustains = new FlxTypedGroup<FlxSprite>();
		nextRenderedNotes = new FlxTypedGroup<Note>();

		FlxG.mouse.visible = true;

		updateJsonData();
		currentSongName = Paths.formatToSongPath(_song.song);
		loadSong();
		reloadGridLayer();
		Conductor.bpm = _song.bpm;
		Conductor.mapBPMChanges(_song);
		if(curSec >= _song.notes.length) curSec = _song.notes.length - 1;

		bpmTxt = new FlxText(1060, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		for (i in 0...EK.strums(_song.mania)) {
			var note:StrumNote = new StrumNote(GRID_SIZE * (i + 1), strumLine.y, i % EK.keys(_song.mania), 0);
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.playAnim('static', true);
			strumLineNotes.add(note);
			note.scrollFactor.set(1, 1);
		}
		add(strumLineNotes);

		camPos = new FlxObject(0, 0, 1, 1);
		camPos.setPosition(strumLine.x + CAM_OFFSET, strumLine.y);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		dummyArrow.antialiasing = ClientPrefs.data.antialiasing;
		add(dummyArrow);

		UI_box = new PsychUIBox(640 + GRID_SIZE * 3, 25, 300, 400, ['Charting', 'Data', 'Events', 'Note', 'Section', 'Song']);
		UI_box.selectedName = 'Song';
		UI_box.scrollFactor.set();

		var tipText:FlxText = new FlxText(FlxG.width - 200, FlxG.height - 32, 200, "Press F1 for Help", 16);
		tipText.setFormat(null, 16, FlxColor.WHITE);
		tipText.setBorderStyle(OUTLINE_FAST, FlxColor.BLACK);
		tipText.scrollFactor.set();
		tipText.active = false;
		add(tipText);
		add(UI_box);

		helpBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		helpBg.scrollFactor.set();
		helpBg.scale.set(FlxG.width, FlxG.height);
		helpBg.updateHitbox();
		helpBg.alpha = 0.6;
		helpBg.active = helpBg.visible = false;

		var str:Array<String> = [
			"W/S or Mouse Wheel - Change Conductor's strum time",
			"H - Go to the start of the chart",
			"A/D - Go to the previous/next section",
			"Left/Right - Change Snap",
			"Up/Down - Change Conductor's Strum Time with Snapping",
			"",
			"Brackets - Change Song Playback Rate (SHIFT to go Faster)",
			"ALT + Brackets - Reset Song Playback Rate",
			"",
			"Hold Shift - Move 4x faster Conductor's strum time",
			"Hold Control + click on an arrow - Select it",
			"Z/X - Zoom in/out",
			"",
			"Hold Right Mouse - Placing Notes by dragging mouse",
			"Esc - Test your chart inside Chart Editor",
			"Enter - Play your chart",
			"Q/E - Decrease/Increase Note Sustain Length",
			"Space - Stop/Resume song",
			"Hold Ctrl and Click - Place Both Notes",
		];

		helpTexts = new FlxSpriteGroup();
		helpTexts.scrollFactor.set();
		for (i => txt in str) {
			if(txt.length < 1) continue;
	
			var helpText:FlxText = new FlxText(0, 0, 720, txt, 16);
			helpText.setFormat(null, 16, FlxColor.WHITE, CENTER, FlxColor.BLACK);
			helpText.setBorderStyle(OUTLINE_FAST, FlxColor.BLACK);
			helpText.screenCenter();
			add(helpText);
			helpText.y += ((i - str.length / 2) * 32) + 16;
			helpText.active = false;
			helpTexts.add(helpText);
		}
		helpTexts.active = helpTexts.visible = false;

		addSongUI();
		addSectionUI();
		addNoteUI();
		addEventsUI();
		addChartingUI();
		addDataUI();
		updateHeads();
		updateWaveform();

		add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedNoteType);
		add(nextRenderedSustains);
		add(nextRenderedNotes);

		if(lastSong != currentSongName) changeSection();
		lastSong = currentSongName;

		add(helpBg);
		add(helpTexts);
		updateGrid();
		super.create();
	}

	var check_mute_inst:PsychUICheckBox = null;
	var check_mute_vocals:PsychUICheckBox = null;
	var check_vortex:PsychUICheckBox = null;
	var check_warnings:PsychUICheckBox = null;
	var playSoundBf:PsychUICheckBox = null;
	var playSoundDad:PsychUICheckBox = null;
	var UI_songTitle:PsychUIInputText;
	var stageDropDown:PsychUIDropDownMenu;
	var difficultyDropDown:PsychUIDropDownMenu;
	var sliderRate:PsychUISlider;
	function addSongUI():Void {
		UI_songTitle = new PsychUIInputText(10, 10, 70, _song.song, 8);

		var check_voices = new PsychUICheckBox(10, 30, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		check_voices.onClick = () -> _song.needsVoices = check_voices.checked;

		var saveButton:PsychUIButton = new PsychUIButton(110, 8, "Save", () -> saveLevel());

		var reloadSong:PsychUIButton = new PsychUIButton(saveButton.x + 90, saveButton.y, "Reload Audio", () -> {
			currentSongName = Paths.formatToSongPath(UI_songTitle.text);
			updateJsonData();
			loadSong();
			updateWaveform();
		});

		var reloadSongJson:PsychUIButton = new PsychUIButton(reloadSong.x, saveButton.y + 30, "Reload JSON", () -> openSubState(new Prompt('This action will clear current progress.\n\nProceed?', () -> loadJson(_song.song.toLowerCase()), null, ignoreWarnings)));

		var loadAutosaveBtn:PsychUIButton = new PsychUIButton(reloadSongJson.x, reloadSongJson.y + 30, 'Load Autosave', () -> {
			PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
			FlxG.resetState();
		});

		var loadEventJson:PsychUIButton = new PsychUIButton(loadAutosaveBtn.x, loadAutosaveBtn.y + 30, 'Load Events', () -> {
			var songName:String = Paths.formatToSongPath(_song.song);
			final eventPath:String = '${Paths.CHART_PATH}/$songName/events';
			var file:String = Paths.json(eventPath);
			#if sys
			if (#if MODS_ALLOWED FileSystem.exists(Paths.modsJson(eventPath)) || #end FileSystem.exists(file))
			#else
			if (Assets.exists(file))
			#end
			{
				clearEvents();
				var events:SwagSong = Song.loadFromJson('events', songName);
				_song.events = events.events;
				changeSection(curSec);
			}
		});

		var saveEvents:PsychUIButton = new PsychUIButton(110, reloadSongJson.y, 'Save Events', () -> saveEvents());
		var clear_events:PsychUIButton = new PsychUIButton(320, 310, 'Clear events', () -> openSubState(new Prompt('This action will clear current progress.\n\nProceed?', clearEvents, null, ignoreWarnings)));
		clear_events.normalStyle.bgColor = FlxColor.RED;
		clear_events.normalStyle.textColor = FlxColor.WHITE;

		var clear_notes:PsychUIButton = new PsychUIButton(320, clear_events.y + 30, 'Clear notes', () -> openSubState(new Prompt('This action will clear current progress.\n\nProceed?', () -> {
			for (sec in 0..._song.notes.length) _song.notes[sec].sectionNotes = [];
			updateGrid();
		}, null, ignoreWarnings)));
		clear_notes.normalStyle.bgColor = FlxColor.RED;
		clear_notes.normalStyle.textColor = FlxColor.WHITE;

		var stepperBPM:PsychUINumericStepper = new PsychUINumericStepper(10, 70, 1, 1, 1, 999999, 3);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';

		var stepperSpeed:PsychUINumericStepper = new PsychUINumericStepper(10, stepperBPM.y + 35, 0.1, 1, 0.1, 100, 2);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';

		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods('characters/'), Paths.mods(Mods.currentModDirectory + '/characters/'), Paths.getSharedPath('characters/')];
		for(mod in Mods.getGlobalMods()) directories.push(Paths.mods('$mod/characters/'));
		#else
		var directories:Array<String> = [Paths.getSharedPath('characters/')];
		#end

		var tempArray:Array<String> = [];
		var characters:Array<String> = Mods.mergeAllTextsNamed('data/characterList.txt');
		for (character in characters) if(character.trim().length > 0) tempArray.push(character);

		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					if (!FileSystem.isDirectory(Path.join([directory, file])) && file.endsWith('.json')) {
						var charToCheck:String = file.substr(0, file.length - 5);
						if(charToCheck.trim().length > 0 && !charToCheck.endsWith('-dead') && !tempArray.contains(charToCheck)) {
							tempArray.push(charToCheck);
							characters.push(charToCheck);
						}
					}
				}
			}
		}
		#end
		tempArray = [];

		var player1DropDown = new PsychUIDropDownMenu(10, stepperSpeed.y + 45, characters, function(id:Int, character:String) {
			_song.player1 = character;
			updateJsonData();
			updateHeads();
		});
		player1DropDown.selectedLabel = _song.player1;

		var gfVersionDropDown = new PsychUIDropDownMenu(player1DropDown.x, player1DropDown.y + 40, characters, function(id:Int, character:String) {
			_song.gfVersion = character;
			updateJsonData();
			updateHeads();
		});
		gfVersionDropDown.selectedLabel = _song.gfVersion;
		var player2DropDown = new PsychUIDropDownMenu(player1DropDown.x, gfVersionDropDown.y + 40, characters, function(id:Int, character:String) {
			_song.player2 = character;
			updateJsonData();
			updateHeads();
		});
		player2DropDown.selectedLabel = _song.player2;

		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods('stages/'), Paths.mods(Mods.currentModDirectory + '/stages/'), Paths.getSharedPath('stages/')];
		for(mod in Mods.getGlobalMods()) directories.push(Paths.mods('$mod/stages/'));
		#else
		var directories:Array<String> = [Paths.getSharedPath('stages/')];
		#end

		var stages:Array<String> = [];
		for (stage in Mods.mergeAllTextsNamed('data/stageList.txt')) {
			if(stage.trim().length > 0) stages.push(stage);
			tempArray.push(stage);
		}
		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					if (!FileSystem.isDirectory(Path.join([directory, file])) && file.endsWith('.json')) {
						var stageToCheck:String = file.substr(0, file.length - 5);
						if(stageToCheck.trim().length > 0 && !tempArray.contains(stageToCheck)) {
							tempArray.push(stageToCheck);
							stages.push(stageToCheck);
						}
					}
				}
			}
		}
		#end
		tempArray = [];
		
		if(stages.length < 1) stages.push('stage');

		stageDropDown = new PsychUIDropDownMenu(player1DropDown.x + 140, player1DropDown.y, stages, (id:Int, stage:String) -> _song.stage = stage);
		stageDropDown.selectedLabel = _song.stage;

		var availableDifficulties:Array<Int> = [];
		var availableDifficultiesTexts:Array<String> = [];
		for(i in 0...Difficulty.list.length) {
			var curDifficulty:String = Difficulty.list[i];
			var jsonInput:String;
			if(curDifficulty.toLowerCase() == 'normal') jsonInput = _song.song.toLowerCase();
			else jsonInput = '${_song.song.toLowerCase()}-$curDifficulty';

			var formattedFolder:String = Paths.formatToSongPath(_song.song.toLowerCase());
			var formattedSong:String = Paths.formatToSongPath(jsonInput);

			if(Paths.fileExists('data/${Paths.CHART_PATH}/$formattedFolder/$formattedSong.json', BINARY)) {
				availableDifficulties.push(i);
				availableDifficultiesTexts.push(curDifficulty);
			}
		}

		if(availableDifficulties == null || availableDifficulties.length <= 0) {
			availableDifficulties.push(PlayState.storyDifficulty);
			availableDifficultiesTexts.push(Difficulty.list[0]);
		}

		difficultyDropDown = new PsychUIDropDownMenu(stageDropDown.x, gfVersionDropDown.y, availableDifficultiesTexts, function(id:Int, difficulty:String) {
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', () -> {
				PlayState.storyDifficulty = id;
				PlayState.changedDifficulty = true;
				loadJson(currentSongName.toLowerCase());
			}, null, ignoreWarnings));
		});

		var stepperMania:PsychUINumericStepper = new PsychUINumericStepper(100, stepperSpeed.y, 1, 3, EK.minMania, EK.maxMania, 1);
		stepperMania.value = _song.mania;
		stepperMania.name = 'song_mania';

		var tab_group_song:FlxSpriteGroup = UI_box.getTab('Song').menu;
		tab_group_song.add(UI_songTitle);
		tab_group_song.add(check_voices);
		tab_group_song.add(clear_events);
		tab_group_song.add(clear_notes);
		tab_group_song.add(saveButton);
		tab_group_song.add(saveEvents);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(loadEventJson);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(stepperMania);
		tab_group_song.add(new FlxText(stepperBPM.x, stepperBPM.y - 15, 0, 'Song BPM:'));
		tab_group_song.add(new FlxText(stepperSpeed.x, stepperSpeed.y - 15, 0, 'Song Speed:'));
		tab_group_song.add(new FlxText(stepperMania.x, stepperMania.y - 15, 0, 'Mania:'));
		tab_group_song.add(new FlxText(player2DropDown.x, player2DropDown.y - 15, 0, '(P2) Opponent:'));
		tab_group_song.add(new FlxText(gfVersionDropDown.x, gfVersionDropDown.y - 15, 0, '(P3) GF:'));
		tab_group_song.add(new FlxText(player1DropDown.x, player1DropDown.y - 15, 0, '(P1) BF:'));
		tab_group_song.add(new FlxText(difficultyDropDown.x, difficultyDropDown.y - 15, 0, 'Difficulty:'));
		tab_group_song.add(new FlxText(stageDropDown.x, stageDropDown.y - 15, 0, 'Stage:'));
		tab_group_song.add(player2DropDown);
		tab_group_song.add(gfVersionDropDown);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(difficultyDropDown);
		tab_group_song.add(stageDropDown);

		initPsychCamera().follow(camPos, LOCKON, 999);
	}

	var stepperBeats:PsychUINumericStepper;
	var check_mustHitSection:PsychUICheckBox;
	var check_gfSection:PsychUICheckBox;
	var check_changeBPM:PsychUICheckBox;
	var stepperSectionBPM:PsychUINumericStepper;
	var check_altAnim:PsychUICheckBox;
	var sectionSelectedDropDown:PsychUIDropDownMenu;
	var currentSectionSelected:Int = 0;

	var sectionToCopy:Int = 0;
	var notesCopied:Array<Dynamic>;

	function addSectionUI():Void {
		var tab_group_section:FlxSpriteGroup = UI_box.getTab('Section').menu;

		check_mustHitSection = new PsychUICheckBox(10, 15, "Must hit section", 100, () -> {
			_song.notes[curSec].mustHitSection = check_mustHitSection.checked;

			updateGrid();
			updateHeads();
		});
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = _song.notes[curSec].mustHitSection;

		check_gfSection = new PsychUICheckBox(10, check_mustHitSection.y + 22, "GF section", 100, () -> {
			_song.notes[curSec].gfSection = check_gfSection.checked;

			updateGrid();
			updateHeads();
		});
		check_gfSection.checked = _song.notes[curSec].gfSection;
		check_gfSection.name = 'check_gf';

		check_altAnim = new PsychUICheckBox(check_gfSection.x + 120, check_gfSection.y, "Alt Animation", 100, () -> _song.notes[curSec].altAnim = check_altAnim.checked);
		check_altAnim.checked = _song.notes[curSec].altAnim;
		check_altAnim.name = 'check_altAnim';

		stepperBeats = new PsychUINumericStepper(10, 100, 1, 4, 1, 7, 2);
		stepperBeats.value = getSectionBeats();
		stepperBeats.name = 'section_beats';

		check_changeBPM = new PsychUICheckBox(10, stepperBeats.y + 30, 'Change BPM', 100, () -> _song.notes[curSec].altAnim = check_altAnim.checked);
		check_changeBPM.checked = _song.notes[curSec].changeBPM;
		check_changeBPM.name = 'check_changeBPM';

		stepperSectionBPM = new PsychUINumericStepper(10, check_changeBPM.y + 20, 1, Conductor.bpm, 0, 999999, 1);
		stepperSectionBPM.value = check_changeBPM.checked ? _song.notes[curSec].bpm : Conductor.bpm;
		stepperSectionBPM.name = 'section_bpm';

		var check_eventsSec:PsychUICheckBox = null;
		var check_notesSec:PsychUICheckBox = null;
		var copyButton:PsychUIButton = new PsychUIButton(10, 190, "Copy Section", () -> {
			notesCopied = [];
			sectionToCopy = curSec;
			for (i in 0..._song.notes[curSec].sectionNotes.length) {
				var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
				if(currentSectionSelected == 0) notesCopied.push(note);
				else {
					if((currentSectionSelected == 1 ? note[1] <= _song.mania : note[1] >= EK.keys(_song.mania)))
						notesCopied.push(note);
				}
			}

			var startThing:Float = sectionStartTime();
			var endThing:Float = sectionStartTime(1);
			for (event in _song.events) {
				var strumTime:Float = event[0];
				if(endThing > event[0] && event[0] >= startThing) {
					var copiedEventArray:Array<Dynamic> = [];
					for (i in 0...event[1].length) {
						var eventToPush:Array<Dynamic> = event[1][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
					}
					notesCopied.push([strumTime, -1, copiedEventArray]);
				}
			}
		});

		var pasteButton:PsychUIButton = new PsychUIButton(copyButton.x + 100, copyButton.y, "Paste Section", () -> {
			if(notesCopied == null || notesCopied.length < 1) return;

			var addToTime:Float = Conductor.stepCrochet * (getSectionBeats() * 4 * (curSec - sectionToCopy));
			for (note in notesCopied) {
				var copiedNote:Array<Dynamic> = [];
				var newStrumTime:Float = note[0] + addToTime;
				if(note[1] < 0) {
					if(check_eventsSec.checked) {
						var copiedEventArray:Array<Dynamic> = [];
						for (i in 0...note[2].length) {
							var eventToPush:Array<Dynamic> = note[2][i];
							copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
						}
						_song.events.push([newStrumTime, copiedEventArray]);
					}
				} else {
					if(check_notesSec.checked) {
						if(note[4] != null) copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
						else copiedNote = [newStrumTime, note[1], note[2], note[3]];

						if(currentSectionSelected != 0) {
							if(currentSectionSelected == 1)
								if(copiedNote[1] >= EK.keys(_song.mania)) copiedNote[1] -= EK.keys(_song.mania);
							else if(copiedNote[1] <= _song.mania) copiedNote[1] += EK.keys(_song.mania);
						}

						_song.notes[curSec].sectionNotes.push(copiedNote);
					}
				}
			}
			updateGrid();
		});

		var clearSectionButton:PsychUIButton = new PsychUIButton(pasteButton.x + 100, pasteButton.y, "Clear", () -> {
			if(check_notesSec.checked) {
				if(currentSectionSelected == 0) _song.notes[curSec].sectionNotes = [];
				else {
					var stupidArray = [];
					for (i in 0..._song.notes[curSec].sectionNotes.length){
						var mySection = _song.notes[curSec].sectionNotes;						
						var noteSelected:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];

						if((currentSectionSelected == 2 ? noteSelected[1] <= _song.mania : noteSelected[1] >= EK.keys(_song.mania))) 
							stupidArray.push(mySection[i]);
					}
					_song.notes[curSec].sectionNotes = stupidArray;
				}
			}

			if(check_eventsSec.checked) {
				var i:Int = _song.events.length - 1;
				var startThing:Float = sectionStartTime();
				var endThing:Float = sectionStartTime(1);
				while(i > -1) {
					var event:Array<Dynamic> = _song.events[i];
					if(event != null && endThing > event[0] && event[0] >= startThing) {
						_song.events.remove(event);
					}
					--i;
				}
			}
			updateGrid();
			updateNoteUI();
		});
		clearSectionButton.normalStyle.bgColor = FlxColor.RED;
		clearSectionButton.normalStyle.textColor = FlxColor.WHITE;
		
		sectionSelectedDropDown = new PsychUIDropDownMenu(150, 100, ['Both', 'Section 1', 'Section 2'], (id:Int, selected:String) -> currentSectionSelected = id);

		check_notesSec = new PsychUICheckBox(10, clearSectionButton.y + 25, "Notes", 100);
		check_notesSec.checked = true;
		check_eventsSec = new PsychUICheckBox(check_notesSec.x + 100, check_notesSec.y, "Events", 100);
		check_eventsSec.checked = true;

		var swapSection:PsychUIButton = new PsychUIButton(10, check_notesSec.y + 40, "Swap section", () -> {
			for (i in 0..._song.notes[curSec].sectionNotes.length) {
				var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
				note[1] = (note[1] + EK.keys(_song.mania)) % EK.strums(_song.mania);
				_song.notes[curSec].sectionNotes[i] = note;
			}
			updateGrid();
		});

		var stepperCopy:PsychUINumericStepper = null;
		var copyLastButton:PsychUIButton = new PsychUIButton(10, swapSection.y + 30, "Copy last section", () -> {
			var value:Int = Std.int(stepperCopy.value);
			if(value == 0) return;

			var daSec:Int = FlxMath.maxInt(curSec, value);

			for (note in _song.notes[daSec - value].sectionNotes) {
				if(check_notesSec.checked) {
					var strum:Float = note[0] + Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);
					var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3]];
					if(currentSectionSelected == 0)
						_song.notes[daSec].sectionNotes.push(copiedNote);
					else {
						if((currentSectionSelected == 1 ? copiedNote[1] <= _song.mania : copiedNote[1] >= EK.keys(_song.mania))) {
							_song.notes[daSec].sectionNotes.push(copiedNote);
						}
					}
				}
			}

			var startThing:Float = sectionStartTime(-value);
			var endThing:Float = sectionStartTime(-value + 1);
			for (event in _song.events) {
				var strumTime:Float = event[0];
				if(endThing > event[0] && event[0] >= startThing && check_eventsSec.checked) {
					strumTime += Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);
					var copiedEventArray:Array<Dynamic> = [];
					for (i in 0...event[1].length) {
						var eventToPush:Array<Dynamic> = event[1][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
					}
					_song.events.push([strumTime, copiedEventArray]);
				}
			}
			updateGrid();
		});
		copyLastButton.resize(80, 30);
		
		stepperCopy = new PsychUINumericStepper(copyLastButton.x + 100, copyLastButton.y, 1, 1, -999, 999, 0);

		var duetButton:PsychUIButton = new PsychUIButton(10, copyLastButton.y + 45, "Duet Notes", () -> {
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes) {
				if(currentSectionSelected == 1 && note[1] >= EK.keys(_song.mania)) continue;
				if(currentSectionSelected == 2 && note[1] <= _song.mania) continue;

				var boob:Int = note[1];
				if (boob > _song.mania) boob -= EK.keys(_song.mania);
				else boob += EK.keys(_song.mania);

				duetNotes.push([note[0], boob, note[2], note[3]]);
			}

			for (i in duetNotes) _song.notes[curSec].sectionNotes.push(i);
			updateGrid();
		});
		var mirrorButton:PsychUIButton = new PsychUIButton(duetButton.x + 100, duetButton.y, "Mirror Notes", () -> {
			for (note in _song.notes[curSec].sectionNotes) {
				var boob:Float = note[1] % EK.keys(_song.mania);
				boob = _song.mania - boob;
				if (note[1] > _song.mania) boob += EK.keys(_song.mania);
				note[1] = boob;
			}
			updateGrid();
		});
		var randomizeNotes:PsychUIButton = new PsychUIButton(mirrorButton.x + 100, duetButton.y, "Randomize Notes", () -> {
			for (note in _song.notes[curSec].sectionNotes) {
				if(currentSectionSelected == 1 && note[1] >= EK.keys(_song.mania)) continue;
				if(currentSectionSelected == 2 && note[1] <= _song.mania) continue;

				var boob:Float = note[1] % EK.keys(_song.mania);
				boob = FlxG.random.int(0, EK.strums(_song.mania) - 1);
				note[1] = boob;
			}
			updateGrid();
		});
		randomizeNotes.resize(80, 30);

		tab_group_section.add(new FlxText(stepperBeats.x, stepperBeats.y - 15, 0, 'Beats per Section:'));
		tab_group_section.add(stepperBeats);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_gfSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(pasteButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(new FlxText(sectionSelectedDropDown.x, sectionSelectedDropDown.y - 15, 0, 'Selected:'));
		tab_group_section.add(sectionSelectedDropDown);
		tab_group_section.add(check_notesSec);
		tab_group_section.add(check_eventsSec);
		tab_group_section.add(swapSection);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(copyLastButton);
		tab_group_section.add(duetButton);
		tab_group_section.add(mirrorButton);
		tab_group_section.add(randomizeNotes);
	}

	var stepperSusLength:PsychUINumericStepper;
	var strumTimeInputText:PsychUIInputText; //I wanted to use a stepper but we can't scale these as far as i know :(
	var noteTypeDropDown:PsychUIDropDownMenu;
	var currentType:Int = 0;
	var noteStuffCopied:Array<Dynamic>;
	var check_stackActive:PsychUICheckBox;
	var stepperStackNum:PsychUINumericStepper;
	var stepperStackOffset:PsychUINumericStepper;
	var stepperStackSideOffset:PsychUINumericStepper;

	function addNoteUI():Void {
		var tab_group_note:FlxSpriteGroup = UI_box.getTab('Note').menu;

		stepperSusLength = new PsychUINumericStepper(10, 25, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 64);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';

		strumTimeInputText = new PsychUIInputText(10, 65, 180, "0");
		tab_group_note.add(strumTimeInputText);

		var key:Int = 0;
		while (key < noteTypeList.length) {
			curNoteTypes.push(noteTypeList[key]);
			key++;
		}

		#if sys
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'custom_notetypes/'))
			for (file in FileSystem.readDirectory(folder)) {
				var fileName:String = file.toLowerCase().trim();
				var wordLen:Int = 4; //length of word ".lua";
				if((#if LUA_ALLOWED fileName.endsWith('.lua') || #end #if HSCRIPT_ALLOWED (fileName.endsWith('.hx') && (wordLen = 3) == 3) || #end fileName.endsWith('.txt')) && fileName != 'readme.txt') {
					var fileToCheck:String = file.substr(0, file.length - wordLen);
					if(!curNoteTypes.contains(fileToCheck)) {
						curNoteTypes.push(fileToCheck);
						key++;
					}
				}
			}
		#end

		var displayNameList:Array<String> = curNoteTypes.copy();
		for (i in 1...displayNameList.length) displayNameList[i] = '$i. ${displayNameList[i]}';

		noteTypeDropDown = new PsychUIDropDownMenu(10, 105, displayNameList, function(curType:Int, character:String) {
			currentType = curType;
			if(curSelectedNote != null && curSelectedNote[1] > -1) {
				curSelectedNote[3] = curNoteTypes[currentType];
				updateGrid();
			}
		});

		var copyButton:PsychUIButton = new PsychUIButton(10, noteTypeDropDown.y + 30, "Copy Note", () -> if(curSelectedNote != null && curSelectedNote.length > 2) noteStuffCopied = curSelectedNote);

		var pasteButton:PsychUIButton = new PsychUIButton(copyButton.x + 100, copyButton.y, "Paste Note", () -> {
			if(noteStuffCopied != null) {
				curSelectedNote[2] = noteStuffCopied[2];
				curSelectedNote[3] = noteStuffCopied[3];
				curSelectedNote[4] = noteStuffCopied[4];
				updateGrid();
			}
		});

		var leftSectionNotetype:PsychUIButton = new PsychUIButton(copyButton.x, noteTypeDropDown.y + 60, "Left Section to Notetype", () -> {
			for (sNotes in _song.notes[curSec].sectionNotes) {
				var note:Array<Dynamic> = sNotes;
				if (note[1] < EK.keys(_song.mania))
					note[3] = curNoteTypes[currentType];
				sNotes = note;
			}
			updateGrid();
		});
		leftSectionNotetype.resize(80, 30);
		var rightSectionNotetype:PsychUIButton = new PsychUIButton(pasteButton.x, leftSectionNotetype.y, "Right Section to Notetype", () -> {
			for (sNotes in _song.notes[curSec].sectionNotes) {
				var note:Array<Dynamic> = sNotes;
				if (note[1] > _song.mania)
					note[3] = curNoteTypes[currentType];
				sNotes = note;
			}
			updateGrid();
		});
		rightSectionNotetype.resize(80, 30);

		check_stackActive = new PsychUICheckBox(leftSectionNotetype.x, leftSectionNotetype.y + 50, "Spam Mode", 100);
		check_stackActive.name = 'check_stackActive';
		stepperStackNum = new PsychUINumericStepper(check_stackActive.x, check_stackActive.y + 40, 1, 4, 0, 999999);
		stepperStackNum.name = 'stack_count';

		stepperStackOffset = new PsychUINumericStepper(stepperStackNum.x + 80, stepperStackNum.y, 1, 1, 0, 8192);
		stepperStackOffset.name = 'stack_offset';
		stepperStackSideOffset = new PsychUINumericStepper(stepperStackOffset.x + 80, stepperStackOffset.y, 1, 0, -9999, 9999);
		stepperStackSideOffset.name = 'stack_sideways';

		tab_group_note.add(check_stackActive);
		tab_group_note.add(stepperStackNum);
		tab_group_note.add(stepperStackOffset);
		tab_group_note.add(stepperStackSideOffset);
		tab_group_note.add(new FlxText(stepperStackNum.x, stepperStackNum.y - 15, 0, "Spam Count"));
		tab_group_note.add(new FlxText(stepperStackOffset.x, stepperStackOffset.y - 15, 0, "Spam Multiplier"));
		tab_group_note.add(new FlxText(stepperStackSideOffset.x, stepperStackSideOffset.y - 15, 0, "Spam Scroll Amount"));
		tab_group_note.add(new FlxText(10, 10, 0, 'Sustain length:'));
		tab_group_note.add(new FlxText(10, 50, 0, 'Strum time (in miliseconds):'));
		tab_group_note.add(new FlxText(10, 90, 0, 'Note type:'));
		tab_group_note.add(leftSectionNotetype);
		tab_group_note.add(rightSectionNotetype);
		tab_group_note.add(copyButton);
		tab_group_note.add(pasteButton);
		tab_group_note.add(stepperSusLength);
		tab_group_note.add(strumTimeInputText);
		tab_group_note.add(noteTypeDropDown);
	}

	var eventDropDown:PsychUIDropDownMenu;
	var descText:FlxText;
	var selectedEventText:FlxText;
	function addEventsUI():Void {
		var tab_group_event:FlxSpriteGroup = UI_box.getTab('Events').menu;

		#if LUA_ALLOWED
		var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
		var directories:Array<String> = [];

		#if MODS_ALLOWED
		directories.push(Paths.mods('custom_events/'));
		directories.push(Paths.mods(Mods.currentModDirectory + '/custom_events/'));
		for(mod in Mods.getGlobalMods()) directories.push(Paths.mods('$mod/custom_events/'));
		#end

		for (i in 0...directories.length) {
			var directory:String = directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path:String = Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file != 'readme.txt' && file.endsWith('.txt')) {
						var fileToCheck:String = file.substr(0, file.length - 4);
						if(!eventPushedMap.exists(fileToCheck)) {
							eventPushedMap.set(fileToCheck, true);
							eventStuff.push([fileToCheck, File.getContent(path)]);
						}
					}
				}
			}
		}
		eventPushedMap.clear();
		eventPushedMap = null;
		#end

		descText = new FlxText(20, 200, 0, eventStuff[0][0]);

		var text:FlxText = new FlxText(20, 30, 0, "Event:");
		tab_group_event.add(text);
		eventDropDown = new PsychUIDropDownMenu(20, 50, [for (i in 0...eventStuff.length) eventStuff[i][0]], function(sE:Int, pressed:String) {
			descText.text = eventStuff[sE][1];
			if (curSelectedNote != null && eventStuff != null) {
				if (curSelectedNote != null && curSelectedNote[2] == null)
					curSelectedNote[1][sE][0] = eventStuff[sE][0];
				updateGrid();
			}
		});

		var text:FlxText = new FlxText(20, 90, 0, "Value 1:");
		tab_group_event.add(text);
		value1InputText = new PsychUIInputText(20, 110, 100, "");

		var text:FlxText = new FlxText(20, 130, 0, "Value 2:");
		tab_group_event.add(text);
		value2InputText = new PsychUIInputText(20, 150, 100, "");

		// New event buttons
		var removeButton:PsychUIButton = new PsychUIButton(eventDropDown.x + eventDropDown.width + 10, eventDropDown.y, '-', () -> {
			if(curSelectedNote != null && curSelectedNote[2] == null) { //Is event note
				if(curSelectedNote[1].length < 2) {
					_song.events.remove(curSelectedNote);
					curSelectedNote = null;
				} else curSelectedNote[1].remove(curSelectedNote[1][curEventSelected]);

				var eventsGroup:Array<Dynamic>;
				--curEventSelected;
				if(curEventSelected < 0) curEventSelected = 0;
				else if(curSelectedNote != null && curEventSelected >= (eventsGroup = curSelectedNote[1]).length) curEventSelected = eventsGroup.length - 1;

				changeEventSelected();
				updateGrid();
			}
		});
		removeButton.resize(Std.int(removeButton.height), Std.int(removeButton.height));
		removeButton.normalStyle.bgColor = FlxColor.RED;
		removeButton.normalStyle.textColor = FlxColor.WHITE;
		tab_group_event.add(removeButton);

		var addButton:PsychUIButton = new PsychUIButton(removeButton.x + removeButton.width + 10, removeButton.y, '+', () -> {
			if(curSelectedNote != null && curSelectedNote[2] == null) { //Is event note
				curSelectedNote[1].push(['', '', '']);
				changeEventSelected(1);
				updateGrid();
			}
		});
		addButton.resize(Std.int(removeButton.width), Std.int(removeButton.height));
		addButton.normalStyle.bgColor = FlxColor.GREEN;
		addButton.normalStyle.textColor = FlxColor.WHITE;
		tab_group_event.add(addButton);

		var moveLeftButton:PsychUIButton = new PsychUIButton(addButton.x + addButton.width + 20, addButton.y, '<', () -> changeEventSelected(-1));
		moveLeftButton.resize(Std.int(addButton.width), Std.int(addButton.height));
		tab_group_event.add(moveLeftButton);

		var moveRightButton:PsychUIButton = new PsychUIButton(moveLeftButton.x + moveLeftButton.width + 10, moveLeftButton.y, '>', () -> changeEventSelected(1));
		moveRightButton.resize(Std.int(moveLeftButton.width), Std.int(moveLeftButton.height));
		tab_group_event.add(moveRightButton);

		selectedEventText = new FlxText(addButton.x - 100, addButton.y + addButton.height + 6, (moveRightButton.x - addButton.x) + 186, 'Selected Event: None');
		selectedEventText.alignment = CENTER;
		tab_group_event.add(selectedEventText);

		tab_group_event.add(descText);
		tab_group_event.add(value1InputText);
		tab_group_event.add(value2InputText);
		tab_group_event.add(eventDropDown);
	}

	function changeEventSelected(change:Int = 0) {
		if(curSelectedNote != null && curSelectedNote[2] == null) { //Is event note
			curEventSelected += change;
			if(curEventSelected < 0) curEventSelected = Std.int(curSelectedNote[1].length) - 1;
			else if(curEventSelected >= curSelectedNote[1].length) curEventSelected = 0;
			selectedEventText.text = 'Selected Event: ' + (curEventSelected + 1) + ' / ' + curSelectedNote[1].length;
		} else {
			curEventSelected = 0;
			selectedEventText.text = 'Selected Event: None';
		}
		updateNoteUI();
	}

	var metronome:PsychUICheckBox;
	var mouseScrollingQuant:PsychUICheckBox;
	var metronomeStepper:PsychUINumericStepper;
	var metronomeOffsetStepper:PsychUINumericStepper;
	var disableAutoScrolling:PsychUICheckBox;
	var instVolume:PsychUINumericStepper;
	var voicesVolume:PsychUINumericStepper;
	function addChartingUI() {
		var tab_group_chart:FlxSpriteGroup = UI_box.getTab('Charting').menu;

		#if desktop
		if (FlxG.save.data.chart_waveformInst == null) FlxG.save.data.chart_waveformInst = false;
		if (FlxG.save.data.chart_waveformVoices == null) FlxG.save.data.chart_waveformVoices = false;

		var waveformUseInstrumental:PsychUICheckBox = null;
		var waveformUseVoices:PsychUICheckBox = null;

		waveformUseInstrumental = new PsychUICheckBox(10, 90, "Waveform\nInstrumental", 85);
		waveformUseInstrumental.checked = FlxG.save.data.chart_waveformInst;
		waveformUseInstrumental.onClick = () -> {
			waveformUseVoices.checked = false;
			FlxG.save.data.chart_waveformVoices = false;
			FlxG.save.data.chart_waveformInst = waveformUseInstrumental.checked;
			updateWaveform();
		};

		waveformUseVoices = new PsychUICheckBox(waveformUseInstrumental.x + 120, waveformUseInstrumental.y, "Waveform\n(Main Vocals)", 85);
		waveformUseVoices.checked = FlxG.save.data.chart_waveformVoices;
		waveformUseVoices.onClick = () -> {
			waveformUseInstrumental.checked = false;
			FlxG.save.data.chart_waveformInst = false;
			FlxG.save.data.chart_waveformVoices = waveformUseVoices.checked;
			updateWaveform();
		};
		#end

		check_mute_inst = new PsychUICheckBox(10, 310, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.onClick = () -> {
			var vol:Float = instVolume.value;
			if (check_mute_inst.checked) vol = 0;
			FlxG.sound.music.volume = vol;
		};
		mouseScrollingQuant = new PsychUICheckBox(10, 200, "Mouse Scrolling Quantization", 100);
		if (FlxG.save.data.mouseScrollingQuant == null) FlxG.save.data.mouseScrollingQuant = false;
		mouseScrollingQuant.checked = FlxG.save.data.mouseScrollingQuant;

		mouseScrollingQuant.onClick = () -> {
			FlxG.save.data.mouseScrollingQuant = mouseScrollingQuant.checked;
			mouseQuant = FlxG.save.data.mouseScrollingQuant;
		};

		check_vortex = new PsychUICheckBox(10, 160, "Vortex Editor (BETA)", 100);
		if (FlxG.save.data.chart_vortex == null) FlxG.save.data.chart_vortex = false;
		check_vortex.checked = FlxG.save.data.chart_vortex;

		check_vortex.onClick = () -> {
			FlxG.save.data.chart_vortex = check_vortex.checked;
			vortex = FlxG.save.data.chart_vortex;
			reloadGridLayer();
		};

		check_warnings = new PsychUICheckBox(10, 120, "Ignore Progress Warnings", 100);
		if (FlxG.save.data.ignoreWarnings == null) FlxG.save.data.ignoreWarnings = false;
		check_warnings.checked = FlxG.save.data.ignoreWarnings;

		check_warnings.onClick = () -> {
			FlxG.save.data.ignoreWarnings = check_warnings.checked;
			ignoreWarnings = FlxG.save.data.ignoreWarnings;
		};

		check_mute_vocals = new PsychUICheckBox(check_mute_inst.x + 120, check_mute_inst.y, "Mute Main Vocals (in editor)", 100);
		check_mute_vocals.checked = false;
		check_mute_vocals.onClick = () -> {
			var vol:Float = voicesVolume.value;
			if (check_mute_vocals.checked) vol = 0;
			if(vocals != null) vocals.volume = vol;
		};

		playSoundBf = new PsychUICheckBox(check_mute_inst.x, check_mute_vocals.y + 30, 'Play Sound (Boyfriend notes)', 100, () -> FlxG.save.data.chart_playSoundBf = playSoundBf.checked);
		if (FlxG.save.data.chart_playSoundBf == null) FlxG.save.data.chart_playSoundBf = false;
		playSoundBf.checked = FlxG.save.data.chart_playSoundBf;

		playSoundDad = new PsychUICheckBox(check_mute_inst.x + 120, playSoundBf.y, 'Play Sound (Opponent notes)', 100, () -> FlxG.save.data.chart_playSoundDad = playSoundDad.checked);
		if (FlxG.save.data.chart_playSoundDad == null) FlxG.save.data.chart_playSoundDad = false;
		playSoundDad.checked = FlxG.save.data.chart_playSoundDad;

		metronome = new PsychUICheckBox(10, 15, "Metronome Enabled", 100, () -> FlxG.save.data.chart_metronome = metronome.checked);
		if (FlxG.save.data.chart_metronome == null) FlxG.save.data.chart_metronome = false;
		metronome.checked = FlxG.save.data.chart_metronome;

		metronomeStepper = new PsychUINumericStepper(15, 55, 5, _song.bpm, 1, 1500, 1);
		metronomeOffsetStepper = new PsychUINumericStepper(metronomeStepper.x + 100, metronomeStepper.y, 25, 0, 0, 1000, 1);

		disableAutoScrolling = new PsychUICheckBox(metronome.x + 120, metronome.y, "Disable Autoscroll (Not Recommended)", 120, () -> FlxG.save.data.chart_noAutoScroll = disableAutoScrolling.checked);
		if (FlxG.save.data.chart_noAutoScroll == null) FlxG.save.data.chart_noAutoScroll = false;
		disableAutoScrolling.checked = FlxG.save.data.chart_noAutoScroll;

		instVolume = new PsychUINumericStepper(metronomeStepper.x, 270, 0.1, 1, 0, 1, 1);
		instVolume.value = FlxG.sound.music.volume;
		instVolume.name = 'inst_volume';

		voicesVolume = new PsychUINumericStepper(instVolume.x + 100, instVolume.y, 0.1, 1, 0, 1, 1);
		voicesVolume.value = vocals.volume;
		voicesVolume.name = 'voices_volume';

		sliderRate = new PsychUISlider(120, 120, ((v:Float) -> playbackSpeed = v), 1, 0.5, 3, 150);
		sliderRate.label = 'Playback Rate';
		tab_group_chart.add(sliderRate);

		tab_group_chart.add(new FlxText(metronomeStepper.x, metronomeStepper.y - 15, 0, 'BPM:'));
		tab_group_chart.add(new FlxText(metronomeOffsetStepper.x, metronomeOffsetStepper.y - 15, 0, 'Offset (ms):'));
		tab_group_chart.add(new FlxText(instVolume.x, instVolume.y - 15, 0, 'Inst Volume'));
		tab_group_chart.add(new FlxText(voicesVolume.x, voicesVolume.y - 15, 0, 'Main Vocals'));
		tab_group_chart.add(metronome);
		tab_group_chart.add(disableAutoScrolling);
		tab_group_chart.add(metronomeStepper);
		tab_group_chart.add(metronomeOffsetStepper);
		#if desktop
		tab_group_chart.add(waveformUseInstrumental);
		tab_group_chart.add(waveformUseVoices);
		#end
		tab_group_chart.add(instVolume);
		tab_group_chart.add(voicesVolume);
		tab_group_chart.add(check_mute_inst);
		tab_group_chart.add(check_mute_vocals);
		tab_group_chart.add(check_vortex);
		tab_group_chart.add(mouseScrollingQuant);
		tab_group_chart.add(check_warnings);
		tab_group_chart.add(playSoundBf);
		tab_group_chart.add(playSoundDad);
	}

	var gameOverCharacterInputText:PsychUIInputText;
	var gameOverSoundInputText:PsychUIInputText;
	var gameOverLoopInputText:PsychUIInputText;
	var gameOverEndInputText:PsychUIInputText;
	var noteSkinInputText:PsychUIInputText;
	var noteSplashesInputText:PsychUIInputText;
	function addDataUI() {
		var tab_group_data:FlxSpriteGroup = UI_box.getTab('Data').menu;

		var skin:Array<Null<String>> = [PlayState.SONG.arrowSkin, PlayState.SONG.splashSkin];
		if(skin[0] == null || skin[0].length < 1) skin[0] = 'NOTE_assets';
		if(skin[1] == null || skin[1].length < 1) skin[1] = 'noteSplashes';

		gameOverCharacterInputText = new PsychUIInputText(10, 25, 150, _song.gameOverChar ?? '', 8);
		gameOverSoundInputText = new PsychUIInputText(10, gameOverCharacterInputText.y + 35, 150, _song.gameOverSound ?? '', 8);
		gameOverLoopInputText = new PsychUIInputText(10, gameOverSoundInputText.y + 35, 150, _song.gameOverLoop ?? '', 8);
		gameOverEndInputText = new PsychUIInputText(10, gameOverLoopInputText.y + 35, 150, _song.gameOverEnd ?? '', 8);

		var check_disableNoteRGB:PsychUICheckBox = new PsychUICheckBox(10, 170, "Disable Note RGB", 100);
		check_disableNoteRGB.checked = (_song.disableNoteRGB == true);
		check_disableNoteRGB.onClick = () -> {
			_song.disableNoteRGB = check_disableNoteRGB.checked;
			updateGrid();
		};

		noteSkinInputText = new PsychUIInputText(10, 280, 150, skin[0], 8);
		noteSplashesInputText = new PsychUIInputText(noteSkinInputText.x, noteSkinInputText.y + 35, 150, skin[1], 8);

		var reloadNotesButton:PsychUIButton = new PsychUIButton(noteSplashesInputText.x + 5, noteSplashesInputText.y + 20, 'Change Notes', () -> {
			_song.arrowSkin = noteSkinInputText.text;
			updateGrid();
		});

		tab_group_data.add(gameOverCharacterInputText);
		tab_group_data.add(gameOverSoundInputText);
		tab_group_data.add(gameOverLoopInputText);
		tab_group_data.add(gameOverEndInputText);

		tab_group_data.add(check_disableNoteRGB);

		tab_group_data.add(reloadNotesButton);
		tab_group_data.add(noteSkinInputText);
		tab_group_data.add(noteSplashesInputText);

		tab_group_data.add(new FlxText(gameOverCharacterInputText.x, gameOverCharacterInputText.y - 15, 0, 'Game Over Character Name:'));
		tab_group_data.add(new FlxText(gameOverSoundInputText.x, gameOverSoundInputText.y - 15, 0, 'Game Over Death Sound (sounds/):'));
		tab_group_data.add(new FlxText(gameOverLoopInputText.x, gameOverLoopInputText.y - 15, 0, 'Game Over Loop Music (music/):'));
		tab_group_data.add(new FlxText(gameOverEndInputText.x, gameOverEndInputText.y - 15, 0, 'Game Over Retry Music (music/):'));

		tab_group_data.add(new FlxText(noteSkinInputText.x, noteSkinInputText.y - 15, 0, 'Note Texture:'));
		tab_group_data.add(new FlxText(noteSplashesInputText.x, noteSplashesInputText.y - 15, 0, 'Note Splashes Texture:'));
	}

	function loadSong():Void {
		if (FlxG.sound.music != null) FlxG.sound.music.stop();

		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}

		vocals = new FlxSound();
		try {
			vocals.loadEmbedded(Paths.voices(currentSongName));
		} catch(e:Dynamic) Logs.trace("ERROR VOCALS ON LOAD: " + e, ERROR);
		vocals.autoDestroy = false;
		FlxG.sound.list.add(vocals);

		generateSong();
		FlxG.sound.music.pause();
		Conductor.songPosition = sectionStartTime();
		FlxG.sound.music.time = Conductor.songPosition;

		var curTime:Float = 0;
		if(_song.notes.length <= 1) { //First load ever
			while(curTime < FlxG.sound.music.length) {
				addSection();
				curTime += (60 / _song.bpm) * 4000;
			}
		}
	}

	var playtesting:Bool = false;
	var playtestingTime:Float = 0;
	var playtestingOnComplete:Void->Void = null;
	override function closeSubState() {
		if(playtesting) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = playtestingTime;
			FlxG.sound.music.onComplete = playtestingOnComplete;
			if (instVolume != null) FlxG.sound.music.volume = instVolume.value;
			if (check_mute_inst != null && check_mute_inst.checked) FlxG.sound.music.volume = 0;

			if(vocals != null) {
				vocals.pause();
				vocals.time = playtestingTime;
				if (voicesVolume != null) vocals.volume = voicesVolume.value;
				if (check_mute_vocals != null && check_mute_vocals.checked) vocals.volume = 0;
			}

			#if DISCORD_ALLOWED DiscordClient.changePresence("Chart Editor", _song.song.replace('-', ' ')); #end
		}
		super.closeSubState();
	}

	function generateSong() {
		FlxG.sound.playMusic(Paths.inst(currentSongName), .6);
		FlxG.sound.music.autoDestroy = false;
		if (instVolume != null) FlxG.sound.music.volume = instVolume.value;
		if (check_mute_inst != null && check_mute_inst.checked) FlxG.sound.music.volume = 0;

		FlxG.sound.music.onComplete = () -> {
			FlxG.sound.music.pause();
			Conductor.songPosition = 0;
			if(vocals != null) {
				vocals.pause();
				vocals.time = 0;
			}
			changeSection();
			curSec = 0;
			updateGrid();
			updateSectionUI();
			if(vocals != null) vocals.play();
		};
	}

	public function UIEvent(id:String, sender:Dynamic) {
		if (id == PsychUINumericStepper.CHANGE_EVENT && (sender is PsychUINumericStepper)) {
			var nums:PsychUINumericStepper = cast sender;
			switch (nums.name) {
				case 'section_beats':
					_song.notes[curSec].sectionBeats = nums.value;
					reloadGridLayer();
				case 'song_speed':
					_song.speed = nums.value;
				case 'song_bpm':
					_song.bpm = nums.value;
					Conductor.mapBPMChanges(_song);
					Conductor.bpm = nums.value;
					stepperSusLength.step = Math.ceil(Conductor.stepCrochet / 2);
					updateGrid();
				case 'song_mania':
					_song.mania = Std.int(nums.value);
					PlayState.mania = _song.mania;
					reloadGridLayer();
				case 'note_susLength':
					if (curSelectedNote != null && curSelectedNote[2] != null) {
						curSelectedNote[2] = nums.value;
						updateGrid();
					}
				case 'section_bpm':
					_song.notes[curSec].bpm = nums.value;
					updateGrid();
				case 'inst_volume':
					FlxG.sound.music.volume = nums.value;
					if(check_mute_inst.checked) FlxG.sound.music.volume = 0;
				case 'voices_volume':
					vocals.volume = nums.value;
					if(check_mute_vocals.checked) vocals.volume = 0;
			}
		} else if (id == PsychUIInputText.CHANGE_EVENT && (sender is PsychUIInputText)) {
			if (sender == noteSplashesInputText) {
				_song.splashSkin = noteSplashesInputText.text;
			} else if(sender == noteSkinInputText) {
				_song.arrowSkin = noteSkinInputText.text;
			} else if(sender == gameOverCharacterInputText) {
				_song.gameOverChar = gameOverCharacterInputText.text;
			} else if(sender == gameOverSoundInputText) {
				_song.gameOverSound = gameOverSoundInputText.text;
			} else if(sender == gameOverLoopInputText) {
				_song.gameOverLoop = gameOverLoopInputText.text;
			} else if(sender == gameOverEndInputText) {
				_song.gameOverEnd = gameOverEndInputText.text;
			} else if (curSelectedNote != null) {
				if (sender == value1InputText) {
					if(curSelectedNote[1][curEventSelected] != null) {
						curSelectedNote[1][curEventSelected][1] = value1InputText.text;
						updateGrid();
					}
				} else if (sender == value2InputText) {
					if(curSelectedNote[1][curEventSelected] != null) {
						curSelectedNote[1][curEventSelected][2] = value2InputText.text;
						updateGrid();
					}
				} else if (sender == strumTimeInputText) {
					var value:Float = Std.parseFloat(strumTimeInputText.text);
					if(Math.isNaN(value)) value = 0;
					curSelectedNote[0] = value;
					updateGrid();
				}
			}
		} else if (id == PsychUISlider.CHANGE_EVENT && (sender is PsychUISlider)) {
			if (sender == 'playbackSpeed') playbackSpeed = Std.int(sliderRate.value);
		}
	}

	function sectionStartTime(add:Int = 0):Float {
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSec + add) {
			if(_song.notes[i] != null) {
				if (_song.notes[i].changeBPM) daBPM = _song.notes[i].bpm;
				daPos += getSectionBeats(i) * (1000 * 60 / daBPM);
			}
		}
		return daPos;
	}

	var lastConductorPos:Float;
	var colorSine:Float = 0;
	override function update(elapsed:Float) {
		curStep = recalculateSteps();

		var gWidth:Float = GRID_SIZE * EK.strums(_song.mania);
		camPos.x = -80 + gWidth;
		strumLine.width = gWidth;

		if (FlxG.sound.music.time < 0) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		} else if(FlxG.sound.music.time > FlxG.sound.music.length) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = UI_songTitle.text;

		strumLineUpdateY();
		for (i in 0...strumLineNotes.members.length) {
			strumLineNotes.members[i].y = strumLine.y;
		}

		camPos.y = strumLine.y;
		if (!disableAutoScrolling.checked) {
			if (Math.ceil(strumLine.y) >= gridBG.height) {
				if (_song.notes[curSec + 1] == null) addSection(getSectionBeats());
				changeSection(curSec + 1, false);
			} else if(strumLine.y < -10) changeSection(curSec - 1, false);
		}
		FlxG.watch.addQuick('daSection', curSection);
		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);

		if (FlxG.mouse.x > gridBG.x && FlxG.mouse.x < gridBG.x + gridBG.width && FlxG.mouse.y > gridBG.y && FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom]) {
			dummyArrow.visible = true;
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT) dummyArrow.y = FlxG.mouse.y;
			else {
				var gridmult:Float = GRID_SIZE / (quantization / 16);
				dummyArrow.y = Math.floor(FlxG.mouse.y / gridmult) * gridmult;
			}
		} else dummyArrow.visible = false;

		if (FlxG.mouse.pressedRight) {
			var curNoteStrum = getStrumTime(dummyArrow.y, false) + sectionStartTime();
			var curNoteData = Math.floor((FlxG.mouse.x - GRID_SIZE) / GRID_SIZE);
			if (!((curNoteStrum == lastNoteStrum) && (curNoteData == lastNoteData))) {
				if (FlxG.mouse.overlaps(curRenderedNotes))
					curRenderedNotes.forEachAlive((note:Note) -> if (FlxG.mouse.overlaps(note)) deleteNote(note));
				else if (FlxG.mouse.x > gridBG.x && FlxG.mouse.x < gridBG.x + gridBG.width && FlxG.mouse.y > gridBG.y && FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
					addNote();
			}
		}
		if (FlxG.mouse.justPressed) {
			if (FlxG.mouse.overlaps(curRenderedNotes)) {
				curRenderedNotes.forEachAlive(function(note:Note) {
					if (FlxG.mouse.overlaps(note)) {
						if (FlxG.keys.pressed.CONTROL) selectNote(note);
						else if (FlxG.keys.pressed.ALT) {
							selectNote(note);
							curSelectedNote[3] = curNoteTypes[currentType];
							updateGrid();
						} else deleteNote(note);
					}
				});
			} else {
				if (FlxG.mouse.x > gridBG.x && FlxG.mouse.x < gridBG.x + gridBG.width && FlxG.mouse.y > gridBG.y && FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom]) {
					FlxG.log.add('added note');
					addNote();
					if (check_stackActive.checked) for(_ in 0...Math.floor(stepperStackNum.value * stepperStackOffset.value - 1)) addNote(curSelectedNote[0] + (15000 / Conductor.bpm) / stepperStackOffset.value, curSelectedNote[1] + Math.floor(stepperStackSideOffset.value), currentType);
				}
			}
		}

		if(PsychUIInputText.focusOn == null) {
			ClientPrefs.toggleVolumeKeys(true);
			if (FlxG.keys.justPressed.ESCAPE && !helpBg.visible) {
				if(FlxG.sound.music != null) FlxG.sound.music.stop();
	
				if(vocals != null) {
					vocals.pause();
					vocals.volume = 0;
				}
	
				autosaveSong();
				playtesting = true;
				playtestingTime = Conductor.songPosition;
				playtestingOnComplete = FlxG.sound.music.onComplete;
				openSubState(new EditorPlayState(playbackSpeed));
			} else if(FlxG.keys.justPressed.F1 || (helpBg.visible && FlxG.keys.justPressed.ESCAPE)) {
				helpBg.visible = !helpBg.visible;
				helpTexts.visible = helpBg.visible;
			} else if (FlxG.keys.justPressed.ENTER) {
				autosaveSong();
				FlxG.mouse.visible = false;
				PlayState.SONG = _song;
				FlxG.sound.music.stop();
				if(vocals != null) vocals.stop();
		
				data.StageData.loadDirectory(_song);
				LoadingState.loadAndSwitchState(() -> new PlayState());
			}

			if(curSelectedNote != null && curSelectedNote[1] > -1) {
				if (FlxG.keys.justPressed.E) changeNoteSustain(Conductor.stepCrochet);
				if (FlxG.keys.justPressed.Q) changeNoteSustain(-Conductor.stepCrochet);
			}

			if (FlxG.keys.justPressed.BACKSPACE) {
				autosaveSong();
				PlayState.chartingMode = false;
				FlxG.switchState(() -> new MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				FlxG.mouse.visible = false;
				return;
			}

			if(FlxG.keys.justPressed.Z && curZoom > 0 && !FlxG.keys.pressed.CONTROL) {
				--curZoom;
				updateZoom();
			}
			if(FlxG.keys.justPressed.X && curZoom < zoomList.length - 1) {
				curZoom++;
				updateZoom();
			}

			if (FlxG.keys.justPressed.TAB) {
				if (FlxG.keys.pressed.SHIFT) {
					var id:Int = UI_box.selectedIndex - 1;
					if (id < 0) id = UI_box.tabs.length - 1;
					UI_box.selectedIndex = id;
				} else {
					var id:Int = UI_box.selectedIndex + 1;
					if (id >= UI_box.tabs.length) id = 0;
					UI_box.selectedIndex = id;
				}
			}

			if (FlxG.keys.justPressed.SPACE) {
				if(vocals != null) vocals.play();
				pauseAndSetVocalsTime();
				if (!FlxG.sound.music.playing) {
					FlxG.sound.music.play();
					if(vocals != null) vocals.play();
				} else FlxG.sound.music.pause();
			}

			if (!FlxG.keys.pressed.ALT && FlxG.keys.justPressed.R)
				resetSection(FlxG.keys.pressed.SHIFT);

			if (FlxG.mouse.wheel != 0) {
				FlxG.sound.music.pause();
				if (!mouseQuant) FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * .8);
				else {
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					if (FlxG.mouse.wheel > 0) {
						var fuck:Float = MathUtil.quantize(beat, snap) - increase;
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					} else {
						var fuck:Float = MathUtil.quantize(beat, snap) + increase;
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
				}
				pauseAndSetVocalsTime();
			}

			if (FlxG.keys.pressed.W || FlxG.keys.pressed.S) {
				FlxG.sound.music.pause();

				var holdingShift:Float = 1;
				if (FlxG.keys.pressed.CONTROL) holdingShift = .25;
				else if (FlxG.keys.pressed.SHIFT) holdingShift = 4;

				var daTime:Float = 700 * elapsed * holdingShift;
				FlxG.sound.music.time += daTime * (FlxG.keys.pressed.W ? -1 : 1);

				pauseAndSetVocalsTime();
			}

			if(!vortex) {
				if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN) {
					FlxG.sound.music.pause();
					updateCurStep();
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					if (FlxG.keys.pressed.UP) {
						var fuck:Float = MathUtil.quantize(beat, snap) - increase;
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					} else {
						var fuck:Float = MathUtil.quantize(beat, snap) + increase;
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
				}
			}

			var style:Int = currentType;
			if (FlxG.keys.pressed.SHIFT) style = 3;

			var conductorTime = Conductor.songPosition;

			if(FlxG.keys.justPressed.RIGHT) {
				curQuant++;
				if(curQuant > quantizations.length - 1) curQuant = 0;
				quantization = quantizations[curQuant];
			}
			if(FlxG.keys.justPressed.LEFT) {
				curQuant--;
				if(curQuant < 0) curQuant = quantizations.length - 1;
				quantization = quantizations[curQuant];
			}
			quant.animation.play('q', true, false, curQuant);

			if(vortex) {
				var controlArray:Array<Bool> = [FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR, FlxG.keys.justPressed.FIVE, FlxG.keys.justPressed.SIX, FlxG.keys.justPressed.SEVEN, FlxG.keys.justPressed.EIGHT];
				if(controlArray.contains(true) && _song.mania == 3) {
					for (i in 0...controlArray.length) {
						if(controlArray[i]) doANoteThing(conductorTime, i, style);
					}
				}

				var feces:Float;
				if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN) {
					FlxG.sound.music.pause();

					updateCurStep();
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					if (FlxG.keys.pressed.UP) {
						var fuck:Float = MathUtil.quantize(beat, snap) - increase;
						feces = Conductor.beatToSeconds(fuck);
					} else {
						var fuck:Float = MathUtil.quantize(beat, snap) + increase;
						feces = Conductor.beatToSeconds(fuck);
					}
					FlxTween.tween(FlxG.sound.music, {time:feces}, .1, {ease:FlxEase.circOut});
					pauseAndSetVocalsTime();

					var dastrum:Int = 0;
					if (curSelectedNote != null) {
						dastrum = curSelectedNote[0];
					}

					var secStart:Float = sectionStartTime();
					var datime:Float = (feces - secStart) - (dastrum - secStart); //idk math find out why it doesn't work on any other section other than 0
					if (curSelectedNote != null) {
						var controlArray:Array<Bool> = [FlxG.keys.pressed.ONE, FlxG.keys.pressed.TWO, FlxG.keys.pressed.THREE, FlxG.keys.pressed.FOUR, FlxG.keys.pressed.FIVE, FlxG.keys.pressed.SIX, FlxG.keys.pressed.SEVEN, FlxG.keys.pressed.EIGHT];
						if(controlArray.contains(true)) {
							for (i in 0...controlArray.length) {
								if(controlArray[i] && curSelectedNote[1] == i) curSelectedNote[2] += datime - curSelectedNote[2] - Conductor.stepCrochet;
							}
							updateGrid();
							updateNoteUI();
						}
					}
				}
			}
			var shiftThing:Int = 1;
			if (FlxG.keys.pressed.SHIFT) shiftThing = 4;

			if (FlxG.keys.justPressed.H) changeSection(0);
			if (FlxG.keys.justPressed.D) changeSection(curSec + shiftThing);
			if (FlxG.keys.justPressed.A) {
				if(curSec <= 0) changeSection(_song.notes.length - 1);
				else changeSection(curSec - shiftThing);
			}
		} else ClientPrefs.toggleVolumeKeys(false);

		strumLineNotes.visible = quant.visible = vortex;

		if(FlxG.sound.music.time < 0) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		} else if(FlxG.sound.music.time > FlxG.sound.music.length) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		strumLineUpdateY();
		camPos.y = strumLine.y;
		for (i in 0...strumLineNotes.members.length) {
			strumLineNotes.members[i].y = strumLine.y;
			strumLineNotes.members[i].alpha = FlxG.sound.music.playing ? 1 : 0.35;
		}

		var holdingShift = FlxG.keys.pressed.SHIFT;
		var holdingLB = FlxG.keys.pressed.LBRACKET;
		var holdingRB = FlxG.keys.pressed.RBRACKET;
		var pressedLB = FlxG.keys.justPressed.LBRACKET;
		var pressedRB = FlxG.keys.justPressed.RBRACKET;

		if (!holdingShift && pressedLB || holdingShift && holdingLB)
			playbackSpeed -= .01;
		if (!holdingShift && pressedRB || holdingShift && holdingRB)
			playbackSpeed += .01;
		if (FlxG.keys.pressed.ALT && (pressedLB || pressedRB || holdingLB || holdingRB))
			playbackSpeed = 1;

		if (playbackSpeed <= .5) playbackSpeed = .5;
		if (playbackSpeed >= 3) playbackSpeed = 3;

		FlxG.sound.music.pitch = playbackSpeed;
		vocals.pitch = playbackSpeed;
		sliderRate.value = playbackSpeed;

		bpmTxt.text =
		'$currentSongName [${Difficulty.getString()}]' +
		'\n${CoolUtil.formatTime(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))} / ${CoolUtil.formatTime(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2))}' +
		'\n\nSection: $curSec' +
		'\nBeat: ${Std.string(curDecBeat).substring(0, 4)}' +
		'\nStep: $curStep' +
		'\nZoom: $zoomFactorTxt' +
		if ((quantization - 2) % 10 == 0 && quantization != 12) '\n\nBeat Snap ${quantization}nd';
		else '\n\nBeat Snap: ${quantization}th';

		var playedSound:Array<Bool> = [false, false, false, false]; //Prevents ouchy GF sex sounds
		curRenderedNotes.forEachAlive(function(note:Note) {
			note.alpha = 1;
			if(curSelectedNote != null) {
				var noteDataToCheck:Int = note.noteData;
				if(noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += EK.keys(_song.mania);

				if (curSelectedNote[0] == note.strumTime && ((curSelectedNote[2] == null && noteDataToCheck < 0) || (curSelectedNote[2] != null && curSelectedNote[1] == noteDataToCheck))) {
					colorSine += elapsed;
					var colorVal:Float = .7 + Math.sin(Math.PI * colorSine) * .3;
					note.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, .999); //Alpha can't be 100% or the color won't be updated for some reason, guess i will die
				}
			}

			if(note.strumTime <= Conductor.songPosition) {
				note.alpha = 0.4;
				if(note.strumTime > lastConductorPos && FlxG.sound.music.playing && note.noteData > -1) {
					var data:Int = note.noteData % 4;
					var noteDataToCheck:Int = note.noteData;
					if(noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += EK.keys(_song.mania);
					strumLineNotes.members[noteDataToCheck].playAnim('confirm', true);
					strumLineNotes.members[noteDataToCheck].resetAnim = ((note.sustainLength / 1000) + .15) / playbackSpeed;
					if(!playedSound[data]) {
						if(note.hitsoundChartEditor && ((playSoundBf.checked && note.mustPress) || (playSoundDad.checked && !note.mustPress))) {
							var soundToPlay:String = 'hitsounds/${Std.string(ClientPrefs.data.hitsoundTypes).toLowerCase()}';
							if(_song.player1 == 'gf') soundToPlay = 'gfnoise/GF_${EK.keys(data)}'; //Easter egg 

							FlxG.sound.play(Paths.sound(soundToPlay)).pan = note.noteData < 4 ? -.3 : .3; //would be coolio
							playedSound[data] = true;
						}

						data = note.noteData;
						if(note.mustPress != _song.notes[curSec].mustHitSection) data += 4;
					}
				}
			}
		});

		if(metronome.checked && lastConductorPos != Conductor.songPosition) {
			var metroInterval:Float = 60 / metronomeStepper.value;
			var metroStep:Int = Math.floor(((Conductor.songPosition + metronomeOffsetStepper.value) / metroInterval) / 1000);
			var lastMetroStep:Int = Math.floor(((lastConductorPos + metronomeOffsetStepper.value) / metroInterval) / 1000);

			if(metroStep != lastMetroStep) FlxG.sound.play(Paths.sound('Metronome_Tick'));
		}
		lastConductorPos = Conductor.songPosition;
		super.update(elapsed);
	}

	function pauseAndSetVocalsTime() {
		if(vocals != null) {
			vocals.pause();
			vocals.time = FlxG.sound.music.time;
		}
	}

	function updateZoom() {
		var daZoom:Float = zoomList[curZoom];
		zoomFactorTxt = '1 / $daZoom';
		if(daZoom < 1) zoomFactorTxt = '${Math.round(1 / daZoom)} / 1';
		reloadGridLayer();
	}

	override function destroy() {
		Note.globalRgbShaders = [];
		backend.NoteTypesConfig.clearNoteTypesData();
		super.destroy();
	}

	function reloadIconPosition() {
		var iconPos:Float = 10 + (GRID_SIZE * (_song.mania - 3) / 2);
		leftIcon.setPosition(GRID_SIZE + iconPos, -100);
		rightIcon.setPosition(GRID_SIZE + GRID_SIZE * EK.keys(_song.mania) + iconPos, -100);
	}

	var lastSecBeats:Float = 0;
	var lastSecBeatsNext:Float = 0;
	var columns:Int = 9;
	function reloadGridLayer() {
		PlayState.mania = _song.mania;
		columns = EK.strums(_song.mania) + 1;

		gridLayer.clear();
		gridBG = FlxGridOverlay.create(1, 1, columns, Std.int(getSectionBeats() * 4 * zoomList[curZoom]));
		gridBG.antialiasing = false;
		gridBG.scale.set(GRID_SIZE, GRID_SIZE);
		gridBG.updateHitbox();

		#if desktop
		if(FlxG.save.data.chart_waveformInst || FlxG.save.data.chart_waveformVoices)
			updateWaveform();
		#end
		reloadIconPosition();

		var leHeight:Int = Std.int(gridBG.height);
		var foundNextSec:Bool = false;
		if(sectionStartTime(1) <= FlxG.sound.music.length) {
			nextGridBG = FlxGridOverlay.create(1, 1, columns, Std.int(getSectionBeats(curSec + 1) * 4 * zoomList[curZoom]));
			nextGridBG.antialiasing = false;
			nextGridBG.scale.set(GRID_SIZE, GRID_SIZE);
			nextGridBG.updateHitbox();
			leHeight = Std.int(gridBG.height + nextGridBG.height);
			foundNextSec = true;
		} else nextGridBG = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		nextGridBG.y = gridBG.height;
		
		gridLayer.add(nextGridBG);
		gridLayer.add(gridBG);

		if(foundNextSec) {
			var gridBlack:FlxSprite = new FlxSprite(0, gridBG.height).makeGraphic(1, 1, FlxColor.BLACK);
			gridBlack.setGraphicSize(Std.int(GRID_SIZE * columns), Std.int(nextGridBG.height));
			gridBlack.updateHitbox();
			gridBlack.antialiasing = false;
			gridBlack.alpha = .4;
			gridLayer.add(gridBlack);
		}

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width - (GRID_SIZE * EK.keys(_song.mania))).makeGraphic(1, 1, FlxColor.BLACK);
		gridBlackLine.setGraphicSize(2, leHeight);
		gridBlackLine.updateHitbox();
		gridBlackLine.antialiasing = false;
		gridLayer.add(gridBlackLine);

		for (i in 1...Std.int(getSectionBeats())) {
			var beatsep:FlxSprite = new FlxSprite(gridBG.x, (GRID_SIZE * (4 * zoomList[curZoom])) * i).makeGraphic(1, 1, 0x44FF0000);
			beatsep.scale.x = gridBG.width;
			beatsep.updateHitbox();
			if(vortex) gridLayer.add(beatsep);
		}

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + GRID_SIZE).makeGraphic(1, 1, FlxColor.BLACK);
		gridBlackLine.setGraphicSize(2, leHeight);
		gridBlackLine.updateHitbox();
		gridBlackLine.antialiasing = false;
		gridLayer.add(gridBlackLine);

		remove(strumLine);
		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE * columns), 4);
		add(strumLine);

		remove(quant);
		quant = new AttachedSprite('chart_quant', 'chart_quant');
		quant.animation.addByPrefix('q', 'chart_quant', 0, false);
		quant.animation.play('q', true, false, 0);
		quant.sprTracker = strumLine;
		quant.addPoint.set(-32, 8);
		add(quant);

		if (strumLineNotes != null)	{
			strumLineNotes.clear();
			for (i in 0...EK.strums(_song.mania)) {
				var note:StrumNote = new StrumNote(GRID_SIZE * (i + 1), strumLine.y, i % EK.keys(_song.mania), 0);
				note.setGraphicSize(GRID_SIZE, GRID_SIZE);
				note.updateHitbox();
				note.playAnim('static', true);
				strumLineNotes.add(note);
				note.scrollFactor.set(1, 1);
			}
		}
		updateGrid();

		lastSecBeats = getSectionBeats();
		if(sectionStartTime(1) > FlxG.sound.music.length) lastSecBeatsNext = 0;
		else getSectionBeats(curSec + 1);
	}

	function strumLineUpdateY() {
		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) / zoomList[curZoom] % (Conductor.stepCrochet * 16)) / (getSectionBeats() / 4);
	}

	var waveformPrinted:Bool = true;
	var wavData:Array<Array<Array<Float>>> = [[[0], [0]], [[0], [0]]];

	var lastWaveformHeight:Int = 0;
	var lastMania:Int = 3;
	function updateWaveform() {
		#if desktop
		var width:Int = Std.int(GRID_SIZE * EK.strums(_song.mania));
		if(waveformPrinted) {
			var height:Int = Std.int(gridBG.height);
			if((lastWaveformHeight != height && waveformSprite.pixels != null) || lastMania != _song.mania) {
				waveformSprite.pixels.dispose();
				waveformSprite.makeGraphic(width, height, 0x00FFFFFF);
				lastWaveformHeight = height;
				lastMania = _song.mania;
			}
			waveformSprite.pixels.fillRect(new Rectangle(0, 0, width, height), 0x00FFFFFF);
		}
		waveformPrinted = false;

		if(!FlxG.save.data.chart_waveformInst && !FlxG.save.data.chart_waveformVoices) return;

		wavData[0][0] = [];
		wavData[0][1] = [];
		wavData[1][0] = [];
		wavData[1][1] = [];

		var steps:Int = Math.round(getSectionBeats() * 4);
		var st:Float = sectionStartTime();
		var et:Float = st + (Conductor.stepCrochet * steps);

		var sound:FlxSound = FlxG.sound.music;
		if (FlxG.save.data.chart_waveformVoices) sound = vocals;
		if (sound != null && sound._sound != null && sound._sound.__buffer != null) {
			var buffer:AudioBuffer = sound._sound.__buffer;
			wavData = waveformData(buffer, buffer.data.toBytes(), st, et, 1, wavData, Std.int(gridBG.height));
		}

		// Draws
		var hSize:Int = Std.int(width / 2);
		var size:Float = 1;

		var leftLength:Int = (wavData[0][0].length > wavData[0][1].length ? wavData[0][0].length : wavData[0][1].length);
		var rightLength:Int = (wavData[1][0].length > wavData[1][1].length ? wavData[1][0].length : wavData[1][1].length);
		var length:Int = leftLength > rightLength ? leftLength : rightLength;

		for (index in 0...length) {
			var lmin:Float = FlxMath.bound(((index < wavData[0][0].length && index >= 0) ? wavData[0][0][index] : 0) * (width / 1.12), -hSize, hSize) / 2;
			var lmax:Float = FlxMath.bound(((index < wavData[0][1].length && index >= 0) ? wavData[0][1][index] : 0) * (width / 1.12), -hSize, hSize) / 2;

			var rmin:Float = FlxMath.bound(((index < wavData[1][0].length && index >= 0) ? wavData[1][0][index] : 0) * (width / 1.12), -hSize, hSize) / 2;
			var rmax:Float = FlxMath.bound(((index < wavData[1][1].length && index >= 0) ? wavData[1][1][index] : 0) * (width / 1.12), -hSize, hSize) / 2;

			waveformSprite.pixels.fillRect(new Rectangle(hSize - (lmin + rmin), index * size, (lmin + rmin) + (lmax + rmax), size), FlxColor.BLUE);
		}

		waveformPrinted = true;
		#end
	}

	function waveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, multiply:Float = 1, ?array:Array<Array<Array<Float>>>, ?steps:Float):Array<Array<Array<Float>>> {
		#if (lime_cffi && !macro)
		if (buffer == null || buffer.data == null) return [[[0], [0]], [[0], [0]]];

		var khz:Float = (buffer.sampleRate / 1000);
		var channels:Int = buffer.channels;

		var index:Int = Std.int(time * khz);
		var samples:Float = ((endTime - time) * khz);

		if (steps == null) steps = 1280;

		var samplesPerRow:Float = samples / steps;
		var samplesPerRowI:Int = Std.int(samplesPerRow);

		var gotIndex:Int = 0;

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var rows:Float = 0;

		var simpleSample:Bool = true;

		if (array == null) array = [[[0], [0]], [[0], [0]]];

		while (index < (bytes.length - 1)) {
			if (index >= 0) {
				var byte:Int = bytes.getUInt16(index * channels * 2);

				if (byte > 65535 / 2) byte -= 65535;

				var sample:Float = (byte / 65535);

				if (sample > 0 && sample > lmax) lmax = sample;
				else if (sample < 0 && sample < lmin) lmin = sample;

				if (channels >= 2) {
					byte = bytes.getUInt16((index * channels * 2) + 2);

					if (byte > 65535 / 2) byte -= 65535;

					sample = (byte / 65535);

					if (sample > 0 && sample > rmax) rmax = sample;
					else if (sample < 0 && sample < rmin) rmin = sample;
				}
			}

			var v1:Bool = samplesPerRowI > 0 ? (index % samplesPerRowI == 0) : false;
			while (simpleSample ? v1 : rows >= samplesPerRow) {
				v1 = false;
				rows -= samplesPerRow;

				gotIndex++;

				var lRMin:Float = Math.abs(lmin) * multiply;
				var lRMax:Float = lmax * multiply;

				var rRMin:Float = Math.abs(rmin) * multiply;
				var rRMax:Float = rmax * multiply;

				if (gotIndex > array[0][0].length) array[0][0].push(lRMin);
				else array[0][0][gotIndex - 1] += lRMin;

				if (gotIndex > array[0][1].length) array[0][1].push(lRMax);
				else array[0][1][gotIndex - 1] += lRMax;

				if (channels >= 2) {
					if (gotIndex > array[1][0].length) array[1][0].push(rRMin);
					else array[1][0][gotIndex - 1] += rRMin;

					if (gotIndex > array[1][1].length) array[1][1].push(rRMax);
					else array[1][1][gotIndex - 1] += rRMax;
				} else {
					if (gotIndex > array[1][0].length) array[1][0].push(lRMin);
					else array[1][0][gotIndex - 1] += lRMin;

					if (gotIndex > array[1][1].length) array[1][1].push(lRMax);
					else array[1][1][gotIndex - 1] += lRMax;
				}

				lmin = 0;
				lmax = 0;

				rmin = 0;
				rmax = 0;
			}

			index++;
			rows++;
			if(gotIndex > steps) break;
		}

		return array;
		#else
		return [[[0], [0]], [[0], [0]]];
		#end
	}

	function changeNoteSustain(value:Float):Void {
		if (curSelectedNote != null && curSelectedNote[2] != null) {
			curSelectedNote[2] += Math.ceil(value);
			curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
		}

		updateNoteUI();
		updateGrid();
	}

	function recalculateSteps():Int {
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length) {
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void {
		updateGrid();

		FlxG.sound.music.pause();
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning) {
			FlxG.sound.music.time = 0;
			curSec = 0;
		}

		pauseAndSetVocalsTime();
		updateCurStep();

		updateGrid();
		updateSectionUI();
		updateWaveform();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void {
		var waveformChanged:Bool = false;
		if (_song.notes[sec] != null) {
			curSec = sec;
			if (updateMusic) {
				FlxG.sound.music.pause();
				FlxG.sound.music.time = sectionStartTime();
				pauseAndSetVocalsTime();
				updateCurStep();
			}

			var blah1:Float = getSectionBeats();
			var blah2:Float = getSectionBeats(curSec + 1);
			if(sectionStartTime(1) > FlxG.sound.music.length) blah2 = 0;
	
			if(blah1 != lastSecBeats || blah2 != lastSecBeatsNext) {
				reloadGridLayer();
				waveformChanged = true;
			} else updateGrid();
			updateSectionUI();
		} else changeSection();
		Conductor.songPosition = FlxG.sound.music.time;
		if(!waveformChanged) updateWaveform();
	}

	function updateSectionUI():Void {
		var sec:backend.Section.SwagSection = _song.notes[curSec];

		stepperBeats.value = getSectionBeats();
		check_mustHitSection.checked = sec.mustHitSection;
		check_gfSection.checked = sec.gfSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	var characterData:Dynamic = {iconP1: null, iconP2: null};
	function updateJsonData():Void {
		for (i in 1...3) Reflect.setField(characterData, 'iconP$i', !characterFailed ? loadCharacterFile(Reflect.field(_song, 'player$i')).healthicon : 'face');
	}

	function updateHeads():Void {
		if (_song.notes[curSec].mustHitSection) {
			leftIcon.changeIcon(characterData.iconP1);
			rightIcon.changeIcon(characterData.iconP2);
			if (_song.notes[curSec].gfSection) leftIcon.changeIcon('gf');
		} else {
			leftIcon.changeIcon(characterData.iconP2);
			rightIcon.changeIcon(characterData.iconP1);
			if (_song.notes[curSec].gfSection) leftIcon.changeIcon('gf');
		}
	}

	var characterFailed:Bool = false;
	function loadCharacterFile(char:String):CharacterFile {
		characterFailed = false;
		var characterPath:String = 'characters/$char.json';
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path)) path = Paths.getSharedPath(characterPath);
		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getSharedPath(characterPath);
		if (!Assets.exists(path))
		#end
		{
			path = Paths.getSharedPath('characters/${Character.DEFAULT_CHARACTER}.json'); //If a character couldn't be found, change him to BF just to prevent a crash
			characterFailed = true;
		}

		return cast Json.parse(#if MODS_ALLOWED File.getContent #else Assets.getText #end(path));
	}

	function updateNoteUI():Void {
		if (curSelectedNote != null) {
			if(curSelectedNote[2] != null) {
				stepperSusLength.value = curSelectedNote[2];
				if(curSelectedNote[3] != null) {
					currentType = curNoteTypes.indexOf(curSelectedNote[3]);
					if(currentType <= 0) noteTypeDropDown.selectedLabel = '';
					else noteTypeDropDown.selectedLabel = '$currentType. ${curSelectedNote[3]}';
				}
			} else {
				eventDropDown.selectedLabel = curSelectedNote[1][curEventSelected][0];
				var selected:Int = eventDropDown.selectedIndex;
				if(selected > 0 && selected < eventStuff.length)
					descText.text = eventStuff[selected][1];
				value1InputText.text = curSelectedNote[1][curEventSelected][1];
				value2InputText.text = curSelectedNote[1][curEventSelected][2];
			}
			strumTimeInputText.text = Std.string(curSelectedNote[0]);
		}
	}

	function updateGrid():Void {
		curRenderedNotes.forEachAlive((spr:Note) -> spr.destroy());
		curRenderedNotes.clear();
		curRenderedSustains.forEachAlive((spr:FlxSprite) -> spr.destroy());
		curRenderedSustains.clear();
		curRenderedNoteType.forEachAlive((spr:FlxText) -> spr.destroy());
		curRenderedNoteType.clear();
		nextRenderedNotes.forEachAlive((spr:Note) -> spr.destroy());
		nextRenderedNotes.clear();
		nextRenderedSustains.forEachAlive((spr:FlxSprite) -> spr.destroy());
		nextRenderedSustains.clear();

		if (_song.notes[curSec].changeBPM && _song.notes[curSec].bpm > 0)
			Conductor.bpm = _song.notes[curSec].bpm;
		else { // get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSec) if (_song.notes[i].changeBPM) daBPM = _song.notes[i].bpm;
			Conductor.bpm = daBPM;
		}

		// CURRENT SECTION
		var beats:Float = getSectionBeats();
		for (i in _song.notes[curSec].sectionNotes) {
			var note:Note = setupNoteData(i, false);
			curRenderedNotes.add(note);
			if (note.sustainLength > 0) curRenderedSustains.add(setupSusNote(note, beats));

			if(i[3] != null && note.noteType != null && note.noteType.length > 0) {
				var typeInt:Int = curNoteTypes.indexOf(i[3]);
				var theType:String = '' + typeInt;
				if(typeInt < 0) theType = '?';

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 100, theType, 24);
				daText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
				daText.setBorderStyle(OUTLINE_FAST, FlxColor.BLACK);
				daText.textoffset.set(-32, 6);
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
			}
			note.mustPress = _song.notes[curSec].mustHitSection;
			if(i[1] > _song.mania) note.mustPress = !note.mustPress;
		}

		// CURRENT EVENTS
		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);
		for (i in _song.events) {
			if(endThing > i[0] && i[0] >= startThing) {
				var note:Note = setupNoteData(i, false);
				curRenderedNotes.add(note);

				var text:String = 'Event: ${note.eventName} (${Math.floor(note.strumTime)} ms)\nValue 1: ${note.eventVal1}\nValue 2: ${note.eventVal2}';
				if(note.eventLength > 1) text = note.eventLength + ' Events:\n' + note.eventName;

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 400, text, 12);
				daText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT);
				daText.setBorderStyle(OUTLINE_FAST, FlxColor.BLACK);
				daText.textoffset.x = -410;
				if(note.eventLength > 1) daText.textoffset.y += 8;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
			}
		}

		// NEXT SECTION
		var beats:Float = getSectionBeats(1);
		if(curSec < _song.notes.length - 1) {
			for (i in _song.notes[curSec + 1].sectionNotes) {
				var note:Note = setupNoteData(i, true);
				note.alpha = .6;
				nextRenderedNotes.add(note);
				if (note.sustainLength > 0) nextRenderedSustains.add(setupSusNote(note, beats));
			}
		}

		// NEXT EVENTS
		var startThing:Float = sectionStartTime(1);
		var endThing:Float = sectionStartTime(2);
		for (i in _song.events) {
			if(endThing > i[0] && i[0] >= startThing) {
				var note:Note = setupNoteData(i, true);
				note.alpha = .6;
				nextRenderedNotes.add(note);
			}
		}
	}

	function setupNoteData(i:Array<Dynamic>, isNextSection:Bool):Note {
		var daNoteInfo = i[1];
		var daStrumTime = i[0];
		var daSus:Dynamic = i[2];

		var note:Note = new Note(daStrumTime, daNoteInfo % EK.keys(_song.mania), null, null, true);
		if(daSus != null) { //Common note
			if(!Std.isOfType(i[3], String)) i[3] = curNoteTypes[i[3]]; //Convert old note type to new note type format
			if(i.length > 3 && (i[3] == null || i[3].length < 1)) i.remove(i[3]);
			note.sustainLength = daSus;
			note.noteType = i[3];
		} else { //Event note
			note.loadGraphic(Paths.image('eventArrow'));
			note.rgbShader.enabled = false;
			note.eventName = getEventName(i[1]);
			note.eventLength = i[1].length;
			if(i[1].length < 2) {
				note.eventVal1 = i[1][0][1];
				note.eventVal2 = i[1][0][2];
			}
			note.noteData = -1;
			daNoteInfo = -1;
		}

		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.x = Math.floor(daNoteInfo * GRID_SIZE) + GRID_SIZE;
		if(isNextSection && _song.notes[curSec].mustHitSection != _song.notes[curSec + 1].mustHitSection) {
			if(daNoteInfo > _song.mania) note.x -= GRID_SIZE * EK.keys(_song.mania);
			else if(daSus != null) note.x += GRID_SIZE * EK.keys(_song.mania);
		}

		var beats:Float = getSectionBeats(isNextSection ? 1 : 0);
		note.y = getYfromStrumNotes(daStrumTime - sectionStartTime(), beats);
		if(note.y < -150) note.y = -150;
		return note;
	}

	function getEventName(names:Array<Dynamic>):String {
		var retStr:String = '';
		var addedOne:Bool = false;
		for (i in 0...names.length) {
			if(addedOne) retStr += ', ';
			retStr += names[i][0];
			addedOne = true;
		}
		return retStr;
	}

	function setupSusNote(note:Note, beats:Float):FlxSprite {
		var height:Int = Math.floor(FlxMath.remapToRange(note.sustainLength, 0, Conductor.stepCrochet * 16, 0, GRID_SIZE * 16 * zoomList[curZoom]) + (GRID_SIZE * zoomList[curZoom]) - GRID_SIZE / 2);
		var minHeight:Int = Std.int((GRID_SIZE * zoomList[curZoom] / 2) + GRID_SIZE / 2);
		if(height < minHeight) height = minHeight;
		if(height < 1) height = 1; //Prevents error of invalid height

		return new FlxSprite(note.x + (GRID_SIZE * .5) - 4, note.y + GRID_SIZE / 2).makeGraphic(8, height);
	}

	function addSection(sectionBeats:Float = 4):Void {
		_song.notes.push({
			sectionBeats: sectionBeats,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			gfSection: false,
			sectionNotes: [],
			altAnim: false
		});
	}

	function selectNote(note:Note):Void {
		var noteDataToCheck:Int = note.noteData;

		if(noteDataToCheck > -1) {
			if(note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += EK.keys(_song.mania);
			for (i in _song.notes[curSec].sectionNotes) {
				if (i != curSelectedNote && i.length > 2 && i[0] == note.strumTime && i[1] == noteDataToCheck) {
					curSelectedNote = i;
					break;
				}
			}
		} else {
			for (i in _song.events) {
				if(i != curSelectedNote && i[0] == note.strumTime) {
					curSelectedNote = i;
					curEventSelected = Std.int(curSelectedNote[1].length) - 1;
					break;
				}
			}
		}
		changeEventSelected();

		updateGrid();
		updateNoteUI();
	}

	function deleteNote(note:Note):Void {
		var noteDataToCheck:Int = note.noteData;
		if(noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += EK.keys(_song.mania);

		if(note.noteData > -1) { //Normal Notes
			for (i in _song.notes[curSec].sectionNotes) {
				if (i[0] == note.strumTime && i[1] == noteDataToCheck) {
					lastNoteData = Math.floor((FlxG.mouse.x - GRID_SIZE) / GRID_SIZE);
					lastNoteStrum = getStrumTime(dummyArrow.y, false) + sectionStartTime();
					if(i == curSelectedNote) curSelectedNote = null;
					_song.notes[curSec].sectionNotes.remove(i);
					break;
				}
			}
		} else { //Events
			for (i in _song.events) {
				if(i[0] == note.strumTime) {
					if(i == curSelectedNote) {
						curSelectedNote = null;
						changeEventSelected();
					}
					_song.events.remove(i);
					break;
				}
			}
		}

		updateGrid();
	}

	public function doANoteThing(cs, d, style):Void {
		var delnote:Bool = false;
		if(strumLineNotes.members[d].overlaps(curRenderedNotes)) {
			curRenderedNotes.forEachAlive((note:Note) -> {
				if (note.overlapsPoint(FlxPoint.weak(strumLineNotes.members[d].x + 1, strumLine.y + 1)) && note.noteData == d % EK.keys(_song.mania)) {
					if(!delnote) deleteNote(note);
					delnote = true;
				}
			});
		}

		if (!delnote) addNote(cs, d, style);
	}

	function addNote(strum:Null<Float> = null, data:Null<Int> = null, type:Null<Int> = null):Void {
		var noteStrum:Float = getStrumTime(dummyArrow.y * (getSectionBeats() / 4), false) + sectionStartTime();
		var noteData:Int = Math.floor((FlxG.mouse.x - GRID_SIZE) / GRID_SIZE);
		var noteSus:Int = 0;
		var daType:Int = currentType;

		if (strum != null) noteStrum = strum;
		if (data != null) noteData = data;
		if (type != null) daType = type;

		if(noteData > -1) {
			_song.notes[curSec].sectionNotes.push([noteStrum, noteData, noteSus, curNoteTypes[daType]]);
			curSelectedNote = _song.notes[curSec].sectionNotes[_song.notes[curSec].sectionNotes.length - 1];
		} else {
			_song.events.push([noteStrum, [[eventStuff[eventDropDown.selectedIndex][0], value1InputText.text, value2InputText.text]]]);
			curSelectedNote = _song.events[_song.events.length - 1];
			curEventSelected = 0;
		}
		changeEventSelected();

		if (FlxG.keys.pressed.CONTROL && noteData > -1)
			_song.notes[curSec].sectionNotes.push([noteStrum, (noteData + EK.keys(_song.mania)) % EK.strums(_song.mania), noteSus, curNoteTypes[daType]]);

		strumTimeInputText.text = '' + curSelectedNote[0];

		lastNoteData = noteData;
		lastNoteStrum = noteStrum;

		updateGrid();
		updateNoteUI();
	}

	function getStrumTime(yPos:Float, doZoomCalc:Bool = true):Float {
		var leZoom:Float = zoomList[curZoom];
		if(!doZoomCalc) leZoom = 1;
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height * leZoom, 0, 16 * Conductor.stepCrochet);
	}
	function getYfromStrum(strumTime:Float, doZoomCalc:Bool = true):Float {
		var leZoom:Float = zoomList[curZoom];
		if(!doZoomCalc) leZoom = 1;
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height * leZoom);
	}
	function getYfromStrumNotes(strumTime:Float, beats:Float):Float {
		var value:Float = strumTime / (beats * 4 * Conductor.stepCrochet);
		return GRID_SIZE * beats * 4 * zoomList[curZoom] * value + gridBG.y;
	}

	var missingText:FlxText;
	var missingTextTimer:FlxTimer;
	function loadJson(song:String):Void {
		try {
			if (Difficulty.getString() != Difficulty.getDefault()) {
				if(Difficulty.getString() == null)
					PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
				else PlayState.SONG = Song.loadFromJson(song.toLowerCase() + "-" + Difficulty.getString(), song.toLowerCase());
			} else PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
			Paths.clearUnusedMemory();
			FlxG.resetState();
		} catch(e) {
			var errorStr:String = e.toString();
			if(errorStr.startsWith('[lime.utils.Assets] ERROR:')) errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(Paths.formatToSongPath(PlayState.SONG.song)), errorStr.length - 1); //Missing chart
			
			if(missingText == null) {
				missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
				missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				missingText.scrollFactor.set();
				add(missingText);
			} else missingTextTimer.cancel();

			missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
			missingText.screenCenter(Y);

			missingTextTimer = FlxTimer.wait(5, () -> {
				remove(missingText);
				missingText.destroy();
			});
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}
	}

	function autosaveSong():Void {
		FlxG.save.data.autosave = Json.stringify({"song": _song});
		FlxG.save.flush();
	}

	function clearEvents() {
		_song.events = [];
		updateGrid();
	}

	function saveLevel() {
		if(_song.events != null && _song.events.length > 1) _song.events.sort(sortByTime);
		var data:String = Json.stringify({"song": _song}, "\t");
		if (data != null && data.length > 0) {
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), convPathShit(getCurrrentDataPath()));
		}
	}

	function getCurrrentDataPath():String {
		var diffSuffix:String = Difficulty.getString() != null && Difficulty.getString() != Difficulty.getDefault() ? "-" + Difficulty.getString().toLowerCase() : "";
		var songPath:String = '${Paths.CHART_PATH}/$currentSongName/$currentSongName$diffSuffix';

		var path:String;
		#if MODS_ALLOWED
		path = Paths.modsJson(songPath);
		if (!FileSystem.exists(path))
		#end
			path = Paths.json(songPath);

		return path;
	}

	function convPathShit(path:String):String {
		path = Path.normalize(Sys.getCwd() + path);
		#if windows path = path.replace("/", "\\"); #end
		return path;
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	function saveEvents() {
		if(_song.events != null && _song.events.length > 1) _song.events.sort(sortByTime);
		var data:String = Json.stringify({"song": {events: _song.events}}, "\t");
		if (data != null && data.length > 0) {
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), convPathShit(Path.directory(getCurrrentDataPath()) + "/events.json"));
		}
	}

	function onSaveComplete(_):Void {
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
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function getSectionBeats(?section:Null<Int> = null) {
		if (section == null) section = curSec;
		var val:Null<Float> = null;
		
		if(_song.notes[section] != null) val = _song.notes[section].sectionBeats;
		return val ?? 4;
	}
}