package utils;

import haxe.Http;
import haxe.io.Bytes;

class HttpUtil {
	public static var userAgent:String = "request";
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

	static function isRedirect(status:Int):Bool {
		switch (status) {
			case 301 | 302 | 307 | 308:
				Logs.traceColored([Logs.logText('[Connection Status] ', BLUE), Logs.logText('Redirected with status code: ', YELLOW), Logs.logText(Std.string(status), GREEN)], WARNING);
				return true;
		}
		return false;
	}
}