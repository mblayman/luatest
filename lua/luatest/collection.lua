local dir = require "pl.dir"
local path = require "pl.path"
local stringx = require "pl.stringx"
local inspect = require "inspect"

-- Collect all available tests.
local function collect(config)
    local cwd = path.currentdir()
    local tests_dir = path.join(cwd, "tests")

    if config.verbose then
        -- TODO: use a reporter instead of printing.
        -- In fact, the reporter should probably care about verbose, not this collect function.
        print("Searching " .. tests_dir)
    end

    -- This table will hold all test modules that will be used
    -- during the execution phase.
    local test_modules = {meta = {total_tests = 0}}
    local total_tests = 0

    for root, _, files in dir.walk(tests_dir) do
        for file_ in files:iter() do
            if stringx.startswith(file_, "test_") and
                stringx.endswith(file_, ".lua") then
                local filepath = path.join(root, file_)
                local relpath = path.relpath(filepath, cwd)
                local modpath, _ = path.splitext(relpath)
                modpath = stringx.replace(modpath, "/", ".")

                local test_module = require(modpath)

                -- Count tests.
                local tests_count = 0
                for _ in pairs(test_module) do
                    tests_count = tests_count + 1
                end
                total_tests = total_tests + tests_count

                test_modules[relpath] = {
                    module = test_module,
                    tests_count = tests_count
                }
            end
        end
    end

    test_modules.meta = {total_tests = total_tests}

    if config.debug then
        print('Test Modules')
        print(inspect(test_modules))
    end

    return test_modules
end

return {collect = collect}
