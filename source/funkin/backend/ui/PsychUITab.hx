package funkin.backend.ui;

import flixel.util.FlxDestroyUtil;

class PsychUITab extends FlxSprite {
	public var name(default, set):String;
	public var text:FlxText;
	public var menu:FlxSpriteGroup = new FlxSpriteGroup();

	public function new(name:String) {
		super();
		makeGraphic(1, 1);
		color = FlxColor.BLACK;
		alpha = 0.6;

		@:bypassAccessor this.name = name;
		text = new FlxText(0, 0, 100, name);
		text.alignment = CENTER;
	}

	override function draw() {
		super.draw();

		if (visible && text != null && text.exists && text.visible) {
			text.setPosition(x, y + height / 2 - text.height / 2);
			text.draw();
		}
	}

	override function destroy() {
		text = FlxDestroyUtil.destroy(text);
		menu = FlxDestroyUtil.destroy(menu);
		super.destroy();
	}
	
	public function updateMenu(parent:PsychUIBox, elapsed:Float) {
		if (menu != null && menu.exists && menu.active) {
			menu.scrollFactor.set(parent.scrollFactor.x, parent.scrollFactor.y);
			menu.update(elapsed);
		}
	}

	public function drawMenu(parent:PsychUIBox) {
		if (menu != null && menu.exists && menu.visible) {
			menu.setPosition(parent.x, parent.y + parent.tabHeight);
			menu.draw();
		}
	}

	public function resize(width:Int, height:Int) {
		setGraphicSize(width, height);
		updateHitbox();
		text.fieldWidth = width;
	}

	function set_name(v:String):String {
		text.text = v;
		return (name = v);
	}

	override function set_cameras(v:Array<FlxCamera>):Array<FlxCamera> {
		text.cameras = v;
		menu.cameras = v;
		return super.set_cameras(v);
	}

	override function set_camera(v:FlxCamera):FlxCamera {
		text.camera = v;
		menu.camera = v;
		return super.set_camera(v);
	}
}