local dir = require "pl.dir"
local path = require "pl.path"
local stringx = require "pl.stringx"
local inspect = require "inspect"

-- Process module and store it with the collected modules.
local function process_module(relpath, test_module, test_modules, reporter)
    local tests_count = 0

    if test_module == true then
        reporter:warn(relpath ..
                          " is not a module. Did you remember to return tests?")
    else
        for _ in pairs(test_module) do tests_count = tests_count + 1 end

        if tests_count == 0 then
            reporter:warn("No tests found in " .. relpath)
        else
            test_modules[relpath] = {
                module = test_module,
                tests_count = tests_count
            }
        end
    end

    return tests_count
end

-- Collect a directory.
-- This function assumes that the directory is within (or is) the tests directory.
local function collect_directory(config, reporter, directory, cwd, test_modules)
    local total_tests = 0
    for root, _, files in dir.walk(directory) do
        for file_ in files:iter() do
            if string.match(file_, config.test_file_pattern) then
                local filepath = path.join(root, file_)
                local relpath = path.relpath(filepath, cwd)

                -- Load module.
                local modpath, _ = path.splitext(relpath)
                modpath = stringx.replace(modpath, "/", ".")
                local test_module = require(modpath)

                -- Process the module.
                local tests_count = process_module(relpath, test_module,
                                                   test_modules, reporter)
                total_tests = total_tests + tests_count
            end
        end
    end
    return total_tests
end

-- Collect all available tests.
local function collect(config, reporter)
    local cwd = path.currentdir()
    local tests_dir = path.join(cwd, config.tests_dir)

    reporter:start_collection(tests_dir)

    -- 1. no tests, run all
    -- 2. validate paths, deduplicate, group by directories and files
    -- 3. collect directories, reject directories with test filter
    -- 4. collect whole files
    -- 5. collect individual tests (don't reload module repeatedly)

    -- This table will hold all test modules that will be used
    -- during the execution phase.
    local test_modules = {meta = {total_tests = 0}}
    local total_tests = 0

    if #config.tests == 0 then
        total_tests = collect_directory(config, reporter, tests_dir, cwd,
                                        test_modules)
    else
        print('pos args')
    end

    test_modules.meta = {total_tests = total_tests}

    if config.debug then
        -- luacov: disable
        reporter:print('\nTest Modules')
        reporter:print(inspect(test_modules) .. "\n")
        -- luacov: enable
    end

    reporter:finish_collection(total_tests)
    return test_modules
end

return {collect = collect, process_module = process_module}
