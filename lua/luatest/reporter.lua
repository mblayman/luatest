local ansicolors = require "ansicolors"
local inspect = require "inspect"
local tablex = require "pl.tablex"

local Reporter = {}
Reporter.__index = Reporter

local function _init(_, config)
    local self = setmetatable({}, Reporter)
    self._config = config

    -- Times to track total execution time
    self._start = nil
    self._finish = nil

    -- Holds all the failure details for reporting at the end
    self._failures = {}
    -- Passed count (no other details needed)
    self._passed_count = 0
    return self
end
setmetatable(Reporter, {__call = _init})

-- Start recording execution time.
function Reporter.start(self) self._start = os.time() end

-- Finish recording execution time.
function Reporter.finish(self) self._finish = os.time() end

-- Show a warning message.
function Reporter.warn(_, message) print(ansicolors("%{yellow}" .. message)) end

--
-- Collection hooks
--

-- Report at the start of collection.
function Reporter.start_collection(self, tests_dir)
    if self._config.verbose then print("Searching " .. tests_dir) end
end

-- Report at the finish of collection.
function Reporter.finish_collection(_, total_tests)
    local tests_label = " tests\n"
    if total_tests == 1 then tests_label = " test\n" end
    print(ansicolors("%{bright}Collected " .. total_tests .. tests_label))
end

--
-- Execution hooks
--

-- Report at the start of a module's test execution.
function Reporter.start_module(self, relpath)
    -- In verbose mode, the relpath is included with every test,
    -- so this is not needed in that mode.
    if not self._config.verbose then io.write(relpath .. " ") end
end

-- Report at the finish of a module's test execution.
function Reporter.finish_module(self, _)
    if not self._config.verbose then io.write("\n") end
end

-- Report at the start of a test's execution.
function Reporter.start_test(self, relpath, test_name)
    if self._config.verbose then
        io.write(relpath .. "::" .. test_name .. " ")
    end
end

-- Report at the finish of a test's execution.
function Reporter.finish_test(self, relpath, test_name, status,
                              assertion_details)
    if self._config.verbose then
        if status then
            io.write(ansicolors("%{green}PASSED\n"))
        else
            io.write(ansicolors("%{red}FAILED\n"))
        end
    else
        if status then
            io.write(ansicolors("%{green}."))
        else
            io.write(ansicolors("%{red}F"))
        end
    end

    if status then
        self._passed_count = self._passed_count + 1
    else
        if not self._failures[relpath] then self._failures[relpath] = {} end
        self._failures[relpath][test_name] = assertion_details
    end
end

-- Show failure details.
function Reporter._show_failure_details(self)
    for relpath, test_names in tablex.sort(self._failures) do
        for test_name, assertion_details in tablex.sort(test_names) do
            print(ansicolors("%{bright red}" .. relpath .. "::" .. test_name ..
                                 "%{reset}\n\n" .. assertion_details .. "\n"))
        end
    end
end

-- Summarize the results.
function Reporter.summarize(self)
    if self._config.debug then print("Failures\n" .. inspect(self._failures)) end

    local failures_count = tablex.size(self._failures)
    if failures_count > 0 then self:_show_failure_details() end

    -- Summary line
    local delta_seconds = os.difftime(self._finish, self._start)
    if failures_count > 0 then
        print(ansicolors("%{bright red}" .. failures_count ..
                             " failed%{reset}, %{green}" .. self._passed_count ..
                             " passed %{red}in " .. delta_seconds .. "s"))
    else
        print(ansicolors("%{bright green}" .. self._passed_count ..
                             " passed %{reset}%{green}in " .. delta_seconds ..
                             "s"))
    end

    -- The status code to report at process exit
    local final_status = 0
    if failures_count > 0 then final_status = 1 end
    return final_status
end

return Reporter
