local assert = require "luassert"
local spy = require "luassert.spy"

local collection = require "luatest.collection"

local tests = {}

-- Collection provides a set of test modules and associated meta data.
function tests.test_collects_test_modules()
    local something_test = require "tests.demo.something_test"
    local other_test = require "tests.demo.other_test"
    local another_test = require "tests.demo.subdir.another_test"
    local config = {
        tests = {},
        tests_dir = "tests/demo",
        test_file_pattern = ".+_test%.lua"
    }
    local reporter = {}
    spy.on(reporter, "start_collection")
    spy.on(reporter, "finish_collection")

    local test_modules = collection.collect(config, reporter)

    assert.is_same({
        meta = {total_tests = 3},
        ["tests/demo/something_test.lua"] = {
            module = {test_foo = something_test.test_foo},
            tests = {"test_foo"}
        },
        ["tests/demo/other_test.lua"] = {
            module = {test_foo = other_test.test_foo},
            tests = {"test_foo"}
        },
        ["tests/demo/subdir/another_test.lua"] = {
            module = {test_bar = another_test.test_bar},
            tests = {"test_bar"}
        }
    }, test_modules)
end

-- Collection can filter specific files and directories from users.
function tests.test_collects_specific_user_tests()
    local something_test = require "tests.demo.something_test"
    local another_test = require "tests.demo.subdir.another_test"
    local config = {
        tests = {"tests/demo/subdir", "tests/demo/something_test.lua::test_foo"},
        tests_dir = "tests/demo",
        test_file_pattern = ".+_test%.lua"
    }
    local reporter = {}
    spy.on(reporter, "start_collection")
    spy.on(reporter, "finish_collection")

    local test_modules = collection.collect(config, reporter)

    assert.is_same({
        meta = {total_tests = 2},
        ["tests/demo/something_test.lua"] = {
            module = {test_foo = something_test.test_foo},
            tests = {"test_foo"}
        },
        ["tests/demo/subdir/another_test.lua"] = {
            module = {test_bar = another_test.test_bar},
            tests = {"test_bar"}
        }
    }, test_modules)
end

-- A module that has no test matching the listed test reports an error.
function tests.test_module_does_not_have_test()
    local relpath = "tests/demo/something_test.lua"
    local test_module = require "tests.demo.something_test"
    local test_modules = {}
    local reporter = {}
    spy.on(reporter, "error")
    spy.on(reporter, "fatal")
    spy.on(reporter, "warn") -- Because `report_errors` will fall through

    collection.process_module(relpath, test_module, {
        collect_all = false,
        tests = {["test_does_not_exist"] = true}
    }, test_modules, reporter)

    assert.spy(reporter.error).was_called_with(reporter,
                                               "tests/demo/something_test.lua has no test function named test_does_not_exist")
end

-- A module that doesn't look like a table of functions triggers a warning.
function tests.test_non_module()
    local relpath = "tests/demo/not_a_module.lua"
    local test_module = require "tests.demo.not_a_module"
    local test_modules = {}
    local reporter = {}
    spy.on(reporter, "warn")

    local test_count = collection.process_module(relpath, test_module,
                                                 {collect_all = true},
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
    local test_module = require "tests.demo.empty"
    local test_modules = {}
    local reporter = {}
    spy.on(reporter, "warn")

    local test_count = collection.process_module(relpath, test_module,
                                                 {collect_all = true},
                                                 test_modules, reporter)

    assert.spy(reporter.warn).was_called_with(reporter,
                                              "No tests found in tests/demo/empty.lua")
    assert.is_same(test_modules, {})
    assert.is_equal(test_count, 0)
end

-- Reports errors warns and fatally exits collection.
function tests.test_reports_errors()
    local errors = {"Houston, we have a problem."}
    local reporter = {}
    spy.on(reporter, "error")
    spy.on(reporter, "fatal")

    local test_count = collection.report_errors(errors, reporter)

    assert.spy(reporter.error).was_called_with(reporter,
                                               "Houston, we have a problem.")
    assert.spy(reporter.fatal).was_called_with(reporter, "Collection failed.")
end

-- A test file outside of the tests directory is an error.
function tests.test_file_in_tests_dir()
    local config = {
        tests_dir = "elsewhere",
        tests = {"not/in/tests/dir/test_something.lua"}
    }
    local reporter = {}
    spy.on(reporter, "error")
    spy.on(reporter, "fatal")

    collection.check_tests_in_tests_dir(config, reporter)

    local expected =
        "not/in/tests/dir/test_something.lua is not in the tests directory."
    assert.spy(reporter.error).was_called_with(reporter, expected)

end

-- A test file matches the test pattern.
function tests.test_file_matches_test_pattern()
    local config = {test_file_pattern = "test_.+%.lua"}
    local files = {["does/not/match.lua"] = true}
    local reporter = {}
    spy.on(reporter, "error")
    spy.on(reporter, "fatal")

    collection.check_files_are_tests(config, reporter, files)

    local expected = "does/not/match.lua does not match the test file pattern."
    assert.spy(reporter.error).was_called_with(reporter, expected)
end

-- A directory with a test filter is a failure.
function tests.test_directory_with_test_filter()
    local config = {tests_dir = "tests", tests = {"tests/demo::test_wont_work"}}
    local reporter = {}
    spy.on(reporter, "error")
    spy.on(reporter, "fatal")

    collection.clean_test(config, reporter)

    local expected =
        "Test name filtering does not apply to directories: tests/demo::test_wont_work"
    assert.spy(reporter.error).was_called_with(reporter, expected)
end

-- A file with no filter collects alls tests.
function tests.test_cleaned_file_whole_module()
    local config = {
        tests = {"tests/demo/something_test.lua"},
        tests_dir = "tests/demo",
        test_file_pattern = ".+_test%.lua"
    }
    local reporter = {}
    spy.on(reporter, "error")
    spy.on(reporter, "fatal")

    local tests_map = collection.clean_test(config, reporter)

    assert.is_true(tests_map.files["tests/demo/something_test.lua"].collect_all)
end

-- An invalid user provided file is an error.
function tests.test_invalid_user_file()
    local config = {
        tests = {"tests/demo/not_gonna_be_there.lua"},
        tests_dir = "tests/demo",
        test_file_pattern = ".+_test%.lua"
    }
    local reporter = {}
    spy.on(reporter, "error")
    spy.on(reporter, "fatal")

    collection.clean_test(config, reporter)

    local expected =
        "tests/demo/not_gonna_be_there.lua is an invalid test path."
    assert.spy(reporter.error).was_called_with(reporter, expected)
end

-- An invalid tests directory is an error.
function tests.test_invalid_tests_dir()
    local tests_dir = "/not/real"
    local reporter = {}
    spy.on(reporter, "error")
    spy.on(reporter, "fatal")

    collection.validate_tests_dir(tests_dir, reporter)

    local expected = "/not/real is not a valid directory."
    assert.spy(reporter.error).was_called_with(reporter, expected)
end

return tests
