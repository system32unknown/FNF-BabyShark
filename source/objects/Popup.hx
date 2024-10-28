package objects;

enum PopupType {
    NONE;
    RATING;
    NUMBER;
}
class Popup extends FlxSprite {
    public var type:PopupType;
    public var popUpTime:Float = 0;
	var placement:Float = FlxG.width * 0.35;
    var i:PlayState;
    
    public static var antialias:Bool = true;
    var comboOffset:Array<Array<Int>> = ClientPrefs.data.comboOffset;

    public function new() {
        super();
        type = NONE;
        i = PlayState.instance;
    }
    
    var texture:Popup;
    public function reloadTexture(target:String):Popup {
        popUpTime = Conductor.songPosition;
        if (Paths.popUpFramesMap.exists(target)) {
            this.frames = Paths.popUpFramesMap.get(target);
            return this;
        } else {
            texture = cast loadGraphic(Paths.image(target));
            Paths.popUpFramesMap.set(target, this.frames);
            return texture;
        }
    }

    // ╔═════════════════════╗
    // ║ RATING SPRITE STUFF ║
    // ╚═════════════════════╝
    public function setupRatingData(rateImg:String) {
        type = RATING;
        reloadTexture(rateImg);
        screenCenter(Y).y -= 60 + comboOffset[0][1];
		x = placement - 40 + comboOffset[0][0];
        acceleration.set(i.ratingAcc.x * i.playbackRate * i.playbackRate, 550 * i.playbackRate * i.playbackRate + i.ratingAcc.y);
        velocity.set(-FlxG.random.int(0, 10) * i.playbackRate + i.ratingVel.x, -FlxG.random.int(140, 175) * i.playbackRate + i.ratingVel.y);
        visible = (!ClientPrefs.data.hideHud && i.showRating);
        antialiasing = antialias;
        
        setGraphicSize(Std.int(width * (PlayState.isPixelStage ? 0.85 * PlayState.daPixelZoom : 0.7)));
        updateHitbox();
    }
    public function ratingOtherStuff() {
        FlxTween.tween(this, {alpha: 0}, 0.2 / i.playbackRate, {onComplete: (tween:FlxTween) -> kill(), startDelay: .7 / i.playbackRate});
    }

    // ╔═════════════════════╗
    // ║ NUMBER SPRITE STUFF ║
    // ╚═════════════════════╝
    public function setupNumberData(numberImg:String, daloop:Int) {
        type = NUMBER;
        reloadTexture(numberImg);
        setPosition(x + (43 * daloop++) - 50 + comboOffset[1][0], 80 - comboOffset[1][1]);
		velocity.set(FlxG.random.float(-5, 5) * i.playbackRate + i.ratingVel.x, -FlxG.random.int(130, 150) * i.playbackRate + i.ratingVel.y);
		acceleration.set(i.ratingAcc.x * i.playbackRate * i.playbackRate, FlxG.random.int(250, 300) * i.playbackRate * i.playbackRate + i.ratingAcc.y);
        setGraphicSize(Std.int(width * (PlayState.isPixelStage ? PlayState.daPixelZoom : 0.5)));
        updateHitbox();
        
        visible = !ClientPrefs.data.hideHud;
        antialiasing = antialias;
    }
    public function numberOtherStuff() {
        FlxTween.tween(this, {alpha: 0}, 0.2 / i.playbackRate, {onComplete: (tween:FlxTween) -> kill(), startDelay: 1.4 / i.playbackRate});
    }

    override public function kill() {
        type = NONE;
        super.kill();
    }
    override public function revive() {
        super.revive();
        initVars();
        acceleration.x = acceleration.y = velocity.x = velocity.y = x = y = 0;
        alpha = 1;
        visible = true;
    }
}