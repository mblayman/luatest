local inspect = require "inspect"
local defaults = require "luacov.defaults"
local runner = require "luacov.runner"
local dir = require "pl.dir"
local path = require "pl.path"

local Reporter = require "luatest.reporter"

-- Validate that the coverage directory exists.
local function validate_coverage_directory(coverage_directory)
    if not path.isdir(coverage_directory) then
        Reporter.fatal_early(coverage_directory ..
                                 " is not a valid directory for coverage.")
    end
end

-- Set all the files that should be measured for coverage.
local function set_included_files(config, configuration)
    -- Include all source files in luacov format
    -- (i.e. with forward slash and no extension)
    local cwd = path.currentdir()
    local src = path.join(cwd, config.cov)

    validate_coverage_directory(src)

    for root, _, files in dir.walk(src) do
        for file_ in files:iter() do
            local filepath = path.join(root, file_)
            local relpath = path.relpath(filepath, cwd)
            local modpath, _ = path.splitext(relpath)
            table.insert(configuration.include, modpath)
        end
    end
end

local function initialize_coverage(config)
    -- luacov: disable
    local configuration = {}
    for setting, value in pairs(defaults) do configuration[setting] = value end

    set_included_files(config, configuration)

    -- Override defaults.
    configuration.runreport = true
    configuration.reporter = "lcov"
    configuration.reportfile = "lcov.info"
    configuration.deletestats = true
    -- This is provisional. I'm not sure if I actually want this setting
    -- since I can't fully understand its behavior yet.
    configuration.includeuntestedfiles = true

    if config.debug then
        print("Coverage configuration\n" .. inspect(configuration) .. "\n")
    end

    runner.init(configuration)
    -- luacov: enable
end

-- Finalize coverage measurement directly because the os.exit hook isn't running.
local function finalize_coverage() runner.shutdown() end

return {
    initialize_coverage = initialize_coverage,
    finalize_coverage = finalize_coverage,
    set_included_files = set_included_files,
    validate_coverage_directory = validate_coverage_directory
}
