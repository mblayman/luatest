local assert = require "luassert"
local spy = require "luassert.spy"

local collection = require "luatest.collection"

local tests = {}

-- Collection provides a set of test modules and associated meta data.
-- TODO: This can't be done until the tests directory is a config option. See #8
function tests.test_collects_test_modules() end

-- Collection is done in the user's configured directory containing tests.
-- TODO: This can't be done until the tests directory is a config option. See #8
function tests.test_configured_tests_directory() assert.is_true(true) end

-- Collection calculates the total number of tests.
-- TODO: This can't be done until the tests directory is a config option. See #8
function tests.test_total_tests() assert.is_true(true) end

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
