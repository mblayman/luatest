local argparse = require "argparse"
local inspect = require "inspect"

-- Build the interface parser.
local function build_parser()
    local parser = argparse("luatest", "A Lua test runner")
    parser:add_help(true)
    parser:flag("-v --verbose", "Show verbose output")
    return parser
end

-- The initial entry point of the tool
local function main(args)
    local parser = build_parser()
    local config = parser:parse(args)
    print(inspect(config))
end

return {main = main}
