package.cpath = package.cpath .. ";./build/?.so"

local PrintR = require "lib.print_r"
local ImgExporter = require "3rd/imgexporter/exporter"

local mfloor = math.floor
local mmax = math.max
local mmin = math.min
local tinsert = table.insert

local a = {x=10, y=60, w=10, h=10}
local b = {x=20, y=10, w=10, h=70}
local c = {x=30, y=60, w=10, h=10}
local d = {x=30, y=20, w=10, h=30}
local e = {x=40, y=30, w=10, h=10}
local i = {x=30, y=90, w=20, h=10}
local j = {x=60, y=120, w=20, h=10}

local test = {x=10, y=10, w=10, h=10}
local map = {a, b, c, d, e, i, j}

local WIDTH = 200
local HEIGH = 200

-- 每个节点最多容纳多少个矩形
local NODE_CAPACITY = 2

local LU = "lu"
local LD = "ld"
local RU = "ru"
local RD = "rd"
local REGION_IDX_LIST = { LU, LD, RU, RD}

local mt = {}
mt.__index = mt

local function create_region(x, y, w, h)
    local node = {
        x = x,
        y = y,
        w = w,
        h = h,

        -- 如果没有达到上限 NODE_CAPACITY, 塞入list， 否则才开始切割生成children
        children = nil,
        list = nil,
    }
    return setmetatable(node, mt)
end

function mt:fetch_region(region_idx, x, y, w, h)
    print("fetch_region:", region_idx, x, y, w, h)
    if not(self.children) then
        self.children = {}
    end

    local r = self.children[region_idx]
    if not(r) then
        r = create_region(x, y, w, h)
        self.children[region_idx] = r
    end
    return r
end

function mt:_insert_region(x, y, w, h)
    if self.children then
        for _, child in pairs(self.children) do
            child:add(x, y, w, h)
        end
        return
    end

    if not(self.list) then
        self.list = {}
    end

    local elem = {
        x = x,
        y = y,
        w = w,
        h = h,
    }
    tinsert(self.list, elem)
    if #self.list > NODE_CAPACITY then
        -- todo partition

    end
end

function mt:add(x, y, w, h)
    assert(x >= 0, x)
    assert(y >= 0, y)
    assert(w > 0, w)
    assert(h > 0, h)

    local nw2 = mfloor(self.w/2)
    local nh2 = mfloor(self.h/2)

    local nx = self.x + self.w
    local ny = self.y + self.h

    -- 先添加、再融合、最后再分裂
    local mid_x = self.x + nw2
    local mid_y = self.y + nh2

    print("add:", x, y, w, h, "mid:", mid_x, mid_y)
    if x + w >= mid_x and x + w <= nx then
        if y + h >= mid_y and y + h <= ny then
            -- 右上角
            local region = self:fetch_region(RU, mid_x, mid_y, nw2, nh2)
            local tempx = mmax(x, mid_x)
            local tempy = mmax(y, mid_y)
            local tempw = x+w-tempx
            local temph = y+h-tempy
            region:_insert_region(tempx, tempy, tempw, temph)
        end

        if y >= self.y and y <= mid_y then
            -- 右下角
            local region = self:fetch_region(RD, mid_x, self.y, nx, mid_y)
            local tempx = mmax(x, mid_x)
            local tempy = y
            local tempw = x+w-tempx
            local temph = mmin(tempy+h, mid_y)-tempy
            region:_insert_region(tempx, tempy, tempw, temph)
        end    
    end

    if x >= self.x and x <= mid_x then
        if y >= mid_y and y <= ny then
            -- 左上角
            local region = self:fetch_region(LU, self.x, mid_y, mid_x, self.y)
            local tempx = x
            local tempy = mmax(y, mid_y)
            local tempw = mmin(tempx+w, mid_x)-tempx
            local temph = y+h-tempy
            region:_insert_region(tempx, tempy, tempw, temph)
        end

        if y >= self.y and y <= mid_y then
            local region = self:fetch_region(LD, self.x, self.y, mid_x, mid_y)
            local tempx = x
            local tempy = y
            local tempw = mmin(tempx+w, mid_x) - tempx
            local temph = mmin(y+h, mid_y) - tempy
            region:_insert_region(tempx, tempy, tempw, temph)
        end
    end
end

local function export(tree, filename, title)
    local width = tree.w
    local heigh = tree.h
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
            for _, rname in ipairs(REGION_IDX_LIST) do
                if node.children[rname] then
                    do_export(node.children[rname], exp)
                end
            end
        end
    end

    local exp = ImgExporter.new(width, heigh, title)
    exp:rect(1, 1, width-2, heigh-2)
    do_export(tree, exp)
    exp:write("./output/"..filename) 
end

local tree = create_region(0, 0, WIDTH, HEIGH)

for k, v in ipairs(map) do
    tree:add(v.x, v.y, v.w, v.h)
end

PrintR.print_r(tree)
export(tree, "map.json", "title")
print("Done.")
