package api.github;

import haxe.Json;
import haxe.Http;

using StringTools;

class GithubAPI {
    public static function getLatestCommits():String {
        var sha_id:GithubCommits = getCommits("system32unknown", "FNF-BabyShark")[0];
        return sha_id.sha;
    }

	static function getCommits(user:String, commits:String) {
        var url:String = 'https://api.github.com/repos/${user}/${commits}/commits';
		return getGitToJSON(url);
	}

	static function getGitToJSON(url:String) {
		var http = new Http(url);
		http.setHeader("User-Agent", "request");

		var r:Dynamic = null;
		http.onData = function(data) {r = data;}
		http.onError = function(exception) {throw exception;}
		http.request();
		return Json.parse(r);
	}
}