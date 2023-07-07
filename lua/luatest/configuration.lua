local path = require "pl.path"
local toml = require "toml"

-- Load any options from the configuration file (if it exists).
local function load_config_file(config)
    -- Set any defaults before attempting to load a config file.
    config.tests_dir = "tests"
    config.test_file_pattern = "test_.+%.lua"

    local config_path = path.join(path.currentdir(), "luaproject.toml")
    if path.exists(config_path) then
        local config_file = io.open(config_path)
        local content = ""
        if config_file ~= nil then content = config_file:read("a") end
        local parsed = toml.parse(content)
        if parsed.tool and parsed.tool.luatest then
            if parsed.tool.luatest.tests_dir then
                config.tests_dir = parsed.tool.luatest.tests_dir
            end
        end
    end
end

return {load_config_file = load_config_file}
