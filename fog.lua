package.cpath = package.cpath .. ";./build/?.so"
local PrintR = require "lib.print_r"

local mfloor = math.floor
local mmax = math.max
local mmin = math.min
local tinsert = table.insert
local tremove = table.remove

local a = {x=100, y=600, w=100, h=100}
local b = {x=200, y=100, w=100, h=700}
local c = {x=300, y=600, w=100, h=100}
local d = {x=300, y=200, w=100, h=300}
local e = {x=400, y=300, w=100, h=100}
local i = {x=300, y=900, w=200, h=100}
local j = {x=600, y=1200, w=200, h=100}

local map = {a, b, c, d, e, i, j}

local WIDTH = 2000
local HEIGH = 2000

-- 每个节点最多容纳多少个矩形
local NODE_CAPACITY = 2

local LU = "lu"
local LD = "ld"
local RU = "ru"
local RD = "rd"
local REGION_IDX_LIST = { LU, LD, RU, RD}

local to_merge = false

local img_idx = 1
local function do_export(tree)
    local export = require "export"
    export(tree, img_idx..".json", "title")
    img_idx = img_idx + 1
end

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

local tree = create_region(0, 0, WIDTH, HEIGH)

function mt:_fetch_region(region_idx, x, y, w, h)
    print("_fetch_region:", region_idx, x, y, w, h)
    if not(self.children) then
        self.children = {}
    end

    local r = self.children[region_idx]
    if not(r) then
        r = create_region(x, y, w, h)
        r.region_idx = region_idx
        self.children[region_idx] = r
    end
    return r
end

function mt:fetch_region(region_idx)
    local nw2 = mfloor(self.w/2)
    local nh2 = mfloor(self.h/2)

    local nx = self.x + self.w
    local ny = self.y + self.h

    local mid_x = self.x + nw2
    local mid_y = self.y + nh2

    if region_idx == RU then
        return self:_fetch_region(RU, mid_x, mid_y, nw2, nh2)
    elseif region_idx == RD then
        return self:_fetch_region(RD, mid_x, self.y, nw2, nh2)
    elseif region_idx == LU then
        return self:_fetch_region(LU, self.x, mid_y, nw2, nh2)
    elseif region_idx == LD then
        return self:_fetch_region(LD, self.x, self.y, nw2, nh2)
    else
        assert(false, region_idx)    
    end
end

function mt:split_region()
    print("spliting region:", self.x, self.y, self.w, self.h)
    local nw2 = mfloor(self.w/2)
    local nh2 = mfloor(self.h/2)

    local nx = self.x + self.w
    local ny = self.y + self.h

    local mid_x = self.x + nw2
    local mid_y = self.y + nh2

    assert(not self.children, "invalid children")
    self:fetch_region(RU)
    self:fetch_region(RD)
    self:fetch_region(LU)
    self:fetch_region(LD)

    assert(self.list, "missing list")
    for _, elem in ipairs(self.list) do
        print("re-add after split:", elem.x, elem.y, elem.w, elem.h)
        self:add(elem.x, elem.y, elem.w, elem.h)
    end
    self.list = nil
    do_export(tree)
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

    assert(h > 0)
    local elem = {
        x = x,
        y = y,
        w = w,
        h = h,
    }
    self:try_merge(elem)
    tinsert(self.list, elem)
    if #self.list > NODE_CAPACITY then
        self:split_region()
    end
end

function mt:try_merge(new_rect)
    if not(to_merge) then
        return
    end

    local function merge(e)
        if new_rect.h == e.h then
            if new_rect.x == e.x + e.w then
                -- new_rect 在 e的右边
                return {x = e.x, y = e.y, w = e.w + new_rect.w, h = e.h}
            elseif new_rect.x + new_rect.w == e.x then
                -- new_rect 在 e的左边
                return {x = new_rect.x, y = e.y, w = new_rect.w + e.x, h = e.h}
            end
        end
        if new_rect.w == e.w then
            if new_rect.y + new_rect.h == e.y then
                -- new_rect 在e的下方
                return {x = new_rect.x, y = new_rect.y, w = e.w, h = new_rect.h+e.h}
            elseif new_rect.y == e.y + e.h then
                -- new_rect 在e的上方
                return {x = e.x, y = e.y, w = e.w, h = e.h + new_rect.h}
            end
        end
    end

    for k, e in ipairs(self.list) do
        local merged_rect = merge(e)
        if merged_rect then
            tremove(self.list, k)
            new_rect.x = merged_rect.x
            new_rect.y = merged_rect.y
            new_rect.w = merged_rect.w
            new_rect.h = merged_rect.h
            self:try_merge(new_rect)
            return
        end
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

    print("add:", x, y, w, h, "self:", self.region_idx, self.x, self.y, self.w, self.h)
    if x + w >= mid_x and x + w <= nx then
        if y + h >= mid_y and y + h <= ny then
            -- 右上角
            local region = self:fetch_region(RU)
            local tempx = mmax(x, mid_x)
            local tempy = mmax(y, mid_y)
            local tempw = x+w-tempx
            local temph = y+h-tempy
            region:_insert_region(tempx, tempy, tempw, temph)
        end

        if y >= self.y and y <= mid_y then
            -- 右下角
            local region = self:fetch_region(RD)
            local tempx = mmax(x, mid_x)
            local tempy = y
            local tempw = x+w-tempx
            local temph = mmin(tempy+h, mid_y)-tempy
            region:_insert_region(tempx, tempy, tempw, temph)
        end    
    end

    if x >= self.x and x <= mid_x then
        if y + h >= mid_y and y + h <= ny then
            -- 左上角
            local region = self:fetch_region(LU)
            local tempx = x
            local tempy = mmax(y, mid_y)
            local tempw = mmin(tempx+w, mid_x)-tempx
            local temph = y+h-tempy
            if temph > 0 then
                region:_insert_region(tempx, tempy, tempw, temph)
            end
        end

        -- 左下角
        if y >= self.y and y <= mid_y then
            local region = self:fetch_region(LD)
            local tempx = x
            local tempy = y
            local tempw = mmin(tempx+w, mid_x) - tempx
            local temph = mmin(y+h, mid_y) - tempy
            print("insert LD:", tempx, tempy, tempw, temph)
            region:_insert_region(tempx, tempy, tempw, temph)
        end
    end
end


for k, v in ipairs(map) do
    tree:add(v.x, v.y, v.w, v.h)
    do_export(tree)
end

to_merge = true

for k, v in ipairs{
    {x=1900, y=1900, w=100, h=100}, -- 添加到空白区域
    {x=1900, y=1800, w=100, h=100}, -- 添加到已有一个元素的区域，可以合并
    {x=600, y=1300, w=100, h=100},  -- 添加到已有一个元素的区域，不可合并
    {x=700, y=1300, w=100, h=100},  -- 添加到已有两个元素的区域，可以连锁合并
} do
    tree:add(v.x, v.y, v.w, v.h)
    do_export(tree)
end

PrintR.print_r(tree)
print("Done.")
