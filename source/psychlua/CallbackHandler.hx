package psychlua;

class CallbackHandler {
	public static inline function call(l:State, fname:String):Int {
		try {
			var cbf:Dynamic = Lua_helper.callbacks.get(fname);

			if(cbf == null)  {
				for (script in PlayState.instance.luaArray)
					if(script != null && script.lua == l) {
						cbf = script.callbacks.get(fname);
						break;
					}
			}
			
			if(cbf == null) return 0;

			var nparams:Int = Lua.gettop(l);
			var args:Array<Dynamic> = [];

			for (i in 0...nparams) {
				args[i] = Convert.fromLua(l, i + 1);
			}

			var ret:Dynamic = null;
			ret = Reflect.callMethod(null, cbf, args);
			if(ret != null) {
				Convert.toLua(l, ret);
				return 1;
			}
		} catch(e:Dynamic) {
			if(Lua_helper.sendErrorsToLua) {LuaL.error(l, 'CALLBACK ERROR! ${if(e.message != null) e.message else e}');return 0;}
			trace(e);
			throw(e);
		}
		return 0;
	}
}