local argparse = require "argparse"
local inspect = require "inspect"

local collection = require "luatest.collection"
local configuration = require "luatest.configuration"
local coverage = require "luatest.coverage"
local executor = require "luatest.executor"
local Reporter = require "luatest.reporter"

-- Build the interface parser.
local function build_parser()
    local parser = argparse("luatest", "A Lua test runner")
    parser:add_help(true)

    parser:group("General", parser:flag("-v --verbose", "Show verbose output"),
    -- The debug flag is for developing luatest
    -- and is not meant to be a user-level feature.
                 parser:flag("-d --debug", "Show debug output"):hidden(true))

    parser:group("Coverage",
                 parser:option("--cov",
                               "Measure coverage of the provided directory")
                     :argname("<dir>"))
    return parser
end

-- The initial entry point of the tool
local function main(args)
    local parser = build_parser()
    local config = parser:parse(args)
    configuration.load_config_file(config)
    if config.debug then print("Configuration\n" .. inspect(config)) end

    if config.cov then coverage.initialize_coverage(config) end

    local reporter = Reporter(config)
    reporter:start()

    local test_modules = collection.collect(config, reporter)
    executor.execute(test_modules, reporter)

    reporter:finish()
    local status = reporter:summarize()

    if config.cov then coverage.finalize_coverage() end

    return status
end

return {main = main}
