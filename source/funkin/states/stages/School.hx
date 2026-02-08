package funkin.states.stages;

import funkin.substates.GameOverSubstate;

class School extends BaseStage {
	override function create() {
		var _song:funkin.backend.Song.SwagSong = PlayState.SONG;
		if (_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
		if (_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverSubstate.loopSoundName = 'gameOver-pixel';
		if (_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
		if (_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverSubstate.characterName = 'bf-pixel-dead';

		var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
		bgSky.zIndex = 10;
		add(bgSky);
		bgSky.antialiasing = false;

		var repositionShit:Int = -200;

		var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
		bgSchool.zIndex = 20;
		add(bgSchool);
		bgSchool.antialiasing = false;

		var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
		bgStreet.zIndex = 30;
		add(bgStreet);
		bgStreet.antialiasing = false;

		var widShit = Std.int(bgSky.width * PlayState.daPixelZoom);
		if (!lowQuality) {
			var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
			fgTrees.setGraphicSize(Std.int(widShit * 0.8));
			fgTrees.updateHitbox();
			fgTrees.zIndex = 40;
			add(fgTrees);
			fgTrees.antialiasing = false;
		}

		var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
		bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
		bgTrees.animation.add('treeLoop', [for (i in 0...18) i], 12);
		bgTrees.animation.play('treeLoop');
		bgTrees.scrollFactor.set(.85, .85);
		bgTrees.zIndex = 60;
		add(bgTrees);
		bgTrees.antialiasing = false;

		if (!lowQuality) {
			var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
			treeLeaves.setGraphicSize(widShit);
			treeLeaves.updateHitbox();
			treeLeaves.zIndex = 70;
			add(treeLeaves);
			treeLeaves.antialiasing = false;
		}

		bgSky.setGraphicSize(widShit);
		bgSchool.setGraphicSize(widShit);
		bgStreet.setGraphicSize(widShit);
		bgTrees.setGraphicSize(Std.int(widShit * 1.4));

		bgSky.updateHitbox();
		bgSchool.updateHitbox();
		bgStreet.updateHitbox();
		bgTrees.updateHitbox();

		setDefaultGF('gf-pixel');
	}
}