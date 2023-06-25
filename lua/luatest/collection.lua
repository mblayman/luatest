local ansicolors = require "ansicolors"
local dir = require "pl.dir"
local path = require "pl.path"
local stringx = require "pl.stringx"
local inspect = require "inspect"

-- Process module and store it with the collected modules.
local function process_module(relpath, test_module, test_modules)
    local tests_count = 0

    if test_module == true then
        print(relpath .. " is not a module. Did you remember to return tests?")
    else
        for _ in pairs(test_module) do tests_count = tests_count + 1 end

        if tests_count == 0 then
            print("No tests found in " .. relpath)
        else
            test_modules[relpath] = {
                module = test_module,
                tests_count = tests_count
            }
        end
    end

    return tests_count
end

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

                -- Load module.
                local modpath, _ = path.splitext(relpath)
                modpath = stringx.replace(modpath, "/", ".")
                local test_module = require(modpath)

                -- Process the module.
                local tests_count = process_module(relpath, test_module,
                                                   test_modules)
                total_tests = total_tests + tests_count
            end
        end
    end

    test_modules.meta = {total_tests = total_tests}

    if config.debug then
        print('Test Modules')
        print(inspect(test_modules))
    end

    local tests_label = " tests\n"
    if test_modules.meta.total_tests == 1 then tests_label = " test\n" end
    print(ansicolors("%{bright}Collected " .. test_modules.meta.total_tests ..
                         tests_label))

    return test_modules
end

return {collect = collect}
