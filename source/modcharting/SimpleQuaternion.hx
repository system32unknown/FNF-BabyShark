package modcharting;

import flixel.math.FlxAngle;

typedef Quaternion = {
	var x:Float;
	var y:Float;
	var z:Float;
	var w:Float;
};

// me whenthe
class SimpleQuaternion {
	// no more gimbal lock fuck you
	public static function fromEuler(roll:Float, pitch:Float, yaw:Float):Quaternion {
		// https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
		var cr = FlxMath.fastCos(roll * FlxAngle.TO_RAD);
		var sr = FlxMath.fastSin(roll * FlxAngle.TO_RAD);
		var cp = FlxMath.fastCos(pitch * FlxAngle.TO_RAD);
		var sp = FlxMath.fastSin(pitch * FlxAngle.TO_RAD);
		var cy = FlxMath.fastCos(yaw * FlxAngle.TO_RAD);
		var sy = FlxMath.fastSin(yaw * FlxAngle.TO_RAD);

		var q:Quaternion = {x: 0, y: 0, z: 0, w: 0};
		q.w = cr * cp * cy + sr * sp * sy;
		q.x = sr * cp * cy - cr * sp * sy;
		q.y = cr * sp * cy + sr * cp * sy;
		q.z = cr * cp * sy - sr * sp * cy;
		return q;
	}

	public static function normalize(q:Quaternion):Quaternion {
		var length:Float = Math.sqrt(q.w * q.w + q.x * q.x + q.y * q.y + q.z * q.z);
		q.w = q.w / length;
		q.x = q.x / length;
		q.y = q.y / length;
		q.z = q.z / length;
		return q;
	}

	public static function conjugate(q:Quaternion):Quaternion {
		q.y = -q.y;
		q.z = -q.z;
		q.w = -q.w;
		return q;
	}

	public static function multiply(q1:Quaternion, q2:Quaternion):Quaternion {
		var x:Float = q1.x * q2.x - q1.y * q2.y - q1.z * q2.z - q1.w * q2.w;
		var y:Float = q1.x * q2.y + q1.y * q2.x + q1.z * q2.w - q1.w * q2.z;
		var z:Float = q1.x * q2.z - q1.y * q2.w + q1.z * q2.x + q1.w * q2.y;
		var w:Float = q1.x * q2.w + q1.y * q2.z - q1.z * q2.y + q1.w * q2.x;

		q1.x = x;
		q1.y = y;
		q1.z = z;
		q1.w = w;

		return q1;
	}
}
