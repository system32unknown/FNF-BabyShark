package utils.math;

import utils.MathUtil;

class VectorHelpers {
	public static function project(pos:Vector3, resultVector:Null<Vector3> = null, cameraMaxSize:Float = 1280):Vector3 {
		if (resultVector == null) resultVector = new Vector3();
		resultVector.z = pos.z / -cameraMaxSize;
		resultVector.y = pos.y / resultVector.z;
		resultVector.x = pos.x / resultVector.z;
		return resultVector;
	}

	// thanks schmoovin'
	public static function rotateV3(vec:Vector3, xA:Float, yA:Float, zA:Float, resultVector:Null<Vector3> = null):Vector3 {
		var rotateZ:FlxPoint = MathUtil.rotate(vec.x, vec.y, zA);
		var rotateY:FlxPoint = MathUtil.rotate(rotateZ.x, vec.z, yA);
		var rotateX:FlxPoint = MathUtil.rotate(rotateY.y, rotateZ.y, xA);

		if (resultVector == null) resultVector = new Vector3();
		resultVector.x = rotateY.x;
		resultVector.y = rotateX.y;
		resultVector.z = rotateX.x;

		rotateZ.putWeak();
		rotateX.putWeak();
		rotateY.putWeak();

		return resultVector;
	}

	public static function toArray(vec:Vector3, ?resultArray:Array<Float>):Array<Float> {
		if (resultArray == null) resultArray = [];
		else resultArray = [vec.x, vec.y, vec.z];
		return resultArray;
	}
}
