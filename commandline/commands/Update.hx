package commands;

import haxe.xml.Access;
import haxe.Json;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

class Update {
	public static function main(args:Array<String>) {
		prettyPrint("Preparing installation...");

		// to prevent messing with currently installed libs
		if (!FileSystem.exists('.haxelib'))
			FileSystem.createDirectory('.haxelib');

		var libs:Array<Library> = [];
		var libsXML:Access = new Access(Xml.parse(File.getContent('./libs.xml')).firstElement());

		for (libNode in libsXML.elements) {
			var lib:Library = {
				name: libNode.att.name,
				type: libNode.name
			};
			if (libNode.has.global) lib.global = libNode.att.global;
			switch (lib.type) {
				case "lib":
					if (libNode.has.version) lib.version = libNode.att.version;
				case "git":
					if (libNode.has.url) lib.url = libNode.att.url;
					if (libNode.has.ref) lib.ref = libNode.att.ref;
			}
			libs.push(lib);
		}

		for(lib in libs) {
			var globalism:Null<String> = lib.global == "true" ? "--global" : null;
			switch(lib.type) {
				case "lib":
					prettyPrint((lib.global == "true" ? "Globally installing" : "Locally installing") + ' "${lib.name}"...');
					Sys.command('haxelib install ${lib.name} ${lib.version != null ? " " + lib.version : " "}${globalism != null ? ' $globalism' : ''} --always');
				case "git":
					prettyPrint((lib.global == "true" ? "Globally installing" : "Locally installing") + ' "${lib.name}" from git url "${lib.url}"');
					Sys.command('haxelib git ${lib.name} ${lib.url}${lib.ref != null ? ' ${lib.ref}' : ''}${globalism != null ? ' $globalism' : ''} --always');
				default:
					prettyPrint('Cannot resolve library of type "${lib.type}"');
			}
		}

		// vswhere.exe its used to find any visual studio related installations on the system, including full visual studio ide installations, visual studio build tools installations, and other related components  - Nex
		if (Compiler.getBuildTarget().toLowerCase() == "windows" && new Process('"C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe" -property catalog_productDisplayVersion').exitCode(true) == 1) {
			prettyPrint("Installing Microsoft Visual Studio Community (Dependency)");

			// thanks to @crowplexus for these two lines!  - Nex
			Sys.command("curl -# -O https://download.visualstudio.microsoft.com/download/pr/3105fcfe-e771-41d6-9a1c-fc971e7d03a7/8eb13958dc429a6e6f7e0d6704d43a55f18d02a253608351b6bf6723ffdaf24e/vs_Community.exe");
			Sys.command("vs_Community.exe --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 -p");

			FileSystem.deleteFile("vs_Community.exe");
			prettyPrint('If it didn\'t say it before: Because of this component if you want to compile you have to restart the device.');
			Sys.print("Do you wish to do it now [y/n]? ");
			if(Sys.stdin().readLine().toLowerCase() == "y") Sys.command("shutdown /r /t 0 /f");
		}
	}

	public static function prettyPrint(text:String) {
		var lines = text.split("\n");
		var length = -1;
		for(line in lines)
			if(line.length > length)
				length = line.length;
		var header = "══════";
		for(i in 0...length)
			header += "═";
		Sys.println("");
		Sys.println('╔$header╗');
		for(line in lines) {
			Sys.println('║   ${centerText(line, length)}   ║');
		}
		Sys.println('╚$header╝');
	}

	public static function centerText(text:String, width:Int):String {
		var centerOffset = (width - text.length) / 2;
		var left = repeat(' ', Math.floor(centerOffset));
		var right = repeat(' ', Math.ceil(centerOffset));
		return left + text + right;
	}

	public static inline function repeat(ch:String, amt:Int) {
		var str = "";
		for(i in 0...amt)
			str += ch;
		return str;
	}
}

typedef Library = {
	var name:String;
	var type:String;
	var ?global:String;
	var ?version:String;
	var ?ref:String;
	var ?url:String;
}
