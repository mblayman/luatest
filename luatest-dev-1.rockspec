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
    "lua >= 5.1, < 5.5", -- Only testing against 5.4
    "ansicolors", -- For colors in the output
    "argparse", -- For parsing command line arguments
    "inspect", -- Debugging only
    "luassert", -- The assertions that tests should use
    "luacov", -- For collection test coverage metrics
    "luacov-reporter-lcov", -- Report coverage data in lcov format
    "penlight" -- Utilities used throughout the library
}

build = {type = "builtin", install = {bin = {"bin/luatest"}}}
