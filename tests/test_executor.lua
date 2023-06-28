local assert = require "luassert"
local stub = require "luassert.stub"

local executor = require "luatest.executor"
local Reporter = require "luatest.reporter"

local tests = {}

-- Execution processes a passing test module.
function tests.test_pass()
    local passing = require "tests.demo.passing"
    local test_modules = {["tests/demo/passing.lua"] = {module = passing}}
    local reporter = Reporter()
    stub(reporter, "start_module")
    stub(reporter, "start_test")
    stub(reporter, "finish_test")
    stub(reporter, "finish_module")

    executor.execute(test_modules, reporter)

    assert.stub(reporter.finish_test).was_called_with(reporter,
                                                      "tests/demo/passing.lua",
                                                      "test_passes", true, nil)
end

return tests
