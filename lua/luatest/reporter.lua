local ansicolors = require "ansicolors"
local inspect = require "inspect"
local stringio = require "pl.stringio"
local tablex = require "pl.tablex"

local Reporter = {}
Reporter.__index = Reporter

local function _init(_, config, file)
    local self = setmetatable({}, Reporter)
    self._config = config

    -- Default to stdout, but use a provided file handle for testing purposes.
    if file then
        self._file = file
    else
        self._file = io.stdout
    end

    -- Times to track total execution time
    self._start = nil
    self._finish = nil

    -- Holds all the failure details for reporting at the end
    self._failures = {}
    -- Passed count (no other details needed)
    self._passed_count = 0

    -- Storage for any captured content to show along with test failure details.
    self._stdout_stringio = stringio.create()
    self._stderr_stringio = stringio.create()
    self._captured_stdout = {}
    self._captured_stderr = {}

    return self
end
setmetatable(Reporter, {__call = _init})

-- Should the reporter handle stdout/stderr capturing?
-- Using this because double negatives in code are gross.
function Reporter._should_capture(self) return not self._config.no_capture end

-- Clear the stdout stringio buffer.
-- This method assumes that it will only be called in a context
-- where capturing is in effect.
function Reporter._clear_stdout(self)
    -- Careful! This is taking advantage of a stringio implementation detail.
    self._stdout_stringio.tbl = {}
end

-- Clear the stderr stringio buffer.
-- This method assumes that it will only be called in a context
-- where capturing is in effect.
function Reporter._clear_stderr(self)
    -- Careful! This is taking advantage of a stringio implementation detail.
    self._stderr_stringio.tbl = {}
end

-- Read the stdout stringio buffer.
-- This method assumes that it will only be called in a context
-- where capturing is in effect.
function Reporter._read_stdout(self) return self._stdout_stringio:value() end

-- Read the stderr stringio buffer.
-- This method assumes that it will only be called in a context
-- where capturing is in effect.
function Reporter._read_stderr(self) return self._stderr_stringio:value() end

-- Capture stdout and stderr.
-- This method intercepts the system's default output abilities
-- to keep reporting clean and to show stdout and stderr later
-- with the other diagnostic information when failures occur.
function Reporter.capture_standard_files(self)
    if self:_should_capture() then
        io.stdout = self._stdout_stringio
        io.stderr = self._stderr_stringio

        -- print seems to operate separately from io.stdout|stderr.
        -- Replace the global print function with a function that writes
        -- to the stringio buffer.
        _G.print = function(...)
            for _, value in ipairs({...}) do io.stdout:write(value) end
            -- Simulate print behavior.
            io.stdout:write("\n")
        end
    end
end

-- Start recording execution time.
function Reporter.start_timing(self) self._start = os.time() end

-- Finish recording execution time.
function Reporter.finish_timing(self) self._finish = os.time() end

-- Print to the file.
-- This convenience method is used to behave like print on the reporter's file handle.
function Reporter.print(self, message)
    if message == nil then message = "" end
    self._file:write(message .. "\n")
end

-- Write to the file.
-- This convenience method is used to behave like write on the reporter's file handle.
function Reporter._write(self, message) self._file:write(message) end

-- Show a warning message.
function Reporter.warn(self, message)
    self:print(ansicolors("%{yellow}" .. message))
end

-- Show an error message.
function Reporter.error(self, message)
    self:print(ansicolors("%{red}" .. message))
end

-- Show a fatal error message and exit.
function Reporter.fatal(self, message)
    self:error(message)
    os.exit(1)
end

--
-- Collection hooks
--

-- Report at the start of collection.
function Reporter.start_collection(self, tests_dir)
    if self._config.verbose then self:print("Searching " .. tests_dir) end
end

-- Report at the finish of collection.
function Reporter.finish_collection(self, total_tests)
    if not self._config.quiet then
        local tests_label = " tests\n"
        if total_tests == 1 then tests_label = " test\n" end
        self:print(ansicolors("%{bright}Collected " .. total_tests ..
                                  tests_label))
    end
end

--
-- Execution hooks
--

-- Report at the start of a module's test execution.
function Reporter.start_module(self, relpath)
    -- In verbose mode, the relpath is included with every test,
    -- so this is not needed in that mode.
    if not self._config.verbose and not self._config.quiet then
        self:_write(relpath .. " ")
    end
end

-- Report at the finish of a module's test execution.
function Reporter.finish_module(self, _)
    if not self._config.verbose and not self._config.quiet then
        self:_write("\n")
    end
end

-- Report at the start of a test's execution.
function Reporter.start_test(self, relpath, test_name)
    if self:_should_capture() then
        self:_clear_stdout()
        self:_clear_stderr()
    end

    if self._config.verbose then
        self:_write(relpath .. "::" .. test_name .. " ")
    end
end

-- Report at the finish of a test's execution.
function Reporter.finish_test(self, relpath, test_name, status,
                              assertion_details)
    if self._config.verbose then
        if status then
            self:_write(ansicolors("%{green}PASSED\n"))
        else
            self:_write(ansicolors("%{red}FAILED\n"))
        end
    else
        if status then
            self:_write(ansicolors("%{green}."))
        else
            self:_write(ansicolors("%{red}F"))
        end
    end

    if status then
        self._passed_count = self._passed_count + 1
    else
        if not self._failures[relpath] then self._failures[relpath] = {} end
        self._failures[relpath][test_name] = assertion_details

        if self:_should_capture() then
            local captured_stdout = self:_read_stdout()
            if captured_stdout ~= "" then
                if not self._captured_stdout[relpath] then
                    self._captured_stdout[relpath] = {}
                end
                self._captured_stdout[relpath][test_name] = captured_stdout
            end

            local captured_stderr = self:_read_stderr()
            if captured_stderr ~= "" then
                if not self._captured_stderr[relpath] then
                    self._captured_stderr[relpath] = {}
                end
                self._captured_stderr[relpath][test_name] = captured_stderr
            end
        end
    end
end

-- Report at the end of the execution phase.
function Reporter.finish_execution(self) self:print() end

-- Show failure details.
function Reporter._show_failure_details(self)
    for relpath, test_names in tablex.sort(self._failures) do
        for test_name, assertion_details in tablex.sort(test_names) do
            self:print(ansicolors("%{bright red}" .. relpath .. "::" ..
                                      test_name .. "%{reset}\n"))

            if self:_should_capture() then
                if self._captured_stdout[relpath] and
                    self._captured_stdout[relpath][test_name] then
                    self:print("> stdout:")
                    self:print(self._captured_stdout[relpath][test_name])
                    self:print()
                end
                if self._captured_stderr[relpath] and
                    self._captured_stderr[relpath][test_name] then
                    self:print("> stderr:")
                    self:print(self._captured_stderr[relpath][test_name])
                    self:print()
                end
            end

            self:print(assertion_details .. "\n")
        end
    end
end

-- Summarize the results.
function Reporter.summarize(self)
    if self._config.debug then
        -- luacov: disable
        self:print("Failures\n" .. inspect(self._failures))
        self:print("Captured stdout\n" .. inspect(self._captured_stdout))
        self:print("Captured stderr\n" .. inspect(self._captured_stderr))
        -- luacov: enable
    end

    local failures_count = tablex.size(self._failures)
    if failures_count > 0 then self:_show_failure_details() end

    -- Summary line
    local delta_seconds = os.difftime(self._finish, self._start)
    if failures_count > 0 then
        self:print(ansicolors("%{bright red}" .. failures_count ..
                                  " failed%{reset}, %{green}" ..
                                  self._passed_count .. " passed %{red}in " ..
                                  delta_seconds .. "s"))
    else
        self:print(ansicolors("%{bright green}" .. self._passed_count ..
                                  " passed %{reset}%{green}in " .. delta_seconds ..
                                  "s"))
    end

    -- The status code to report at process exit
    local final_status = 0
    if failures_count > 0 then final_status = 1 end
    return final_status
end

return Reporter
