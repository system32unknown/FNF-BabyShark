package utils;

import haxe.Http;
import haxe.io.Bytes;

/**
 * A utility class for making HTTP requests in Haxe.
 */
class HttpUtil {
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
		var r:String = null;
		var h:Http = new Http(url);
		h.setHeader("User-Agent", userAgent);

		h.onStatus = (s:Int) -> if (isRedirect(s)) r = requestText(h.responseHeaders.get("Location"));
		h.onData = (d:String) -> if (r == null) r = d;
		h.onError = (e:String) -> throw e;

		h.request();
		return r;
	}

	/**
	 * Performs an HTTP request to retrieve binary data from a given URL.
	 * 
	 * @param url The URL to request binary data from.
	 * @return The response as Bytes.
	 * @throws Exception if an error occurs during the request.
	 */
	public static function requestBytes(url:String):Bytes {
		var r:Bytes = null;
		var h:Http = new Http(url);
		h.setHeader("User-Agent", userAgent);

		h.onStatus = (s:Int) -> if (isRedirect(s)) r = requestBytes(h.responseHeaders.get("Location"));
		h.onBytes = (d:Bytes) -> r ??= d;
		h.onError = (e:String) -> throw e;

		h.request();
		return r;
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
			Logs.trace("postParameters Error: " + e, ERROR);
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
				Logs.traceColored([Logs.logText('[Connection Status] ', BLUE), Logs.logText('Redirected with status code: ', YELLOW), Logs.logText(Std.string(status), GREEN)], WARNING);
				return true;
		}
		return false;
	}
}