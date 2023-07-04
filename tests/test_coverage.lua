local assert = require "luassert"

local coverage = require "luatest.coverage"

local tests = {}

-- Note: Portions of the coverage module are not very testable (irony?)
-- because they might interfere with actual coverage collection for this tool.

function tests.test_set_included_files()
    local config = {cov = "tests/demo"}
    local configuration = {include = {}}

    coverage.set_included_files(config, configuration)

    assert.is_same({
        include = {
            "tests/demo/failing", "tests/demo/empty", "tests/demo/not_a_module",
            "tests/demo/passing"
        }
    }, configuration)
end

return tests
