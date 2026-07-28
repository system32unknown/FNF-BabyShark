package utils;

import haxe.Http;
import haxe.io.Bytes;

/**
 * Utility class for making synchronous HTTP requests with automatic redirect handling.
 * All methods are blocking and throw `HttpError` on failure. Redirects (301, 302, 307, 308) are followed recursively using the `Location` response header.
 */
final class HttpUtil {
	/**
	 * The User-Agent header sent with every request.
	 */
	public static var userAgent:String = "request";

	/**
	 * Maximum number of redirects allowed before aborting a request.
	 */
	public static var maxRedirects:Int = 10;

	/**
	 * Makes a synchronous GET request and returns the response body as a string.
	 * Automatically follows redirects.
	 * @param url The URL to request.
	 * @return The response body as a `String`.
	 * @throws HttpError If the request fails, redirects without a `Location` header, or returns an empty response.
	 */
	public static function requestText(url:String):String
		return cast fetch(url, false, 0);

	/**
	 * Makes a synchronous GET request and returns the response body as raw bytes.
	 * This automatically follows redirects.
	 * @param url The URL to request.
	 * @return The response body as `haxe.io.Bytes`.
	 * @throws HttpError If the request fails, redirects without a `Location` header, or returns an empty response.
	 */
	public static function requestBytes(url:String):Bytes
		return cast fetch(url, true, 0);

	/**
	 * Sends a POST request with key-value parameters.
	 *
	 * @param url Destination URL.
	 * @param params Map of parameters to include in the request body.
	 * @throws HttpError If the request fails.
	 */
	public static function postParameters(url:String, params:Map<String, String>):Void {
		var error:HttpError = null;

		var h:Http = makeHttp(url);
		for (k => v in params) h.addParameter(k, v);
		h.onError = (msg:String) -> error = new HttpError(msg, url);
		h.request(true);

		if (error != null) throw error;
	}

	/**
	 * Checks whether an internet connection is available by pinging (or requesting) `google.com`.
	 * @return `true` if the request succeeded, `false` if it threw an `HttpError`.
	 */
	public static function hasInternet():Bool {
		try {
			requestText("https://connectivitycheck.gstatic.com/generate_204");
			return true;
		} catch (e:HttpError) {
			Logs.warn('[HttpUtil.hasInternet] Failed: ${e.toString()}');
			return false;
		}
	}

	/**
	 * Makes a synchronous GET request and returns the response body as raw bytes.
	 * This automatically follows redirects.
	 * @param url The URL to request.
	 * @param asBytes Whether the response should be returned as Bytes.
	 * @param depth Current redirect depth.
	 * @return Response data (String or Bytes).
	 * @throws HttpError If the request fails, redirects without a `Location` header, or returns an empty response.
	 */
	static function fetch(url:String, asBytes:Bool, depth:Int):Dynamic {
		if (depth > maxRedirects) throw new HttpError('Redirect limit ($maxRedirects) exceeded', url);

		var result:Dynamic = null;
		var error:HttpError = null;
		var redirectUrl:String = null;

		var h:Http = makeHttp(url);

		h.onStatus = (status:Int) -> {
			if (isRedirect(status)) {
				redirectUrl = h.responseHeaders.get("Location");
				if (redirectUrl == null) error = new HttpError("Missing Location header in redirect", url, status);
			}
		};

		if (asBytes) h.onBytes = (data:Bytes) -> if (redirectUrl == null) result = data; else h.onData = (data:String) -> if (redirectUrl == null) result = data;
		h.onError = (msg:String) -> error = new HttpError(msg, url);

		h.request(false);

		if (error != null) throw error;
		if (redirectUrl != null) return fetch(redirectUrl, asBytes, depth + 1);
		if (result == null) throw new HttpError("Unknown error or empty byte response", url);

		return result;
	}

	/**
	 * Creates and configures an `Http` instance.
	 *
	 * Applies shared headers such as `User-Agent`.
	 *
	 * @param url Target URL.
	 * @return Configured Http object.
	 */
	static inline function makeHttp(url:String):Http {
		var h:Http = new Http(url);
		h.setHeader("User-Agent", userAgent);
		return h;
	}

	/**
	 * Returns whether an HTTP status code represents a redirect.
	 * It handles 301, 302, 307, and 308.
	 * @param status The HTTP status code to check.
	 * @return `true` if the status is a redirect code.
	 */
	static function isRedirect(status:Int):Bool {
		return switch (status) {
			case 301 | 302 | 307 | 308:
				Logs.traceColored([
					{fgColor: BLUE, text: "[Connection Status] "},
					{fgColor: YELLOW, text: "Redirected with status code: "},
					{fgColor: GREEN, text: Std.string(status)}
				], VERBOSE);
				true;
			case _: false;
		}
	}
}

/**
 * Represents an HTTP error with context about the failed request.
 */
private class HttpError {
	/** The error message. */
	public var message:String;

	/** The URL that triggered the error. */
	public var url:String;

	/** The HTTP status code, or `-1` if not applicable. */
	public var status:Int;

	/** Whether the error occurred during a redirect. */
	public var redirected:Bool;

	/**
	 * @param message Description of the Error
	 * @param url The URL associated with the failed request.
	 * @param status HTTP status code. Defaults to `-1`.
	 * @param redirected Whether this error occurred mid-redirect. Defaults to `false`.
	 */
	public function new(message:String, url:String, ?status:Int = -1, ?redirected:Bool = false) {
		this.message = message;
		this.url = url;
		this.status = status;
		this.redirected = redirected;
	}

	/**
	 * Returns a formatted string representation of the error.
	 * The format should look like this: `[HttpError] | Status: N | (Redirected) | URL: ... | Message: ...`
	 * @return An error summary in a string
	 */
	public function toString():String {
		final parts:Array<String> = ['[HttpError]'];
		if (status != -1) parts.push('Status: $status');
		if (redirected) parts.push('(Redirected)');
		parts.push('URL: $url');
		parts.push('Message: $message');
		return parts.join(' | ');
	}
}