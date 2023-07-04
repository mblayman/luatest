local assert = require "luassert"

local coverage = require "luatest.coverage"

local tests = {}

-- Note: Portions of the coverage module are not very testable (irony?)
-- because they might interfere with actual coverage collection for this tool.

function tests.test_set_included_files()
    local config = {cov = "tests/demo"}
    local configuration = {include = {}}

    coverage.set_included_files(config, configuration)

    local expected = {
        ["tests/demo/failing"] = true,
        ["tests/demo/empty"] = true,
        ["tests/demo/not_a_module"] = true,
        ["tests/demo/passing"] = true
    }
    for _, module in pairs(configuration.include) do expected[module] = nil end
    assert.is_same({}, expected)
end

return tests
