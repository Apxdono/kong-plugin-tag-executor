-- LuaRocks configuration

rocks_trees = {
   { name = "user", root = home .. "/.luarocks" };
   { name = "system", root = "/home/runner/work/kong-plugin-tag-executor/kong-plugin-tag-executor/.luarocks" };
}
lua_interpreter = "lua";
variables = {
   LUA_DIR = "/home/runner/work/kong-plugin-tag-executor/kong-plugin-tag-executor/.lua";
   LUA_BINDIR = "/home/runner/work/kong-plugin-tag-executor/kong-plugin-tag-executor/.lua/bin";
}
