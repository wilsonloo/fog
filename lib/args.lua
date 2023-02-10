local M = {}

function M.parse(...)
    local map = {}
    for _, v in ipairs{...} do
        map[v] = true
    end
    return map
end

return M