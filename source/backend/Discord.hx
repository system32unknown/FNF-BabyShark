package backend;

import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;
import psychlua.FunkinLua;

class DiscordClient {
	public static var isInitialized:Bool = false;
	static final _defaultID:String = "1013313492889108510";
	public static var clientID(default, set):String = _defaultID;
	static var presence:DiscordRichPresence = DiscordRichPresence.create();

	public static function check() {
		if(ClientPrefs.getPref('discordRPC')) initialize();
		else if(isInitialized) shutdown();
	}

	public static function prepare() {
		if (!isInitialized && ClientPrefs.getPref('discordRPC')) initialize();
		lime.app.Application.current.window.onClose.add(() -> if(isInitialized) shutdown());
	}

	public dynamic static function shutdown() {
		Discord.Shutdown();
		isInitialized = false;
	}
	
	static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void {
		var requestPtr:cpp.Star<DiscordUser> = cpp.ConstPointer.fromRaw(request).ptr;

		if (Std.parseInt(cast(requestPtr.discriminator, String)) != 0) //New Discord IDs/Discriminator system
			Logs.trace('(Discord) Connected to User (${cast(requestPtr.username, String)}#${cast(requestPtr.discriminator, String)})');
		else Logs.trace('(Discord) Connected to User (${cast(requestPtr.username, String)})'); //Old discriminators

		changePresence();
	}

	static function onError(errorCode:Int, message:cpp.ConstCharStar):Void {
		Logs.trace('Discord: Error ($errorCode: ${cast(message, String)})', ERROR);
	}

	static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void {
		Logs.trace('Discord: Disconnected ($errorCode: ${cast(message, String)})', WARNING);
	}

	public static function initialize() {
		var discordHandlers:DiscordEventHandlers = DiscordEventHandlers.create();
		discordHandlers.ready = cpp.Function.fromStaticFunction(onReady);
		discordHandlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		discordHandlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize(clientID, cpp.RawPointer.addressOf(discordHandlers), 1, null);

		Logs.trace("Discord Client initialized");

		sys.thread.Thread.create(() -> {
			var localID:String = clientID;
			while (localID == clientID) {
				#if DISCORD_DISABLE_IO_THREAD Discord.UpdateConnection(); #end
				Discord.RunCallbacks();
				Sys.sleep(.5); // Wait 0.5 seconds until the next loop...
			}
		});
		isInitialized = true;
	}

	public static function changePresence(?details:String = 'In the Menus', ?state:Null<String>, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
		var startTimestamp:Float = hasStartTimestamp ?  Date.now().getTime() : 0;
		if (endTimestamp > 0) endTimestamp = startTimestamp + endTimestamp;

		presence.details = details;
		presence.state = state;
		presence.largeImageKey = (ClientPrefs.getPref('AltDiscordImg') ? 'iconalt' + ClientPrefs.getPref('AltDiscordImgCount') : 'icon');
		presence.largeImageText = 'Baby Shark\'s Funkin';
		// Obtained times are in milliseconds so they are divided so Discord can use it
		presence.startTimestamp = Std.int(startTimestamp / 1000);
		presence.endTimestamp = Std.int(endTimestamp / 1000);
		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence));
	}
	
	public static function resetClientID()
		clientID = _defaultID;

	static function set_clientID(newID:String) {
		var change:Bool = (clientID != newID);
		clientID = newID;

		if(change && isInitialized) {
			shutdown();
			initialize();
			Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence));
		}
		return newID;
	}

	#if MODS_ALLOWED
	public static function loadModRPC() {
		var pack:Dynamic = Mods.getPack();
		if(pack != null && pack.discordRPC != null && pack.discordRPC != clientID)
			clientID = pack.discordRPC;
	}
	#end

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:FunkinLua) {
		lua.set("changePresence", (details:String, state:Null<String>, ?hasStartTimestamp:Bool, ?endTimestamp:Float) -> changePresence(details, state, hasStartTimestamp, endTimestamp));
		lua.set("changeDiscordClientID", (?newID:String = null) -> {
			if(newID == null) newID = _defaultID;
			clientID = newID;
		});
	}
	#end
}