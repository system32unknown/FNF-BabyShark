package funkin.utils;

import haxe.Http;
import haxe.io.Bytes;

/**
 * A utility class for making HTTP requests in Haxe.
 */
final class HttpUtil {
	/**
	 * User-Agent string used for HTTP requests.
	 */
	public static var userAgent:String = "request";

	/**
	 * Performs an HTTP request to retrieve text data from a given URL.
	 * 
	 * @param url The URL to request data from.
	 * @return The response text from the server.
	 * @throws Exception if an error occurs during the request.
	 */
	public static function requestText(url:String):String {
		var result:String = null;
		var error:HttpError = null;

		var h:Http = new Http(url);
		h.setHeader("User-Agent", userAgent);

		h.onStatus = function(status:Int) {
			var redirected:Bool = isRedirect(status);
			if (redirected) {
				var loc:Null<String> = h.responseHeaders.get("Location");
				if (loc != null) result = requestText(loc);
				else error = new HttpError("Missing Location header in redirect", url, status, true);
			}
		};
		h.onData = (data:String) -> if (result == null) result = data;
		h.onError = (msg:String) -> error = new HttpError(msg, url);

		h.request(false);

		if (error != null) throw error;
		if (result == null) throw new HttpError("Unknown error or empty response", url);

		return result;
	}

	/**
	 * Performs an HTTP request to retrieve binary data from a given URL.
	 * 
	 * @param url The URL to request binary data from.
	 * @return The response as Bytes.
	 * @throws Exception if an error occurs during the request.
	 */
	public static function requestBytes(url:String):Bytes {
		var result:Bytes = null;
		var error:HttpError = null;

		var h:Http = new Http(url);
		h.setHeader("User-Agent", userAgent);

		h.onStatus = (status:Int) -> {
			var redirected:Bool = isRedirect(status);
			if (redirected) {
				var loc:Null<String> = h.responseHeaders.get("Location");
				if (loc != null) result = requestBytes(loc);
				else error = new HttpError("Missing Location header in redirect", url, status, true);
			}
		};
		h.onBytes = (data:Bytes) -> if (result == null) result = data;
		h.onError = (msg:String) -> error = new HttpError(msg, url);

		h.request(false);

		if (error != null) throw error;
		if (result == null) throw new HttpError("Unknown error or empty byte response", url);

		return result;
	}

	/**
	 * Sends a POST request with parameters to a given URL.
	 * 
	 * @param url The URL to send the POST request to.
	 * @param param A map of key-value pairs to include as parameters.
	 * @return True if the request was sent successfully, otherwise false.
	 */
	public static function postParameters(url:String, param:Map<String, String>):Bool {
		var h:Http = new Http(url);
		try {
			for (k => v in param) h.addParameter(k, v);
			h.onError = (e:String) -> throw e;
			h.request(true);
			return true;
		} catch (e:Dynamic) {
			Logs.error("postParameters Error: " + e);
			return false;
		}
	}

	public static function hasInternet():Bool {
		try {
			requestText("https://www.google.com/");
			return true;
		} catch (e:HttpError) {
			Logs.warn('[HttpUtil.hasInternet] Failed: ${e.toString()}');
			return false;
		}
	}

	/**
	 * Checks whether an HTTP status code indicates a redirect.
	 * 
	 * @param status The HTTP status code.
	 * @return True if the status code indicates a redirect, otherwise false.
	 */
	static function isRedirect(status:Int):Bool {
		switch (status) {
			case 301 | 302 | 307 | 308:
				Logs.traceColored([
					{fgColor: BLUE, text: "[Connection Status] "},
					{fgColor: YELLOW, text: "Redirected with status code: "},
					{fgColor: GREEN, text: Std.string(status)}
				], WARNING);
				return true;
		}
		return false;
	}
}

private class HttpError {
	public var message:String;
	public var url:String;
	public var status:Int;
	public var redirected:Bool;

	public function new(message:String, url:String, ?status:Int = -1, ?redirected:Bool = false) {
		this.message = message;
		this.url = url;
		this.status = status;
		this.redirected = redirected;
	}

	public function toString():String {
		var parts:Array<String> = ['[HttpError]'];

		if (status != -1) parts.push('Status: $status');
		if (redirected) parts.push('(Redirected)');

		parts.push('URL: $url');
		parts.push('Message: $message');

		return parts.join(' | ');
	}
}