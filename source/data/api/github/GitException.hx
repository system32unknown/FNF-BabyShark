package data.api.github;

import haxe.Exception;

class GitException extends Exception {
    public var gitMessage:String;

    public function new(gitMessage:String) {
        super('[Git Exception] ' + gitMessage);
        this.gitMessage = gitMessage;
    }
} 