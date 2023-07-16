local assert = require "luassert"
local stub = require "luassert.stub"
local path = require "pl.path"

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

-- The coverage directory exists or is an error.
function tests.test_coverage_directory_exists()
    local cwd = path.currentdir()
    local src = path.join(cwd, "not/real")
    local Reporter = require "luatest.reporter"
    stub(Reporter, "fatal_early")

    coverage.validate_coverage_directory(src)

    local expected = src .. " is not a valid directory for coverage."
    assert.stub(Reporter.fatal_early).was_called_with(expected)
    Reporter.fatal_early:revert()
end

return tests
