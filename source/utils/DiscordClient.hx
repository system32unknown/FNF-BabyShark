package utils;

import Sys.sleep;
import discord_rpc.DiscordRpc;
import lime.app.Application;

class DiscordClient
{
	public static var isInitialized:Bool = false;

	static var _defaultID:String = "1013313492889108510";
	public static var clientID(default, set):String = _defaultID;
	#if DISCORD_ALLOWED
	public static var queue:DiscordPresenceOptions = {
		details: "In the Menus",
		state: null,
		largeImageKey: (ClientPrefs.getPref('AltDiscordImg') ? 'iconalt' : 'icon'),
		largeImageText: 'Baby Shark\'s Funkin'
	}
	#end

	public function new()
	{
		#if DISCORD_ALLOWED
		trace("Discord Client starting...");
		DiscordRpc.start({
			clientID: clientID,
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected
		});
		trace("Discord Client started.");

		while (true) {
			DiscordRpc.process();
			sleep(2);
		}

		DiscordRpc.shutdown();
		#end
	}
	
	public static function check() {
		if(!ClientPrefs.getPref('discordRPC')) {
			if(DiscordClient.isInitialized) DiscordClient.shutdown();
			DiscordClient.isInitialized = false;
		} else DiscordClient.start();
	}

	public static function start() {
		if (!DiscordClient.isInitialized && ClientPrefs.getPref('discordRPC')) {
			DiscordClient.initialize();
			Application.current.window.onClose.add(function() {
				DiscordClient.shutdown();
			});
		}
	}

	public static function resetID() {
		if(clientID != _defaultID) clientID = _defaultID;
	}

	public static function shutdown() {
		#if DISCORD_ALLOWED
		DiscordRpc.shutdown();
		#end
	}
	
	static function onReady() {
		#if DISCORD_ALLOWED
		changePresence(
			queue.details, queue.state, queue.smallImageKey,
			queue.startTimestamp == 1 ? true : false,
			queue.endTimestamp
		);
		#end
	}

	static function set_clientID(newID:String) {
		clientID = newID;
		if(isInitialized) {
			DiscordClient.shutdown();
			isInitialized = false;
			start();
		}
		return newID;
	}

	static function onError(_code:Int, _message:String) {
		trace('Error! $_code : $_message');
	}

	static function onDisconnected(_code:Int, _message:String) {
		trace('Disconnected! $_code : $_message');
	}

	public static function initialize() {
		#if DISCORD_ALLOWED
		sys.thread.Thread.create(() -> {
			new DiscordClient();
		});
		trace("Discord Client initialized");
		isInitialized = true;
		#end
	}

	public static function changePresence(details:String, state:Null<String>, ?smallImageKey : String, ?hasStartTimestamp : Bool, ?endTimestamp: Float)
	{
		#if DISCORD_ALLOWED
		var startTimestamp:Float = if(hasStartTimestamp) Date.now().getTime() else 0;
		if (endTimestamp > 0) endTimestamp = startTimestamp + endTimestamp;

		var presence:DiscordPresenceOptions = {
			details: details,
			state: state,
			largeImageKey: (ClientPrefs.getPref('AltDiscordImg') ? 'iconalt' : 'icon'),
			largeImageText: 'Baby Shark\'s Funkin',
			smallImageKey : smallImageKey,
			// Obtained times are in milliseconds so they are divided so Discord can use it
			startTimestamp : Std.int(startTimestamp / 1000),
            endTimestamp : Std.int(endTimestamp / 1000)
		};

		DiscordRpc.presence(presence);
		#end
	}
}
