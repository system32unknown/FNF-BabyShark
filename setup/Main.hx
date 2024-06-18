package;

import haxe.Json;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

using StringTools;

typedef Library = {
	var name:String; var type:String;
	var version:String; var dir:String;
	var ref:String; var url:String;
}

class Main {
	public static function main() {
		var isHMM:Bool = getProcessOutput('haxelib', ['list', 'hmm']).contains('hmm'), prevCwd = Sys.getCwd(), mainCwd;
		var json:Array<Library> = Json.parse(File.getContent('./setup/libraries.json')).dependencies;
		if (isHMM) {
			if (!FileSystem.exists('.haxelib')) FileSystem.createDirectory('.haxelib');
			Sys.setCwd(mainCwd = '$prevCwd/.haxelib');
		} else Sys.setCwd(mainCwd = getProcessOutput('haxelib', ['config']).rtrim());

		try {
			Sys.println("Preparing installation...");

			for (lib in json) {
				switch(lib.type) {
					case "haxelib":
						Sys.println('Installing "${lib.name}"...');   
						var vers:String = lib.version != null ? lib.version : "";          
						if (isHMM) Sys.command('hmm haxelib ${lib.name} $vers');
						else {
							Sys.command('haxelib install ${lib.name} ${vers} --quiet');
							if (lib.version != null) File.saveContent('${lib.name}/.current', vers);
						}
					case "git":
						if (!FileSystem.exists(lib.dir)) FileSystem.createDirectory(lib.dir);
						else if (!isHMM && FileSystem.exists('${lib.dir}/dev')) continue;

						Sys.println('Installing "${lib.name}" from git url "${lib.url}" ${lib.ref != null ? '(with branch: ${lib.ref})' : ''}');

						if (FileSystem.exists('${lib.dir}/git')) {
							Sys.setCwd('$mainCwd/${lib.dir}/git');
							Sys.command('git pull');
						} else {
							Sys.setCwd('$mainCwd/${lib.dir}');
							Sys.command('git clone --recurse-submodules ${lib.url} git ${lib.ref != null ? '--branch' : ''} ${lib.ref}');
							
							if (!isHMM) File.saveContent('.current', 'git');
						}
						Sys.setCwd(mainCwd);
					default: Sys.println('Cannot resolve library of type "${lib.type}"');
				}
			}
			Sys.println("Install Hxcpp with git manually and compile it.");
		} catch(e) trace(e);

		Sys.setCwd(prevCwd);
		Sys.exit(0);
	}

	public static function getProcessOutput(cmd:String, args:Array<String>):String {
		try {
			var process:Process = new Process(cmd, args), output = "";
			try {output = process.stdout.readAll().toString();}
			catch (_) {}

			process.close();
			return output;
		} catch (_) return "";
	}
}