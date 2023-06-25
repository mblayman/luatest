rockspec_format = "3.0"
package = "luatest"
version = "dev-1"

source = {url = "git+ssh://git@github.com/mblayman/luatest.git"}

description = {
    summary = "A Lua test runner",
    detailed = "A Lua test runner",
    homepage = "https://github.com/mblayman/luatest",
    license = "MIT"
}

dependencies = {
    "lua >= 5.1, < 5.5", "argparse", "inspect", "luassert", "penlight"
}

build = {type = "builtin", install = {bin = {"bin/luatest"}}}
