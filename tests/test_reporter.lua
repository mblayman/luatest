local assert = require "luassert"
local stub = require "luassert.stub"

local Reporter = require "luatest.reporter"

local tests = {}

-- Get all the file content.
local function get_content(file)
    file:seek("set", 0)
    return file:read("a")
end

-- Reporter sets the start state.
function tests.test_start_timing()
    local reporter = Reporter()

    reporter:start_timing()

    assert.is_not_nil(reporter._start)
end

-- Reporter sets the finish state.
function tests.test_finish_timing()
    local reporter = Reporter()

    reporter:finish_timing()

    assert.is_not_nil(reporter._finish)
end

-- Print with no message is transformed to an empty string.
function tests.test_print_empty()
    local config = {}
    local file = io.tmpfile()
    local reporter = Reporter(config, file)

    reporter:print()

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

-- An error is printed as red text.
function tests.test_error_red()
    local config = {}
    local file = io.tmpfile()
    local reporter = Reporter(config, file)

    reporter:error("an error")

    assert.is_equal("\x1B[0m\x1B[31man error\x1B[0m\n", get_content(file))
end

-- A fatal error is printed as red text and exits.
function tests.test_fatal()
    local config = {}
    local file = io.tmpfile()
    local reporter = Reporter(config, file)
    stub(os, "exit")

    reporter:fatal("a fatal error")

    assert.is_equal("\x1B[0m\x1B[31ma fatal error\x1B[0m\n", get_content(file))
    assert.stub(os.exit).was_called_with(1)

    os.exit:revert()
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

-- Finish test with passing result.
function tests.test_finish_test_passing()
    local config = {}
    local file = io.tmpfile()
    local reporter = Reporter(config, file)

    reporter:finish_test("tests/test_something.lua", "test_foo", true, nil)

    assert.is_equal("\x1B[0m\x1B[32m.\x1B[0m", get_content(file))
    assert.is_equal(1, reporter._passed_count)
end

-- Finish test with passing result verbose.
function tests.test_finish_test_passing_verbose()
    local config = {verbose = true}
    local file = io.tmpfile()
    local reporter = Reporter(config, file)

    reporter:finish_test("tests/test_something.lua", "test_foo", true, nil)

    assert.is_equal("\x1B[0m\x1B[32mPASSED\n\x1B[0m", get_content(file))
end

-- Finish test with failing result.
function tests.test_finish_test_failing()
    local config = {}
    local file = io.tmpfile()
    local reporter = Reporter(config, file)

    reporter:finish_test("tests/test_something.lua", "test_foo", false,
                         "details")

    assert.is_equal("\x1B[0m\x1B[31mF\x1B[0m", get_content(file))
    assert.is_equal(0, reporter._passed_count)
    assert.is_same({["tests/test_something.lua"] = {test_foo = "details"}},
                   reporter._failures)
end

-- Finish test with failing result verbose.
function tests.test_finish_test_failing_verbose()
    local config = {verbose = true}
    local file = io.tmpfile()
    local reporter = Reporter(config, file)

    reporter:finish_test("tests/test_something.lua", "test_foo", false,
                         "details")

    assert.is_equal("\x1B[0m\x1B[31mFAILED\n\x1B[0m", get_content(file))
end

-- A failure stores any captured stdout content.
function tests.test_finish_test_stores_stdout()
    local config = {}
    local file = io.tmpfile()
    local reporter = Reporter(config, file)
    reporter._read_stdout = function() return "stdout content" end

    reporter:finish_test("tests/test_something.lua", "test_foo", false,
                         "details")

    assert.is_same({
        ["tests/test_something.lua"] = {test_foo = "stdout content"}
    }, reporter._captured_stdout)
end

-- A failure stores any captured stderr content.
function tests.test_finish_test_stores_stderr()
    local config = {}
    local file = io.tmpfile()
    local reporter = Reporter(config, file)
    reporter._read_stderr = function() return "stderr content" end

    reporter:finish_test("tests/test_something.lua", "test_foo", false,
                         "details")

    assert.is_same({
        ["tests/test_something.lua"] = {test_foo = "stderr content"}
    }, reporter._captured_stderr)
end

-- Summarize reports with no failures.
function tests.test_summarize_no_failures()
    local config = {}
    local file = io.tmpfile()
    -- local file = io.open('test-out.txt', 'w')
    local reporter = Reporter(config, file)
    reporter:start_timing()
    reporter:finish_timing()

    local final_status = reporter:summarize()

    assert.is_equal(
        "\x1B[0m\x1B[1m\x1B[32m0 passed \x1B[0m\x1B[32min 0.0s\x1B[0m\n",
        get_content(file))
    assert.is_equal(0, final_status)
end

-- Summarize reports with failure.
function tests.test_summarize_failure()
    local config = {}
    local file = io.tmpfile()
    local reporter = Reporter(config, file)
    reporter._failures = {["tests/test_something.lua"] = {test_foo = "details"}}
    reporter._captured_stdout = {
        ["tests/test_something.lua"] = {test_foo = "stdout content"}
    }
    reporter._captured_stderr = {
        ["tests/test_something.lua"] = {test_foo = "stderr content"}
    }
    reporter:start_timing()
    reporter:finish_timing()

    local final_status = reporter:summarize()

    local test_file =
        "\x1B[0m\x1B[1m\x1B[31mtests/test_something.lua::test_foo\x1B[0m\n\x1B[0m\n"
    local stdout = "> stdout:\nstdout content\n\n"
    local stderr = "> stderr:\nstderr content\n\n"
    local failure_details = "details\n\n"
    local summary =
        "\x1B[0m\x1B[1m\x1B[31m1 failed\x1B[0m, \x1B[32m0 passed \x1B[31min 0.0s\x1B[0m\n"
    assert.is_equal(test_file .. stdout .. stderr .. failure_details .. summary,
                    get_content(file))
    assert.is_equal(1, final_status)
end

-- Print output is captured to stdout.
-- Because the global replacement is fiddly, this test is measuring the *currently*
-- running reporter instead of an explicit reporter under test.
function tests.test_print_to_stdout_file()
    print('should not appear')
    -- The test does not bother to assert because the suite will fail
    -- if the --no-capture flag is used.
    -- A better version of this test would try to play nicely with the current
    -- stdout and stderr, set up capturing with the reporter under test,
    -- then restore at the end.
end

return tests
