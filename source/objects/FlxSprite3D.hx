package objects;

import flixel.system.FlxAssets.FlxShader;
import flixel.math.FlxAngle;
import utils.math.Vector3;
import openfl.Vector;
import openfl.geom.ColorTransform;

using utils.math.VectorHelpers;

class FlxSprite3D extends FlxSprite {
	public var z:Float = 0;

	public var yaw:Float = 0;
	public var pitch:Float = 0;
	public var roll(get, set):Float;
	function get_roll():Float return angle;
	function set_roll(val:Float):Float return angle = val;

	////
	var _camPos:Vector3 = new Vector3();
	var _camOrigin:Vector3 = new Vector3(); // vertex origin
	var _sprPos:Vector3 = new Vector3();
	var quad0:Vector3 = new Vector3();
	var quad1:Vector3 = new Vector3();
	var quad2:Vector3 = new Vector3();
	var quad3:Vector3 = new Vector3();
	var _vertices:Vector<Float> = new Vector<Float>(12);
	var _indices:Vector<Int> = new Vector<Int>(12, false, [for (i in 0...12) i]);
	var _uvData:Vector<Float> = new Vector<Float>(12);
	
	var _triangleColorTransforms:Array<ColorTransform>;
	var _3DColor:ColorTransform = new ColorTransform();

	public function new(x:Float, y:Float, z:Float, g:flixel.system.FlxAssets.FlxGraphicAsset) {
		super(x, y, g);
		this.z = z;

		_triangleColorTransforms = [_3DColor, _3DColor]; 
	}

	public function setPos(x:Float, y:Float, z:Float) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	override public function draw():Void {
		checkEmptyFrame();

		if (alpha == 0 || _frame.type == flixel.graphics.frames.FlxFrame.FlxFrameType.EMPTY) return;

		if (dirty) calcFrame(useFramePixels); // rarely
		if (this.shader == null) this.shader = new FlxShader();

		shader.bitmap.input = graphic.bitmap;
		shader.bitmap.filter = antialiasing ? LINEAR : NEAREST;

		// TODO: take origin into consideration properly
		var wid:Int = frameWidth;
		var hei:Int = frameHeight;

		var halfW:Float = wid * .5;
		var halfH:Float = hei * .5;

		var radPitch:Float = FlxAngle.TO_RAD * pitch;
		var radYaw:Float = FlxAngle.TO_RAD * yaw;
		var radRoll:Float = FlxAngle.TO_RAD * roll;

		var spriteOrigin:FlxPoint = FlxPoint.weak();
		spriteOrigin.set(origin.x - halfW, origin.y - halfH);

		for (camera in cameras) {
			if (!camera.visible || !camera.exists || camera.canvas == null || camera.canvas.graphics == null) continue;

			_sprPos.setTo(this.x - this.offset.x, this.y - this.offset.y, this.z - camera.scrollZ);
			_point.set(_sprPos.x, _sprPos.y);

			var cameraMaxSize:Float = Math.max(camera.width, camera.height);
			_camPos.setTo(camera.scroll.x * this.scrollFactor.x, camera.scroll.y * this.scrollFactor.y, cameraMaxSize); // scrollfactor in 3D is kinda dumb
			_camOrigin.setTo(camera.width / 2, camera.height / 2, 0);
			
			quad0.setTo(-halfW, -halfH, 0); // LT
			quad1.setTo(halfW, -halfH, 0); // RT
			quad2.setTo(-halfW, halfH, 0); // LB
			quad3.setTo(halfW, halfH, 0); // RB

			for (i in 0...4) {
				var vert:Null<Vector3> = switch (i) {
					case 0: quad0;
					case 1: quad1;
					case 2: quad2;
					case 3: quad3;
					default: null;
				};

				if (flipX) vert.x *= -1;
				if (flipY) vert.y *= -1;
				vert.x -= spriteOrigin.x;
				vert.y -= spriteOrigin.y;
				vert.x *= scale.x;
				vert.y *= scale.y;

				//
				vert.rotateV3(radPitch, radYaw, radRoll, vert);
				
				// origin mod
				vert.add(_sprPos, vert);
				vert.subtract(_camOrigin, vert);
				vert.subtract(_camPos, vert);

				//
				vert.project(vert, cameraMaxSize);
				
				// puts the vertex back to default pos
				vert.subtract(_sprPos, vert);
				vert.add(_camOrigin, vert);
				
				//
				vert.x += spriteOrigin.x;
				vert.y += spriteOrigin.y;
			}

			// LT RT LB RB
			// 0  1  2  3

			// order should be LT, RT, RB | LT, LB, RB
			// R is right L is left T is top B is bottom
			// order matters! so LT is left, top because they're represented as x, y
			_vertices[0] = quad0.x;		_vertices[1] = quad0.y; // LT
			_vertices[2] = quad1.x;		_vertices[3] = quad1.y; // RT
			_vertices[4] = quad3.x;		_vertices[5] = quad3.y; // RB

			_vertices[6] = quad0.x;		_vertices[7] = quad0.y; // LT
			_vertices[8] = quad2.x;		_vertices[9] = quad2.y; // LB
			_vertices[10] = quad3.x;	_vertices[11] = quad3.y; // RB

			var sourceBitmap:openfl.display.BitmapData = graphic.bitmap;
			var frameRect:flixel.math.FlxRect = frame.frame;

			var leftUV:Float = frameRect.left / sourceBitmap.width;
			var rightUV:Float = frameRect.right / sourceBitmap.width;
			var topUV:Float = frameRect.top / sourceBitmap.height;
			var bottomUV:Float = frameRect.bottom / sourceBitmap.height;

			_uvData[0] = leftUV;	_uvData[1] = topUV;
			_uvData[2] = rightUV;	_uvData[3] = topUV;
			_uvData[4] = rightUV;	_uvData[5] = bottomUV;

			_uvData[6] = leftUV;	_uvData[7] = topUV;
			_uvData[8] = leftUV;	_uvData[9] = bottomUV;
			_uvData[10] = rightUV;	_uvData[11] = bottomUV;
			
			_3DColor.redMultiplier = colorTransform.redMultiplier;
			_3DColor.greenMultiplier = colorTransform.greenMultiplier;
			_3DColor.blueMultiplier = colorTransform.blueMultiplier;
			_3DColor.redOffset = colorTransform.redOffset;
			_3DColor.greenOffset = colorTransform.greenOffset;
			_3DColor.blueOffset = colorTransform.blueOffset;
			_3DColor.alphaOffset = colorTransform.alphaOffset;
			_3DColor.alphaMultiplier = colorTransform.alphaMultiplier * camera.alpha;

			var drawItem:flixel.graphics.tile.FlxDrawTrianglesItem = camera.startTrianglesBatch(graphic, antialiasing, true, blend, true, shader);
			@:privateAccess drawItem.addTrianglesColorArray(_vertices, _indices, _uvData, null, _point, camera._bounds, _triangleColorTransforms);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
		spriteOrigin.putWeak();

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug) drawDebug();
		#end
	}
}