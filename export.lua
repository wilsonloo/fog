local ImgExporter = require "3rd/imgexporter/exporter"
local Def = require "def"

return function (tree, filename, title)
    local width = tree.w
    local heigh = tree.h
    local function export_region(r, exp)
        local x = r.x
        local y = heigh - (r.y + r.h)
        local w = r.w
        local h = r.h
        exp:rect(Def.COLOR_RED, x, y, w, h)
    end
    local function do_export(node, exp)
        if node.list then
            for _, e in ipairs(node.list) do
                local x = e.x
                local y = heigh - (e.y + e.h)
                local w = e.w
                local h = e.h
                exp:rect(x, y, w, h)
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
    exp:write("./output/"..filename) 
end
