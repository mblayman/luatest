local assert = require "luassert"
local stub = require "luassert.stub"

local executor = require "luatest.executor"
local Reporter = require "luatest.reporter"

local tests = {}

local function stubbed_reporter()
    local reporter = Reporter()
    stub(reporter, "start_module")
    stub(reporter, "start_test")
    stub(reporter, "finish_test")
    stub(reporter, "finish_module")
    stub(reporter, "finish_execution")
    return reporter
end

-- Execution processes a passing test module.
function tests.test_pass()
    local passing = require "tests.demo.passing"
    local test_modules = {["tests/demo/passing.lua"] = {module = passing}}
    local reporter = stubbed_reporter()

    executor.execute(test_modules, reporter)

    assert.stub(reporter.finish_test).was_called_with(reporter,
                                                      "tests/demo/passing.lua",
                                                      "test_passes", true, nil)
end

-- Execution processes a failing test module.
function tests.test_fail()
    local failing = require "tests.demo.failing"
    local test_modules = {["tests/demo/failing.lua"] = {module = failing}}
    local reporter = stubbed_reporter()

    executor.execute(test_modules, reporter)

    local assertion_details =
        "./tests/demo/failing.lua:6: Expected objects to be the same.\n" ..
            "Passed in:\n(boolean) false\nExpected:\n(boolean) true"
    assert.stub(reporter.finish_test).was_called_with(reporter,
                                                      "tests/demo/failing.lua",
                                                      "test_fails", false,
                                                      assertion_details)
end

return tests
