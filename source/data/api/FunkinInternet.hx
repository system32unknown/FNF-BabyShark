package data.api;

class FunkinInternet {
    public var isOnline:Bool = false;

    public function new() {
        isOnline = __checkOnline();
    }

	function __checkOnline():Bool {
        var successd = false;
        var http = new haxe.Http("http://www.example.com/");
        http.onStatus = function(status:Int) {
            switch status {
                case 200:
                    trace("\033[1;37m[FUNKIN] FunkinWeb is Online.\033[32m");
                    successd = true;
                default:
                    trace("\033[1;37m[FUNKIN] FunkinWeb is Online.\033[31m");
                    successd = false;
            }
        };

        http.onError = function(e) {
            successd = false;
        }

        http.request();
        return successd;
    }
}