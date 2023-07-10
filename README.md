# luatest

[![codecov](https://codecov.io/gh/mblayman/luatest/branch/main/graph/badge.svg?token=DBYXXLQXKB)](https://codecov.io/gh/mblayman/luatest)

A Lua test runner

Lua has a handful of test runners like Busted.
These tools are good, but the ones that I've encountered use a BDD-style.
My preferences have moved away from BDD-style runners
(for reasons that I may document elsewhere at a later time).

The goal of this test runner is provide a fairly opinionated test runner
in the style of pytest for Python.
The feature set will be highly constrained initially
to satisfy my use cases and keep maintenance light.

Assertion functionality is delegated to `luassert`.

```bash
$ luatest
Collected 24 tests

tests/test_collection.lua .....
tests/test_coverage.lua .
tests/test_executor.lua ..
tests/test_reporter.lua ................

24 passed in 0.0s
```

## Features

1. Discover, collect, and execute test code.
2. Measure code coverage via luacov.

### Test filtering

You can execute a subset of your test suite
by using positional arguments to luatest.
These arguments can be in one of three forms,
and these forms can be used in combination.
The three forms are:

1. A directory within the test suite will collect tests within that directory.
2. A test file within the test suite will collect all tests within that file.
3. A test file with a test name, separated by `::`, will collect an individual test.

Here's an example invocation (using verbose output)
from luatest's own test suite
to illustrate.

```bash
$ luatest --verbose \
    tests/test_executor.lua \
    tests/test_collection.lua::test_collects_test_modules
Searching /Users/matt/projects/luatest/tests
Collected 3 tests

tests/test_collection.lua::test_collects_test_modules PASSED
tests/test_executor.lua::test_fail PASSED
tests/test_executor.lua::test_pass PASSED

3 passed in 0.0s
```

### stdout/stderr capturing

By default, luatest will attempt to capture any usage of stdout and stderr
via `io.stdout`, `io.stderr`, or `print`.
Anything captured during test exeuction will be stored upon failures
and displayed with assertion detail diagnostics.

To disable this behavior, use the `--no-capture` flag.

## Configuration

luatest checks for configuration from two sources:

1. Command line flags
2. A configuration file named `luaproject.toml`

### Command line flags

See `luatest -h` for the full list of all available flags.

* `--cov` - Use this flag to measure code coverage for a given directory.
* `--no-capture` - Use this flag to disable stdout/stderr capturing.

### Configuration file

The `luaproject.toml` example is shown below with inline comments
to explain the supported configuration.
Each configuration value shows the default configuration.

```toml
# All configuration options are under the tool.luatest table.
[tool.luatest]

# The directory to search when looking for tests.
tests_dir = "tests"

# The pattern that will be used to discover test modules.
# This default pattern will match a file that looks like "test_<something>.lua".
test_file_pattern = "test_.+%.lua"
```
