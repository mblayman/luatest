local luassert = require "luassert"

local tests = {}

-- This sample test is meant for checking a passing result.
function tests.test_passes() luassert.is_true(true) end

return tests
