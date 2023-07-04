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

# Features

1. Discover, collect, and execute test code.
