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

    parser:argument("tests"):args("*")

    parser:group("General",
    -- These flags control the amount of output information.
                 parser:flag("-v --verbose", "Show verbose output"),
                 parser:flag("-q --quiet", "Show quiet output"),
    -- Adjustments for how data is processed and stored.
                 parser:flag("--no-capture",
                             "Disable capturing of stdout/stderr"),
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
    if config.debug then
        -- This is a naked print because it comes before the reporter exists.
        -- It also comes before capturing so there is no preventing a user
        -- from seeing this if they use the debug flag.
        -- But if the user is using the unpublished debug flag, guess what?
        -- They're going to see some extra stuff.
        -- luacov: disable
        print("Configuration\n" .. inspect(config))
        -- luacov: enable
    end

    if config.cov then coverage.initialize_coverage(config) end

    local reporter = Reporter(config)
    reporter:capture_standard_files()

    reporter:start_timing()
    local test_modules = collection.collect(config, reporter)
    executor.execute(test_modules, reporter)
    reporter:finish_timing()

    local status = reporter:summarize()

    if config.cov then coverage.finalize_coverage() end

    return status
end

return {main = main}
