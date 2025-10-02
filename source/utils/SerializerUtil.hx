package utils;

import haxe.Json;

/**
 * Functions dedicated to serializing and deserializing data.
 * NOTE: Use `json2object` wherever possible, it's way more efficient.
 */
@:nullSafety
class SerializerUtil {
	static final INDENT_CHAR:String = "\t";

	/**
	 * Convert a Haxe object to a JSON string.
	 * NOTE: Use `json2object.JsonWriter<T>` WHEREVER POSSIBLE. Do not use this one unless you ABSOLUTELY HAVE TO it's SLOW!
	 * And don't even THINK about using `haxe.Json.stringify` without the replacer!
	 */
	public static function toJSON(input:Dynamic, pretty:Bool = true):String {
		return Json.stringify(input, replacer, pretty ? INDENT_CHAR : null);
	}

	/**
	 * Convert a JSON string to a Haxe object.
	 */
	public static function fromJSON(input:String):Dynamic {
		input = input.substring(input.indexOf("{"), input.lastIndexOf("}") + 1);

		try {
			return Json.parse(input);
		} catch (e:Dynamic) {
			Logs.error('An error occurred while parsing JSON from string data: $e');
			return null;
		}
	}

	/**
	 * Convert a JSON byte array to a Haxe object.
	 */
	public static function fromJSONBytes(input:haxe.io.Bytes):Null<Dynamic> {
		try {
			return Json.parse(input.toString());
		} catch (e:Dynamic) {
			Logs.error('An error occurred while parsing JSON from byte data: $e');
			return null;
		}
	}

	/**
	 * Customize how certain types are serialized when converting to JSON.
	 */
	static function replacer(key:String, value:Dynamic):Dynamic {
		// Hacky because you can't use `isOfType` on a struct.
		if (key == "version") {
			if (Std.isOfType(value, String)) return value;

			// Stringify Version objects.
			return serializeVersion(cast value);
		}

		// Else, return the value as-is.
		return value;
	}

	static inline function serializeVersion(value:thx.semver.Version):String {
		var result:String = '${value.major}.${value.minor}.${value.patch}';
		if (value.hasPre) result += '-${value.pre}';
		// TODO: Merge fix for version.hasBuild
		if (value.build.length > 0) result += '+${value.build}';
		return result;
	}
}
