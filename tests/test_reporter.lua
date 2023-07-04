local assert = require "luassert"

local Reporter = require "luatest.reporter"

local tests = {}

-- Get all the file content.
local function get_content(file)
    file:seek("set", 0)
    return file:read("a")
end

-- Reporter sets the start state.
function tests.test_start()
    local reporter = Reporter()

    reporter:start()

    assert.is_not_nil(reporter._start)
end

-- Reporter sets the finish state.
function tests.test_finish()
    local reporter = Reporter()

    reporter:finish()

    assert.is_not_nil(reporter._finish)
end

-- Print with no message is transformed to an empty string.
function tests.test_print_empty()
    local config = {}
    local file = io.tmpfile()
    local reporter = Reporter(config, file)

    reporter:_print()

    assert.is_equal("\n", get_content(file))
end

-- A warning is printed as yellow text.
function tests.test_warn_yellow()
    local config = {}
    local file = io.tmpfile()
    local reporter = Reporter(config, file)

    reporter:warn("a warning")

    assert.is_equal("\x1B[0m\x1B[33ma warning\x1B[0m\n", get_content(file))
end

-- Start collection reports the tests directory.
function tests.test_start_collection()
    local config = {verbose = true}
    local file = io.tmpfile()
    local reporter = Reporter(config, file)

    reporter:start_collection("tests/dir")

    assert.is_equal("Searching tests/dir\n", get_content(file))
end

-- Finish collection reports the tests collected for 1 test.
function tests.test_finish_collection_1_test()
    local config = {}
    local file = io.tmpfile()
    local reporter = Reporter(config, file)

    reporter:finish_collection(1)

    assert.is_equal("\x1B[0m\x1B[1mCollected 1 test\n\x1B[0m\n",
                    get_content(file))
end

-- Finish collection reports the tests collected for many tests.
function tests.test_finish_collection_many_tests()
    local config = {}
    local file = io.tmpfile()
    local reporter = Reporter(config, file)

    reporter:finish_collection(42)

    assert.is_equal("\x1B[0m\x1B[1mCollected 42 tests\n\x1B[0m\n",
                    get_content(file))
end

-- Start module reports the test file.
function tests.test_start_module()
    local config = {}
    local file = io.tmpfile()
    local reporter = Reporter(config, file)

    reporter:start_module("tests/test_something.lua")

    assert.is_equal("tests/test_something.lua ", get_content(file))
end

-- Finish module clear the module line.
function tests.test_finish_module()
    local config = {}
    local file = io.tmpfile()
    local reporter = Reporter(config, file)

    reporter:finish_module("tests/test_something.lua")

    assert.is_equal("\n", get_content(file))
end

-- Start test reports the test file and test name.
function tests.test_start_test()
    local config = {verbose = true}
    local file = io.tmpfile()
    local reporter = Reporter(config, file)

    reporter:start_test("tests/test_something.lua", "test_foo")

    assert.is_equal("tests/test_something.lua::test_foo ", get_content(file))
end

-- TODO: finish_test
-- TODO: show failure details
-- TODO: summarize

return tests
