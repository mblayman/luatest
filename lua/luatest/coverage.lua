local inspect = require "inspect"
local defaults = require "luacov.defaults"
local runner = require "luacov.runner"
local dir = require "pl.dir"
local path = require "pl.path"

local function initialize_coverage(config)
    local configuration = {}
    for setting, value in pairs(defaults) do configuration[setting] = value end

    -- Include all source files in luacov format
    -- (i.e. with forward slash and no extension)
    local cwd = path.currentdir()
    local src = path.join(cwd, config.cov)
    for root, _, files in dir.walk(src) do
        for file_ in files:iter() do
            local filepath = path.join(root, file_)
            local relpath = path.relpath(filepath, cwd)
            local modpath, _ = path.splitext(relpath)
            table.insert(configuration.include, modpath)
        end
    end

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
end

-- Finalize coverage measurement directly because the os.exit hook isn't running.
local function finalize_coverage() runner.shutdown() end

return {
    initialize_coverage = initialize_coverage,
    finalize_coverage = finalize_coverage
}
