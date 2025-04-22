package utils.system;

enum abstract ConsoleMode(Int) {
	var INIT:ConsoleMode = 0;
	var BOLD:ConsoleMode = 1;
	var DIM:ConsoleMode = 2;
	var ITALIC:ConsoleMode = 3;
	var UNDERLINE:ConsoleMode = 4;
	var BLINKING:ConsoleMode = 5;
	var INVERT:ConsoleMode = 7;
	var INVISIBLE:ConsoleMode = 8;
	var STRIKETHROUGH:ConsoleMode = 9;

    public function format(?c:Int = 37):String return '\033[${this};${c}m';
	public function asCol(?c:Int = 0):String return '\033[${0};${c}m';
}

enum abstract ConsoleColor(Int) {
	var BLACK:ConsoleColor = 0;
	var DARKBLUE:ConsoleColor = 1;
	var DARKGREEN:ConsoleColor = 2;
	var DARKCYAN:ConsoleColor = 3;
	var DARKRED:ConsoleColor = 4;
	var DARKMAGENTA:ConsoleColor = 5;
	var DARKYELLOW:ConsoleColor = 6;
	var LIGHTGRAY:ConsoleColor = 7;
	var GRAY:ConsoleColor = 8;
	var BLUE:ConsoleColor = 9;
	var GREEN:ConsoleColor = 10;
	var CYAN:ConsoleColor = 11;
	var RED:ConsoleColor = 12;
	var MAGENTA:ConsoleColor = 13;
	var YELLOW:ConsoleColor = 14;
	var WHITE:ConsoleColor = 15;

	var NONE:ConsoleColor = -1;
}

class Ansi {
    public static function colorToANSI(color:ConsoleColor):Int {
		return switch (color) {
			case BLACK: 30;
			case DARKBLUE: 34;
			case DARKGREEN: 32;
			case DARKCYAN: 36;
			case DARKRED: 31;
			case DARKMAGENTA: 35;
			case DARKYELLOW: 33;
			case LIGHTGRAY: 37;
			case GRAY: 90;
			case BLUE: 94;
			case GREEN: 92;
			case CYAN: 96;
			case RED: 91;
			case MAGENTA: 95;
			case YELLOW: 93;
			case WHITE | _: 97;
		}
	}

	public static function colorToOpenFL(color:ConsoleColor):FlxColor {
		return switch (color) {
			case BLACK: 0xFF000000;
			case DARKBLUE: 0xFF000088;
			case DARKGREEN: 0xFF008800;
			case DARKCYAN: 0xFF008888;
			case DARKRED: 0xFF880000;
			case DARKMAGENTA: 0xFF880088;
			case DARKYELLOW: 0xFF888800;
			case LIGHTGRAY: 0xFFBBBBBB;
			case GRAY: 0xFF888888;
			case BLUE: 0xFF0000FF;
			case GREEN: 0xFF00FF00;
			case CYAN: 0xFF00FFFF;
			case RED: 0xFFFF0000;
			case MAGENTA: 0xFFFF00FF;
			case YELLOW: 0xFFFFFF00;
			case WHITE | _: 0xFFFFFFFF;
		}
	}
    
    public static inline function reset():Void {
        Sys.print("\x1b[0m");
    }
}