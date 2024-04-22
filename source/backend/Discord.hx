package backend;

import sys.thread.Thread;
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;
import flixel.util.FlxStringUtil;

class DiscordClient {
	public static var isInitialized:Bool = false;
	inline static final _defaultID:String = "1013313492889108510";
	public static var clientID(default, set):String = _defaultID;
	static var presence:DiscordPresence = new DiscordPresence();
	// hides this field from scripts and reflection in general
	@:unreflective static var __thread:Thread;

	public static var icon_img:String = "icon";
	public static var user:DUser = null;

	public static function check() {
		if(ClientPrefs.data.discordRPC) initialize();
		else if(isInitialized) shutdown();
	}

	public static function prepare() {
		if (!isInitialized && ClientPrefs.data.discordRPC) initialize();
		lime.app.Application.current.window.onClose.add(() -> if(isInitialized) shutdown());
	}

	public dynamic static function shutdown() {
		isInitialized = false;
		Discord.Shutdown();
	}
	
	public static function respond(userId:String, reply:Int) {
		Discord.Respond(fixString(userId), reply);
	}

	static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void {
		user = DUser.initRaw(request);
		Logs.traceColored([
			Logs.logText("[Discord] ", BLUE),
			Logs.logText("Connected to User " + user.globalName + " ("),
			Logs.logText(user.handle, GRAY),
			Logs.logText(")")
		], INFO);

		changePresence();
	}

	static function onError(errorCode:Int, message:cpp.ConstCharStar):Void {
		Logs.traceColored([
			Logs.logText("[Discord] ", BLUE),
			Logs.logText('Error ($errorCode: ${cast(message, String)})', RED)
		], ERROR);
	}

	static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void {
		Logs.traceColored([
			Logs.logText("[Discord] ", BLUE),
			Logs.logText("Disconnected ("),
			Logs.logText('$errorCode: ${cast(message, String)}', RED),
			Logs.logText(")")
		], INFO);
	}

	static function onJoin(joinSecret:cpp.ConstCharStar):Void {
		Logs.traceColored([Logs.logText("[Discord] ", BLUE), Logs.logText("Someone has just joined", GREEN)], INFO);
	}

	static function onSpectate(spectateSecret:cpp.ConstCharStar):Void {
		Logs.traceColored([Logs.logText("[Discord] ", BLUE), Logs.logText("Someone started spectating your game", YELLOW)], INFO);
	}

	static function onJoinReq(request:cpp.RawConstPointer<DiscordUser>):Void {
		Logs.traceColored([Logs.logText("[Discord] ", BLUE), Logs.logText("Someone has just requested to join", YELLOW)], WARNING);
	}

	public static function initialize() {
		var handlers:DiscordEventHandlers = DiscordEventHandlers.create();
		handlers.ready = cpp.Function.fromStaticFunction(onReady);
		handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		handlers.errored = cpp.Function.fromStaticFunction(onError);
		handlers.joinGame = cpp.Function.fromStaticFunction(onJoin);
		handlers.joinRequest = cpp.Function.fromStaticFunction(onJoinReq);
		handlers.spectateGame = cpp.Function.fromStaticFunction(onSpectate);
		Discord.Initialize(clientID, cpp.RawPointer.addressOf(handlers), 1, null);

		if(!isInitialized) trace("Discord Client initialized");

		if (__thread == null) {
			__thread = Thread.create(() -> {
				while (true) {
					if (isInitialized) {
						#if DISCORD_DISABLE_IO_THREAD Discord.UpdateConnection(); #end
						Discord.RunCallbacks();
					}
					Sys.sleep(1.); // Wait 1 second until the next loop...
				}
			});
		}
		isInitialized = true;
	}

	public static function changePresence(?details:String = 'In the Menus', ?state:Null<String>, ?hasStartTimestamp:Bool, ?endTimestamp:Float, ?largeImageKey:Null<String>) {
		if (largeImageKey == null) largeImageKey = (ClientPrefs.data.altDiscordImg ? 'iconalt' + ClientPrefs.data.altDiscordImgCount : icon_img);

		var startTimestamp:Float = hasStartTimestamp ?  Date.now().getTime() : 0;
		if (endTimestamp > 0) endTimestamp = startTimestamp + endTimestamp;

		presence.state = state;
		presence.details = details;
		presence.largeImageKey = largeImageKey;
		presence.largeImageText = 'Baby Shark\'s Big Funkin!';
		// Obtained times are in milliseconds so they are divided so Discord can use it
		presence.startTimestamp = Std.int(startTimestamp / 1000);
		presence.endTimestamp = Std.int(endTimestamp / 1000);
		updatePresence();
	}
	
	public static function updatePresence()
		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence.__presence));

	public static function resetClientID()
		clientID = _defaultID;

	static function set_clientID(newID:String) {
		var change:Bool = (clientID != newID);
		clientID = newID;

		if(change && isInitialized) {
			shutdown();
			initialize();
			updatePresence();
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
	public static function addLuaCallbacks(lua:psychlua.FunkinLua) {
		lua.set("changeDiscordPresence", changePresence);
		lua.set("changeDiscordClientID", (?newID:String) -> {
			if(newID == null) newID = _defaultID;
			clientID = newID;
		});
	}
	#end

	@:noCompletion public static function fixString(str:String) {
		return new cpp.ConstCharStar(cast(str, String));
	}
}

@:allow(backend.DiscordClient)
final class DiscordPresence {
	public var state(get, set):String;
	public var details(get, set):String;
	public var largeImageKey(get, set):String;
	public var largeImageText(get, set):String;
	public var startTimestamp(get, set):Int;
	public var endTimestamp(get, set):Int;

	@:noCompletion private var __presence:DiscordRichPresence;

	function new() {
		__presence = DiscordRichPresence.create();
	}

	public function toString():String {
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("state", state),
			LabelValuePair.weak("details", details),
			LabelValuePair.weak("largeImageKey", largeImageKey),
			LabelValuePair.weak("largeImageText", largeImageText),
			LabelValuePair.weak("startTimestamp", startTimestamp),
			LabelValuePair.weak("endTimestamp", endTimestamp)
		]);
	}

	@:noCompletion inline function get_state():String {
		return __presence.state;
	}

	@:noCompletion inline function set_state(value:String):String {
		return __presence.state = value;
	}

	@:noCompletion inline function get_details():String {
		return __presence.details;
	}

	@:noCompletion inline function set_details(value:String):String {
		return __presence.details = value;
	}

	@:noCompletion inline function get_largeImageKey():String {
		return __presence.largeImageKey;
	}

	@:noCompletion inline function set_largeImageKey(value:String):String {
		return __presence.largeImageKey = value;
	}

	@:noCompletion inline function get_largeImageText():String {
		return __presence.largeImageText;
	}

	@:noCompletion inline function set_largeImageText(value:String):String {
		return __presence.largeImageText = value;
	}

	@:noCompletion inline function get_startTimestamp():Int {
		return __presence.startTimestamp;
	}

	@:noCompletion inline function set_startTimestamp(value:Int):Int {
		return __presence.startTimestamp = value;
	}

	@:noCompletion inline function get_endTimestamp():Int {
		return __presence.endTimestamp;
	}

	@:noCompletion inline function set_endTimestamp(value:Int):Int {
		return __presence.endTimestamp = value;
	}
}

final class DUser {
	/**
	 * The username + discriminator if they have it
	**/
	public var handle:String;

	/**
	 * The user id, aka 860561967383445535
	**/
	public var userId:String;

	/**
	 * The user's username
	**/
	public var username:String;

	/**
	 * The #number from before discord changed to usernames only, if the user has changed to a username them its just a 0
	**/
	public var discriminator:Int;

	/**
	 * The user's avatar filename
	**/
	public var avatar:String;

	/**
	 * The user's display name
	**/
	public var globalName:String;

	/**
	 * If the user is a bot or not
	**/
	public var bot:Bool;

	/**
	 * Idk check discord docs
	**/
	public var flags:Int;

	/**
	 * If the user has nitro
	**/
	public var premiumType:NitroType;

	function new() {}

	public static function initRaw(req:cpp.RawConstPointer<DiscordUser>) {
		return init(cpp.ConstPointer.fromRaw(req).ptr);
	}

	public static function init(userData:cpp.Star<DiscordUser>):DUser {
		var d:DUser = new DUser();
		d.userId = userData.userId;
		d.username = userData.username;
		d.discriminator = Std.parseInt(userData.discriminator);
		d.avatar = userData.avatar;
		d.globalName = userData.globalName;
		d.bot = userData.bot;
		d.flags = userData.flags;
		d.premiumType = userData.premiumType;

		if (d.discriminator != 0)
			d.handle = '${d.username}#${d.discriminator}';
		else d.handle = '${d.username}';
		return d;
	}

	/**
	 * Calling this function gets the BitmapData of the user
	**/
	public function getAvatar(size:Int = 256):openfl.display.BitmapData
		return openfl.display.BitmapData.fromBytes(utils.HttpUtil.requestBytes('https://cdn.discordapp.com/avatars/$userId/$avatar.png?size=$size'));
}

enum abstract NitroType(Int) to Int from Int {
	var NONE = 0;
	var NITRO_CLASSIC = 1;
	var NITRO = 2;
	var NITRO_BASIC = 3;
}