local argparse = require "argparse"
local inspect = require "inspect"

local collection = require "luatest.collection"
local executor = require "luatest.executor"
local Reporter = require "luatest.reporter"

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

    local reporter = Reporter(config)
    reporter:start()

    if config.debug then print("Configuration\n" .. inspect(config)) end

    local test_modules = collection.collect(config, reporter)
    executor.execute(test_modules, reporter)

    reporter:finish()
    return reporter:summarize()
end

return {main = main}
