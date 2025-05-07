package utils.system;

enum abstract AnsiColor(Int) {
	var BLACK:AnsiColor = 0;
	var DARKBLUE:AnsiColor = 1;
	var DARKGREEN:AnsiColor = 2;
	var DARKCYAN:AnsiColor = 3;
	var DARKRED:AnsiColor = 4;
	var DARKMAGENTA:AnsiColor = 5;
	var DARKYELLOW:AnsiColor = 6;
	var LIGHTGRAY:AnsiColor = 7;
	var GRAY:AnsiColor = 8;
	var BLUE:AnsiColor = 9;
	var GREEN:AnsiColor = 10;
	var CYAN:AnsiColor = 11;
	var RED:AnsiColor = 12;
	var MAGENTA:AnsiColor = 13;
	var YELLOW:AnsiColor = 14;
	var WHITE:AnsiColor = 15;

	var NONE:AnsiColor = -1;
}

class Ansi {
    public static function colorToANSI(color:AnsiColor):Int {
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

	public static function colorToOpenFL(color:AnsiColor):FlxColor {
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
}