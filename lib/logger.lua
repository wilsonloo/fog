local sformat = string.format

local M = {}

local mt = {}
mt.__index = mt

function mt:enable_debug()
    self.debug_enabled = true
end

function mt:disable_debug()
    self.debug_enabled = false
end

function mt:debug(msg, ...)
    if self.debug_enabled then
        print("[DEBUG] "..msg, ...)
    end
end

function mt:debugf(fmt, ...)
    if self.debug_enabled then
        print(sformat("[DEBUG] "..fmt, ...))
    end
end

function M.new()
    local obj = setmetatable({
        debug_enabled = true,
    }, mt)
    return obj
end

return M