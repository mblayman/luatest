local dir = require "pl.dir"
local path = require "pl.path"
local stringx = require "pl.stringx"
local inspect = require "inspect"

-- Report errors.
local function report_errors(errors, reporter)
    if #errors ~= 0 then
        for _, error in ipairs(errors) do reporter:error(error) end
        reporter:fatal("Collection failed.")
    end
end

-- Process module and store it with the collected modules.
local function process_module(relpath, test_module, test_meta, test_modules,
                              reporter)
    local tests = {}

    if test_module == true then
        reporter:warn(relpath ..
                          " is not a module. Did you remember to return tests?")
    else
        if test_meta.collect_all then
            for test, _ in pairs(test_module) do
                table.insert(tests, test)
            end
        else
            local errors = {}
            for test, _ in pairs(test_meta.tests) do
                if test_module[test] then
                    table.insert(tests, test)
                else
                    table.insert(errors, relpath ..
                                     " has no test function named " .. test)
                end
            end

            report_errors(errors, reporter)
        end

        if #tests == 0 then
            reporter:warn("No tests found in " .. relpath)
        else
            test_modules[relpath] = {module = test_module, tests = tests}
        end
    end

    return #tests
end

-- Collect a test module file.
-- This function assumes that the file is within the tests directory.
local function collect_file(reporter, test_path, test_meta, cwd, test_modules)
    local relpath = path.relpath(test_path, cwd)

    -- Load module.
    local modpath, _ = path.splitext(relpath)
    modpath = stringx.replace(modpath, "/", ".")
    local test_module = require(modpath)

    -- Process the module.
    return process_module(relpath, test_module, test_meta, test_modules,
                          reporter)
end

-- Collect a directory.
-- This function assumes that the directory is within (or is) the tests directory.
local function collect_directory(config, reporter, directory, cwd, test_modules)
    local total_tests = 0
    for root, _, files in dir.walk(directory) do
        for file_ in files:iter() do
            if string.match(file_, config.test_file_pattern) then
                local filepath = path.join(root, file_)
                local tests_count = collect_file(reporter, filepath,
                                                 {collect_all = true}, cwd,
                                                 test_modules)
                total_tests = total_tests + tests_count
            end
        end
    end
    return total_tests
end

-- Check that any user provided test appears in the tests directory.
local function check_tests_in_tests_dir(config, reporter)
    local errors = {}
    for _, test in ipairs(config.tests) do
        if not stringx.startswith(test, config.tests_dir) then
            table.insert(errors, test .. " is not in the tests directory.")
        end
    end

    report_errors(errors, reporter)
end

-- Check that the user reported test files all conform to the test pattern
local function check_files_are_tests(config, reporter, files_map)
    local errors = {}
    for test_path, _ in pairs(files_map) do
        if not string.match(test_path, config.test_file_pattern) then
            table.insert(errors,
                         test_path .. " does not match the test file pattern.")
        end
    end

    report_errors(errors, reporter)
end

-- Clean user provided tests.
-- This returns a structure that can be used for collection on directories and files.
local function clean_tests(config, reporter)
    local errors = {}
    check_tests_in_tests_dir(config, reporter)

    -- For collection, directories and files need to be processed separately.
    -- This structure also uses the directories and files tables as maps
    -- in order to de-duplicate any user provided input.
    local tests_map = {directories = {}, files = {}}

    for _, test in ipairs(config.tests) do
        local has_test_name = false
        local test_path = string.match(test, "(.*)::")
        if test_path then
            has_test_name = true
        else
            test_path = test
        end

        if path.isdir(test_path) then
            if has_test_name then
                table.insert(errors,
                             "Test name filtering does not apply to directories: " ..
                                 test)
            end
            tests_map.directories[test_path] = true
        elseif path.isfile(test_path) then
            if has_test_name then
                local test_name = string.match(test, "::(.*)")
                if not tests_map.files[test_path] then
                    tests_map.files[test_path] = {
                        collect_all = false,
                        tests = {}
                    }
                end

                -- Only merge in another test when not collecting all tests.
                if not tests_map.files[test_path].collect_all then
                    tests_map.files[test_path].tests[test_name] = true
                end
            else
                tests_map.files[test_path] = {collect_all = true}
            end
        else
            table.insert(errors, test_path .. " is an invalid test path.")
        end
    end

    check_files_are_tests(config, reporter, tests_map.files)

    if config.debug then
        -- luacov: disable
        reporter:print('\nCollected tests:\n' .. inspect(tests_map) .. "\n")
        -- luacov: enable
    end

    report_errors(errors, reporter)
    return tests_map
end

-- Collect all available tests.
local function collect(config, reporter)
    local cwd = path.currentdir()
    local tests_dir = path.join(cwd, config.tests_dir)

    reporter:start_collection(tests_dir)

    -- This table will hold all test modules that will be used
    -- during the execution phase.
    local test_modules = {meta = {total_tests = 0}}
    local total_tests = 0

    if #config.tests == 0 then
        total_tests = collect_directory(config, reporter, tests_dir, cwd,
                                        test_modules)
    else
        local tests_map = clean_tests(config, reporter)
        for directory, _ in pairs(tests_map.directories) do
            local tests_count = collect_directory(config, reporter, directory,
                                                  cwd, test_modules)
            total_tests = total_tests + tests_count
        end
        for test_path, test_meta in pairs(tests_map.files) do
            test_path = path.join(cwd, test_path)
            local tests_count = collect_file(reporter, test_path, test_meta,
                                             cwd, test_modules)
            total_tests = total_tests + tests_count
        end
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

return {
    collect = collect,
    check_tests_in_tests_dir = check_tests_in_tests_dir,
    check_files_are_tests = check_files_are_tests,
    clean_test = clean_tests,
    process_module = process_module,
    report_errors = report_errors
}
