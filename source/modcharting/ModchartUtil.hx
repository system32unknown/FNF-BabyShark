package modcharting;

import openfl.geom.Vector3D;
import objects.Note;

class ModchartUtil {

	public static function getScrollSpeed(?instance:PlayState = null):Float {
		if (instance == null) return PlayState.SONG.speed;
		return instance.songSpeed;
	}

	public static function getIsPixelStage(?instance:ModchartMusicBeatState = null):Bool {
		if (instance == null) return false;
		return PlayState.isPixelStage;
	}

	static var currentFakeCrochet:Float = -1;
	static var lastBpm:Float = -1;

	public static function getFakeCrochet():Float {
		if (PlayState.SONG.bpm != lastBpm) {
			currentFakeCrochet = (60 / PlayState.SONG.bpm) * 1000; // only need to calculate once
			lastBpm = PlayState.SONG.bpm;
		}
		return currentFakeCrochet;
	}

	public static var zNear:Float = 0;
	public static var zFar:Float = 100;
	public static var defaultFOV:Float = 90;

	/**
		Converts a Vector3D to its in world coordinates using perspective math
	**/
	public static function calculatePerspective(pos:Vector3D, FOV:Float, offsetX:Float = 0, offsetY:Float = 0):Vector3D {
		var newz = pos.z - 1;
		var zRange = zNear - zFar;
		var tanHalfFOV = FlxMath.fastSin(FOV * .5) / FlxMath.fastCos(FOV * .5); // faster tan
		if (pos.z > 1)  newz = 0; //if above 1000 z basically, should stop weird mirroring with high z values

		var xOffsetToCenter = pos.x - (FlxG.width * 0.5); // so the perspective focuses on the center of the screen
		var yOffsetToCenter = pos.y - (FlxG.height * 0.5);

		var zPerspectiveOffset = (newz + (2 * zFar * zNear / zRange));

		xOffsetToCenter += (offsetX * -zPerspectiveOffset);
		yOffsetToCenter += (offsetY * -zPerspectiveOffset);

		var xPerspective = xOffsetToCenter * (1 / tanHalfFOV);
		var yPerspective = yOffsetToCenter * tanHalfFOV;
		xPerspective /= -zPerspectiveOffset;
		yPerspective /= -zPerspectiveOffset;

		pos.x = xPerspective + (FlxG.width * 0.5); // offset it back to normal
		pos.y = yPerspective + (FlxG.height * 0.5);
		pos.z = zPerspectiveOffset;

		return pos;
	}

	/**
		Returns in-world 3D coordinates using polar angle, azimuthal angle and a radius.
		(Spherical to Cartesian)

		@param	theta Angle used along the polar axis.
		@param	phi Angle used along the azimuthal axis.
		@param	radius Distance to center.
	**/
	public static function getCartesianCoords3D(theta:Float, phi:Float, radius:Float):Vector3D {
		var pos:Vector3D = new Vector3D();
		var rad:Float = flixel.math.FlxAngle.TO_RAD;
		pos.x = FlxMath.fastCos(theta * rad) * FlxMath.fastSin(phi * rad);
		pos.y = FlxMath.fastCos(phi * rad);
		pos.z = FlxMath.fastSin(theta * rad) * FlxMath.fastSin(phi * rad);
		pos.x *= radius;
		pos.y *= radius;
		pos.z *= radius;
		return pos;
	}

	public static function getTimeFromBeat(beat:Float):Float {
		var totalTime:Float = 0;
		var curBpm:Float = Conductor.bpm;
		if (PlayState.SONG != null) curBpm = PlayState.SONG.bpm;
		for (i in 0...Math.floor(beat)) {
			if (Conductor.bpmChangeMap.length > 0) {
				for (j in 0...Conductor.bpmChangeMap.length) {
					if (totalTime >= Conductor.bpmChangeMap[j].songTime)
						curBpm = Conductor.bpmChangeMap[j].bpm;
				}
			}
			totalTime += (60 / curBpm) * 1000;
		}

		var leftOverBeat:Float = beat - Math.floor(beat);
		totalTime += (60 / curBpm) * 1000 * leftOverBeat;

		return totalTime;
	}
}
