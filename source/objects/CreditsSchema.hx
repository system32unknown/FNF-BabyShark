package objects;

@:structInit
/**
 * For the Credits Menu.
 * @author crowplexus
**/
class CreditsPageSchema {
    /** Page Name, shown on the credits menu when hovering over it. */
	public var name:Null<String> = null;

    /** User list, leave null or empty to display an error message instead (why?). */
	public var users:Array<CreditSchema> = null;

    /** Page icon, shown before its name. */
	public var icon:Null<String> = null;

    /**
     * Returns the graphic used for the icon shown before the page name.
     * @return FlxGraphic
    **/
	public function getHeaderGraphic() {
		var str:String = 'credits/header/$icon';
		if(!Paths.exists('images/$str.png'))
			str = 'credits/header/missing_icon';
		return Paths.image('images/$str.png');
	}
}

@:structInit
/**
 * For the Credits Menu Pages.
 * @author crowplexus
**/
class CreditSchema {
    /** Name of the user, displayed when hovering over them. **/
	public var name:String = "N/A";
    /** User's icon, displayed before their name. **/
	public var icon:Null<String> = null;
    /** Description or role, displayed below the user's name. **/
	public var role:Null<String> = null;
    /** URL that gets opened in your browser if you press enter. **/
	public var url:Null<String> = null;
    /** User's color, the menu background changes in accordance to whatever this is. **/
	public var color:Null<FlxColor> = null;
    /** If the icon has antialiasing, automatically set to false if the icon name ends in "-pixel" **/
	@:optional public var antialiasing:Null<Bool> = null;
    /** User's pronouns **/
    @:optional public var pronouns:Null<String> = "";

	public function new(name:String, icon:String = null, role:String = null, url:Null<String> = null, color:Null<FlxColor> = null, pronouns:Null<String> = null, ?antialiasing:Null<Bool> = null):Void {
		this.name = name;
		this.icon = icon;
		this.role = role;
		this.url = url;
		this.color = color;
		if (antialiasing == null)
			antialiasing = !icon.endsWith("-pixel");
		this.antialiasing = antialiasing;
	}

    /**
     * Returns the graphic used for the icon shown before the user's name.
     * @return FlxGraphic
    **/
	public function getIconGraphic() {
		var str:String = 'credits/icons/$icon';
		if(!Paths.exists('images/$str.png'))
			str = 'credits/missing_icon';
		return Paths.image('images/$str.png');
	}
}