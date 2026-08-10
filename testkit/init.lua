--[[
    TestKit — minimal Lua test framework for running Roblox Luau tests
    outside of Roblox Studio.

    Provides:
      - expect(value) → assertion builder (use :toBe(), :toEqual(), etc.)
      - testkit.loadModule(path) → loads a Lua module from filesystem
      - describe/it for test organization

    Usage:
      LUA_PATH="?.lua;testkit/?.lua;?/init.lua" lua5.1 tests/beatclock_test.lua
]]

local testkit = {}
local passed = 0
local failed = 0

-- ── Expect builder ──────────────────────────────────────

local function expect(actual)
    local mt = {}
    
    function mt:toBe(expected)
        if actual ~= expected then
            error(string.format("Expected %s, got %s", tostring(expected), tostring(actual)), 2)
        end
        return self
    end
    
    function mt:toEqual(expected)
        if type(actual) == "table" and type(expected) == "table" then
            local function deepEq(a, b)
                if type(a) ~= type(b) then return false end
                if type(a) ~= "table" then return a == b end
                for k, v in pairs(a) do if not deepEq(v, b[k]) then return false end end
                for k, v in pairs(b) do if not deepEq(v, a[k]) then return false end end
                return true
            end
            if not deepEq(actual, expected) then
                error("Expected tables to be equal", 2)
            end
        else
            if actual ~= expected then
                error(string.format("Expected %s, got %s", tostring(expected), tostring(actual)), 2)
            end
        end
        return self
    end
    
    function mt:toBeGreaterThan(expected)
        if not (actual > expected) then
            error(string.format("Expected %s > %s", tostring(actual), tostring(expected)), 2)
        end
        return self
    end
    
    function mt:toBeLessThan(expected)
        if not (actual < expected) then
            error(string.format("Expected %s < %s", tostring(actual), tostring(expected)), 2)
        end
        return self
    end
    
    function mt:toBeGreaterThanOrEqualTo(expected)
        if not (actual >= expected) then
            error(string.format("Expected %s >= %s", tostring(actual), tostring(expected)), 2)
        end
        return self
    end
    
    function mt:toBeLessThanOrEqualTo(expected)
        if not (actual <= expected) then
            error(string.format("Expected %s <= %s", tostring(actual), tostring(expected)), 2)
        end
        return self
    end
    
    function mt:toBeTrue()
        if actual ~= true then error(string.format("Expected true, got %s", tostring(actual)), 2) end
        return self
    end
    
    function mt:toBeFalse()
        if actual ~= false then error(string.format("Expected false, got %s", tostring(actual)), 2) end
        return self
    end
    
    function mt:toBeNil()
        if actual ~= nil then error(string.format("Expected nil, got %s", tostring(actual)), 2) end
        return self
    end
    
    function mt:toBeNear(expected, tolerance)
        if math.abs(actual - expected) > tolerance then
            error(string.format("Expected %s ± %s, got %s", tostring(expected), tostring(tolerance), tostring(actual)), 2)
        end
        return self
    end
    
    return mt
end

testkit.expect = expect

-- ── Module loading ──────────────────────────────────────

function testkit.loadModule(path)
    local file = io.open(path, "r")
    if not file then error("File not found: " .. path, 2) end
    local content = file:read("*a")
    file:close()
    
    -- Strip Luau type annotations for Lua 5.1 compatibility
    content = content:gsub("%s*:%s*%a+%??", "")       -- : type or : type?
    content = content:gsub("%s*->%s*%a+", "")           -- -> type
    content = content:gsub("(local%s+%w+)%s*:%s*%w+%s*=", "%1 =")  -- local x: type =
    content = content:gsub("[^\n]*export type[^\n]+\n", "")
    
    local fn, err = loadstring(content, path)
    if not fn then error("Failed to load module: " .. tostring(err), 2) end
    
    local env = setmetatable({}, {__index = _G})
    setfenv(fn, env)
    local ok, result = pcall(fn)
    if not ok then error("Module execution failed: " .. tostring(result), 2) end
    
    if result and type(result) == "table" then return result end
    return env.BeatClock or env
end

-- ── Test registration ───────────────────────────────────

function testkit.describe(name, fn)
    print("\n=== " .. name .. " ===")
    fn()
end

function testkit.it(name, fn)
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
        print("  ✓ " .. name)
    else
        failed = failed + 1
        print("  ✗ " .. name)
        print("    " .. tostring(err))
    end
end

testkit.test = testkit.it

-- ── Summary ─────────────────────────────────────────────

function testkit.summary()
    print(string.format("\n───────────────────────────────"))
    print(string.format("Passed: %d  Failed: %d  Total: %d", passed, failed, passed + failed))
    if failed > 0 then os.exit(1) end
end

-- ── Mock typeof for Luau compatibility ──────────────────

if not typeof then
    _G.typeof = function(v)
        local t = type(v)
        if t == "table" and v._robloxType then return v._robloxType end
        return t
    end
end

-- ── Expose globally ─────────────────────────────────────

_G.expect = expect
_G.describe = testkit.describe
_G.it = testkit.it
_G.test = testkit.test

return testkit
