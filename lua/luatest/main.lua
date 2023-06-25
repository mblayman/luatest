local argparse = require "argparse"
local inspect = require "inspect"

local collection = require "luatest.collection"
local executor = require "luatest.executor"

-- Build the interface parser.
local function build_parser()
    local parser = argparse("luatest", "A Lua test runner")
    parser:add_help(true)
    parser:flag("-v --verbose", "Show verbose output")
    -- This should probably go away once things are more stable.
    parser:flag("-d --debug", "Show debug output")
    return parser
end

-- The initial entry point of the tool
local function main(args)
    local parser = build_parser()
    local config = parser:parse(args)

    if config.debug then print(inspect(config)) end

    local test_modules = collection.collect(config)
    executor.execute(test_modules)
end

return {main = main}
