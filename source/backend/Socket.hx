package backend;

#if sys
import sys.net.Host;
import sys.net.Socket as SysSocket;

class Socket implements flixel.util.FlxDestroyUtil.IFlxDestroyable {
	public var socket:SysSocket;

	public function new(?socket:SysSocket) {
		this.socket = socket;
		if (this.socket == null) this.socket = new SysSocket();
		this.socket.setFastSend(true);
		this.socket.setBlocking(false);
	}

	public function read():String {
		try {
			return this.socket.input.readUntil('\n'.code).replace("\\n", "\n");
		} catch (e:Dynamic) Logs.error('ERROR SOCKET ON READ - $e');
		return null;
	}

	public function write(str:String):Bool {
		try {
			this.socket.output.writeString(str.replace("\n", "\\n"));
			return true;
		} catch (e:Dynamic) Logs.error('ERROR SOCKET ON WRITE - $e');
		return false;
	}

	public function host(host:Host, port:Int, nbConnections:Int = 1) {
		socket.bind(host, port);
		socket.listen(nbConnections);
		socket.setFastSend(true);
	}

	public function hostAndWait(h:Host, port:Int):Socket {
		host(h, port);
		return acceptConnection();
	}

	public function acceptConnection():Socket {
		socket.setBlocking(true);
		var accept:Socket = new Socket(socket.accept());
		socket.setBlocking(false);
		return accept;
	}

	public function connect(host:Host, port:Int) {
		socket.connect(host, port);
	}

	public function destroy() {
		socket?.close();
	}
}
#end