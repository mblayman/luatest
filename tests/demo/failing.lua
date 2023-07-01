local luassert = require "luassert"

local tests = {}

-- This sample test is meant for checking a failing result.
function tests.test_fails() luassert.is_true(false) end

return tests
