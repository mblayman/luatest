local assert = require "luassert"

local main = require "luatest.main"

local tests = {}

-- The package path is updated with the location of source files.
function tests.test_updates_package_path()
    local config = {}
    local package_module = {path = "some/?.lua;"}

    main.update_package_path(config, package_module)

    assert.is_equal(
        "lua/?.lua;lua/?/init.lua;src/?.lua;src/?/init.lua;some/?.lua;",
        package_module.path)
end

-- The package path is updated with a different coverage directory.
function tests.test_updates_package_path_for_coverage()
    local config = {cov = "different"}
    local package_module = {path = "some/?.lua;"}

    main.update_package_path(config, package_module)

    assert.is_equal("different/?.lua;different/?/init.lua;" ..
                        "lua/?.lua;lua/?/init.lua;src/?.lua;src/?/init.lua;some/?.lua;",
                    package_module.path)
end

-- The package path is not updated with a same coverage directory.
function tests.test_updates_package_path_for_same_coverage()
    local config = {cov = "lua"}
    local package_module = {path = "some/?.lua;"}

    main.update_package_path(config, package_module)

    assert.is_equal(
        "lua/?.lua;lua/?/init.lua;src/?.lua;src/?/init.lua;some/?.lua;",
        package_module.path)
end

return tests
