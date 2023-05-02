package data.api;

class FunkinInternet {
    public static var isOnline:Bool = false;

    public static function init() {isOnline = __checkOnline();}

	static function __checkOnline():Bool {
        var done:Bool = false;
        var http = new haxe.Http("http://www.google.com/");
        http.onStatus = function(status:Int) {
            switch status {
                case 200:
                    trace("\n\033[1;37m[FUNKIN] FunkinWeb is Online.\033[32m");
                    done = true;
                default:
                    trace("\n\033[1;37m[FUNKIN] FunkinWeb is Online.\033[31m");
                    done = false;
            }
        };

        http.onError = function(e) {
            done = false;
        }

        http.request(false);

        return done;
    }

    static public function request(web:String, post:Bool = false, func:Void->Void, errorfunc:Void->Void) {
        var http = new haxe.Http(web);
        http.onStatus = function(status:Int) {
            switch status {
                case 200: if(func != null) func();
            }
        };

        http.onError = function(e) {
            if(errorfunc != null) errorfunc();
        }

        http.request(post);
    }
}