local dir = require "pl.dir"
local path = require "pl.path"
local stringx = require "pl.stringx"
local inspect = require "inspect"

-- Collect all available tests.
local function collect(config)
    local cwd = path.currentdir()
    -- TODO: make this configurable.
    local tests_dir = path.join(cwd, "tests")

    if config.verbose then
        -- TODO: use a reporter instead of printing.
        -- In fact, the reporter should probably care about verbose, not this collect function.
        print("Searching " .. tests_dir)
    end

    -- This table will hold all test modules that will be used
    -- during the execution phase.
    local test_modules = {meta = {total_tests = 0}}

    for root, _, files in dir.walk(tests_dir) do
        for file_ in files:iter() do
            if stringx.startswith(file_, "test_") and
                stringx.endswith(file_, ".lua") then
                local filepath = path.join(root, file_)
                local relpath = path.relpath(filepath, cwd)
                local modpath, _ = path.splitext(relpath)
                modpath = stringx.replace(modpath, "/", ".")

                local test_module = require(modpath)
                -- TODO: Count tests. Set tests_count and update total_tests.
                test_modules[relpath] = {module = test_module, tests_count = 42}
            end
        end
    end

    if config.debug then
        print('Test Modules')
        print(inspect(test_modules))
    end

    return test_modules
end

return {collect = collect}
