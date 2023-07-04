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

## Configuration

luatest checks for configuration from two sources:

1. Command line flags
2. A configuration file named `luaproject.toml`

### Command line flags

See `luatest -h` for the full list of all available flags.

`--cov` - Use this flag to measure code coverage for a given directory.

### Configuration file

The `luaproject.toml` example is shown below with inline comments
to explain the supported configuration.
Each configuration value shows the default configuration.

```toml
# All configuration options are under the tool.luatest table.
[tool.luatest]

# The directory to search when looking for tests.
tests_dir = "tests"
```
