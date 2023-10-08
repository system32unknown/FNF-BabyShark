package backend.subtitles;

typedef SubtitleProperties = {
    var ?x:Float;
    var ?y:Float;
    var ?subtitleSize:Int;
    var ?typeSpeed:Float;
    var ?centerScreen:Bool;
    var ?screenCenter:flixel.util.FlxAxes;
    var ?sounds:Array<FlxSound>;
    var ?fonts:String;
}