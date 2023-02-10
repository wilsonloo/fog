local ImgExporter = require "3rd/imgexporter/exporter"
local Def = require "def"

local img_idx = 1

local M = {}

function M.export(tree, title)
    local width = tree.w
    local heigh = tree.h
    local function export_region(r, exp)
        local x = r.x
        local y = heigh - (r.y + r.h)
        local w = r.w
        local h = r.h
        if r.full then
            exp:rect_color(Def.COLOR_GREEN, x, y, w, h, r.id)
        else
            exp:rect_color(Def.COLOR_RED, x, y, w, h, r.id)
        end
    end
    local function do_export(node, exp)
        if node.list then
            for _, e in ipairs(node.list) do
                local x = e.x
                local y = heigh - (e.y + e.h)
                local w = e.w
                local h = e.h
                exp:rect(x, y, w, h, e.id)
            end
        end

        if node.children then
            for _, child in pairs(node.children) do
                export_region(child, exp)
                do_export(child, exp)
            end
        end
    end

    local exp = ImgExporter.new(width, heigh, title)
    exp:rect(1, 1, width-2, heigh-2)
    do_export(tree, exp)
    return exp
end

function M.dump_tree(tree, tag)
    tag = tag or ""
    local root = nil
    local v = tree
    while v ~= nil do
        if v.is_root then
            root = v
            break
        end
        v = v.parent
    end

    local exp = M.export(tree, "title")
    exp:write("./output/"..tag..img_idx..".json")
    img_idx = img_idx + 1
end

function M.dump_exp(exp, tag)
    tag = tag or ""
    exp:write("./output/"..tag..img_idx..".json")
    img_idx = img_idx + 1
end

return M