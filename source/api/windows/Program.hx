package api.windows;

import sys.io.Process;

class Program {
    public static function checkIfRunningbyArray(programName:Array<String>):Bool {
        var taskList = new Process("tasklist", []);
        var programs = taskList.stdout.readAll().toString().toLowerCase();
            
        var checkProgram:Array<String> = programName;
        for (i in 0...checkProgram.length) {
            if (programs.contains(checkProgram[i]))
                taskList.close();
                return true;
        }
        taskList.close();
        return false;
    }

    public static function checkIfRunning(programName:String):Bool {
        var taskList = new Process("tasklist", []);
        var programs = taskList.stdout.readAll().toString().toLowerCase();
            
        if (programs.contains(programName))
            taskList.close();
            return true;

        taskList.close();
        return false;
    }
}