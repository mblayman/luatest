local tablex = require "pl.tablex"

-- Run the tests and collect results.
local function execute(test_modules, reporter)
    for relpath, module_info in tablex.sort(test_modules) do
        if relpath ~= "meta" then
            reporter:start_module(relpath)
            for test_name, test in tablex.sort(module_info.module) do
                reporter:start_test(relpath, test_name)
                local status, assertion_details = pcall(test)
                reporter:finish_test(relpath, test_name, status,
                                     assertion_details)
            end
            reporter:finish_module(relpath)
        end
    end

    reporter:finish_execution()
end

return {execute = execute}
