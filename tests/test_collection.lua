local assert = require "luassert"
local spy = require "luassert.spy"

local collection = require "luatest.collection"

local tests = {}

-- Collection provides a set of test modules and associated meta data.
function tests.test_collects_test_modules()
    local test_something = require "tests.demo.test_something"
    local config = {tests_dir = "tests/demo"}
    local reporter = {}
    spy.on(reporter, "start_collection")
    spy.on(reporter, "finish_collection")

    -- TODO: use the upcoming test file pattern rename so the demo tests
    -- don't appear as part of the whole suite.
    -- TODO: include another test file to show that total calculation is working.
    local test_modules = collection.collect(config, reporter)

    assert.is_same({
        meta = {total_tests = 1},
        ["tests/demo/test_something.lua"] = {
            module = {test_foo = test_something.test_foo},
            tests_count = 1
        }
    }, test_modules)
end

-- A module that doesn't look like a table of functions triggers a warning.
function tests.test_non_module()
    local relpath = "tests/demo/not_a_module.lua"
    local test_module = require "tests/demo/not_a_module"
    local test_modules = {}
    local reporter = {}
    spy.on(reporter, "warn")

    local test_count = collection.process_module(relpath, test_module,
                                                 test_modules, reporter)

    assert.spy(reporter.warn).was_called_with(reporter,
                                              "tests/demo/not_a_module.lua is not a module. " ..
                                                  "Did you remember to return tests?")
    assert.is_same(test_modules, {})
    assert.is_equal(test_count, 0)
end

-- A module that has no function triggers a warning.
function tests.test_empty_module()
    local relpath = "tests/demo/empty.lua"
    local test_module = require "tests/demo/empty"
    local test_modules = {}
    local reporter = {}
    spy.on(reporter, "warn")

    local test_count = collection.process_module(relpath, test_module,
                                                 test_modules, reporter)

    assert.spy(reporter.warn).was_called_with(reporter,
                                              "No tests found in tests/demo/empty.lua")
    assert.is_same(test_modules, {})
    assert.is_equal(test_count, 0)
end
return tests
