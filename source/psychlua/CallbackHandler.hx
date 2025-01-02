package psychlua;

class CallbackHandler {
	public static inline function call(l:State, fname:String):Int {
		try {
			var cbf:Dynamic = Lua_helper.callbacks.get(fname);
			if (cbf == null) {
				var last:FunkinLua = FunkinLua.lastCalledScript;
				if (last == null || last.lua != l) {
					for (script in PlayState.instance.luaArray)
						if (script != FunkinLua.lastCalledScript && script != null && script.lua == l) {
							cbf = script.callbacks.get(fname);
							break;
						}
				} else cbf = last.callbacks.get(fname);
			}

			if (cbf == null) return 0;

			var ret:Dynamic = Reflect.callMethod(null, cbf, [for (i in 0...Lua.gettop(l)) Convert.fromLua(l, i + 1)]);
			if (ret != null) {
				Convert.toLua(l, ret);
				return 1;
			}
		} catch(e:haxe.Exception) {
			if (Lua_helper.sendErrorsToLua) {
				LuaL.error(l, 'CALLBACK ERROR! ${e.details()}');
				return 0;
			}
			throw e;
		}
		return 0;
	}
}