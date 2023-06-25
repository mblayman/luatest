local ansicolors = require "ansicolors"
local tablex = require "pl.tablex"

-- Run the tests and collect results.
local function execute(test_modules)
    for relpath, module_info in tablex.sort(test_modules) do
        if relpath ~= "meta" then
            -- TODO: support verbose output of test.

            io.write(relpath .. " ")
            for _, test in tablex.sort(module_info.module) do
                -- print(test_name)
                local status, _ = pcall(test)
                if status then
                    io.write(ansicolors("%{green}."))
                else
                    io.write(ansicolors("%{red}F"))
                    -- print(assertion_details)
                end
            end
            io.write("\n")
        end
    end

    print()
end

return {execute = execute}
