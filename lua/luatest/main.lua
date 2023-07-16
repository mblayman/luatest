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

-- Update the package path.
--
-- LuaRocks binary entry points will modify the package.path
-- to prepend the local tree. This is a problem if the project is installed
-- in the local tree (which is likely scenario if someone used
-- `luarocks make` to install a project's dependencies).
-- Since luatest's goal is to test source file changes,
-- prepend the most likely locations of source files so that any loaded module
-- will search locally before checking the tree.
--
-- As an implementation detail, the package module is done
-- with dependency injection to make this easier to test without messing
-- with global state.
local function update_package_path(config, package_module)
    -- Add "lua" and "src" because those are common names.
    local lua_path = "lua/?.lua;lua/?/init.lua;"
    local src_path = "src/?.lua;src/?/init.lua;"
    package_module.path = lua_path .. src_path .. package_module.path

    if config.cov and config.cov ~= "lua" and config.cov ~= "src" then
        local cov_path = config.cov .. "/?.lua;" .. config.cov .. "/?/init.lua;"
        package_module.path = cov_path .. package_module.path
    end
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

    update_package_path(config, package)

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

return {main = main, update_package_path = update_package_path}
