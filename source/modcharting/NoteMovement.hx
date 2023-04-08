package modcharting;

import flixel.math.FlxMath;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.FlxG;

import states.PlayState;
import game.Note;

class NoteMovement
{
    public static var keyCount = 4;
    public static var playerKeyCount = 4;
    public static var arrowScale:Float = 0.7;
    public static var arrowSize:Float = 112;
    public static var defaultStrumX:Array<Float> = [];
    public static var defaultStrumY:Array<Float> = [];
    public static var defaultScale:Array<Float> = [];
    public static var arrowSizes:Array<Float> = [];
    public static function getDefaultStrumPos(game:PlayState)
    {
        defaultStrumX = []; //reset
        defaultStrumY = []; 
        defaultScale = [];
        arrowSizes = [];

        for (i in 0...game.strumLineNotes.members.length)
        {
            var strum = game.strumLineNotes.members[i];
            defaultStrumX.push(strum.x);
            defaultStrumY.push(strum.y);
            var s = 0.7;

            defaultScale.push(s);
            arrowSizes.push(160*s);
        }
    }
    public static function getDefaultStrumPosEditor(game:ModchartEditorState)
    {
        defaultStrumX = []; //reset
        defaultStrumY = []; 
        defaultScale = [];
        arrowSizes = [];
        keyCount = game.strumLineNotes.length-game.playerStrums.length; //base game doesnt have opponent strums as group
        playerKeyCount = game.playerStrums.length;

        for (i in 0...game.strumLineNotes.members.length)
        {
            var strum = game.strumLineNotes.members[i];
            defaultStrumX.push(strum.x);
            defaultStrumY.push(strum.y);
            var s = 0.7;
            defaultScale.push(s);
            arrowSizes.push(160*s);
        }
    }
    public static function setNotePath(daNote:Note, lane:Int, scrollSpeed:Float, curPos:Float, noteDist:Float, incomingAngleX:Float, incomingAngleY:Float)
    {
        daNote.setPosition(defaultStrumX[lane], defaultStrumY[lane]);
        daNote.z = 0;

        var pos = ModchartUtil.getCartesianCoords3D(incomingAngleX,incomingAngleY, curPos*noteDist);
        daNote.y += pos.y;
        daNote.x += pos.x;
        daNote.z += pos.z;
    }

    public static function getLaneDiffFromCenter(lane:Int)
    {
        var col:Float = lane % 4;
        if (col + 1 > keyCount * .5)
            col -= (keyCount * .5) + 1;
        else col -= (keyCount * .5);

        return col;
    }
}

