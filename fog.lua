package.cpath = package.cpath .. ";./build/?.so"
local PrintR = require "lib.print_r"
local Logger = require "lib.logger"
local Def = require "def"
local RU, RD, LU, LD = Def.RU, Def.RD, Def.LU, Def.LD

local mfloor = math.floor
local mmax = math.max
local mmin = math.min
local tinsert = table.insert
local tremove = table.remove

local a = {id='a', x=100, y=600, w=100, h=100}
local b = {id='b', x=200, y=100, w=100, h=700}
local c = {id='c', x=300, y=600, w=100, h=100}
local d = {id='d', x=300, y=200, w=100, h=300}
local e = {id='e', x=400, y=300, w=100, h=100}
local f = {id='f', x=300, y=900, w=200, h=100}
local g = {id='g', x=600, y=1200, w=200, h=100}
local map = {a, b, c, d, e, f, g}

local WIDTH = 2000
local HEIGH = 2000

-- 每个节点最多容纳多少个矩形
local NODE_CAPACITY = 2

local to_merge = false

local logger = Logger.new()
logger:disable_debug()

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
    logger:debug("spliting region start:", self.x, self.y, self.w, self.h)
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
    local list = self.list
    self.list = nil
    for _, elem in ipairs(list) do
        logger:debugf("    re-add old: %d %d %d %d, id:%s", elem.x, elem.y, elem.w, elem.h, elem.id)
        self:add(elem.x, elem.y, elem.w, elem.h, elem.id)
    end
    logger:debug("spliting region done")

    do_export(tree)
end

function mt:_insert_region(x, y, w, h, id)
    logger:debugf("insert region(%d %d %d %d)", self.x, self.y, self.w, self.h)
    if self.children then
        logger:debug("    insert region children...")
        for _, child in pairs(self.children) do
            child:add(x, y, w, h, id)
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
        id = id,
    }
    self:try_merge(elem)
    tinsert(self.list, elem)

    logger:debug("    insert to list:", #self.list)
    self:check_full()
    if #self.list > NODE_CAPACITY then
        logger:debug("capacity limited, spliting ...")
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
                return {x = new_rect.x, y = e.y, w = new_rect.w + e.w, h = e.h}
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

function mt:check_full()
    if self.full then
        return true
    end

    if self.list then
        local sum = 0
        for _, v in ipairs(self.list) do
            sum = sum + v.w*v.h
        end
        if sum == self.w * self.h then
            self.full = true
        end
    end
    if self.children then
        local full_count = 0
        for _, region_idx in ipairs(Def.REGION_IDX_LIST) do
            local r = self.children[region_idx]
            if r and r.full then
                full_count = full_count + 1
            end
        end
        if full_count == 4 then
            self.full = true
        end
    end

    if self.full then
        self.list = nil
        self.children = nil
    end
    return self.full
end

function mt:is_contained(x, y, w, h)
    if x >= self.x + self.w then
        return false
    end
    if x + w <= self.x then
        return false
    end
    if y >= self.y + self.h then
        return false
    end
    if y + h <= self.y then
        return false
    end
    return true
end

function mt:add(x, y, w, h, id)
    logger:debugf("add rect %d %d %d %d id:%s", x, y, w, h, id)
    assert(x >= 0, x)
    assert(y >= 0, y)
    assert(w > 0, w)
    assert(h > 0, h)

    if not self:is_contained(x, y, w, h) then
        return
    end

    if not(self.children) then
        self:_insert_region(x, y, w, h, id)
    else
        local nw2 = mfloor(self.w/2)
        local nh2 = mfloor(self.h/2)

        local nx = self.x + self.w
        local ny = self.y + self.h

        -- 先添加、再融合、最后再分裂
        local mid_x = self.x + nw2
        local mid_y = self.y + nh2

        logger:debugf("adding to this region:%s %d %d %d %d", self.region_idx, self.x, self.y, self.w, self.h)
        if x + w >= mid_x and x + w <= nx then
            if y + h >= mid_y and y + h <= ny then
                -- 右上角
                local region = self:fetch_region(RU)
                local tempx = mmax(x, mid_x)
                local tempy = mmax(y, mid_y)
                local tempw = x+w-tempx
                local temph = y+h-tempy
                if tempw > 0 and temph > 0 then
                    logger:debugf("    select sub-region RU, fixed: %d %d %d %d id:%s", tempx, tempy, tempw, temph, id)
                    region:_insert_region(tempx, tempy, tempw, temph, id)
                end
            end

            if y >= self.y and y <= mid_y then
                -- 右下角
                local region = self:fetch_region(RD)
                local tempx = mmax(x, mid_x)
                local tempy = y
                local tempw = x+w-tempx
                local temph = mmin(tempy+h, mid_y)-tempy
                if tempw > 0 and temph > 0 then
                    logger:debugf("    select sub-region RD, fixed: %d %d %d %d id:%s", tempx, tempy, tempw, temph, id)
                    region:_insert_region(tempx, tempy, tempw, temph, id)
                end
            end    
        end

        if x >= self.x and x <= mid_x then
            -- 左下角
            if y >= self.y and y <= mid_y then
                local region = self:fetch_region(LD)
                local tempx = x
                local tempy = y
                local tempw = mmin(tempx+w, mid_x) - tempx
                local temph = mmin(y+h, mid_y) - tempy
                if tempw > 0 and temph > 0 then
                    logger:debugf("    select sub-region LD, fixed: %d %d %d %d id:%s", tempx, tempy, tempw, temph, id)
                    region:_insert_region(tempx, tempy, tempw, temph, id)
                end
            end

            if y + h >= mid_y and y + h <= ny then
                -- 左上角
                local region = self:fetch_region(LU)
                local tempx = x
                local tempy = mmax(y, mid_y)
                local tempw = mmin(tempx+w, mid_x)-tempx
                local temph = y+h-tempy
                if tempw > 0 and temph > 0 then
                    logger:debugf("    select sub-region LU, fixed: %d %d %d %d id:%s", tempx, tempy, tempw, temph, id)
                    region:_insert_region(tempx, tempy, tempw, temph, id)
                end
            end
        end
    end

    -- children 全部都满了，当前区域可以进行full
    self:check_full()
end


local function add_rects(list)
    for k, v in ipairs(list) do
        tree:add(v.x, v.y, v.w, v.h, v.id)
        do_export(tree)
    end
end

to_merge = true

-- 初始矩形列表
add_rects(map)

-- 合并区域内的矩形
add_rects{
    {id="A", x=1900, y=1900, w=100, h=100}, -- 添加到空白区域
    {id="B", x=1900, y=1800, w=100, h=100}, -- 添加到已有一个元素的区域，可以合并
    {id="C", x=600, y=1300, w=100, h=100},  -- 添加到已有一个元素的区域，不可合并
    {id="D", x=700, y=1300, w=100, h=100},  -- 添加到已有两个元素的区域，可以连锁合并
}

-- 合并满一个区域
add_rects{
    {id="z", x=0, y=0, w=200, h=500},
    {id="y", x=200, y=0, w=50, h=100},
    {id="x", x=400, y=400, w=100, h=100},
    {id="w", x=400, y=250, w=100, h=50},
}

-- 合并并向上合并
add_rects{
    {id="v", x=250, y=0, w=50, h=100},
    {id="u", x=400, y=200, w=100, h=50},
    {id="t", x=300, y=0, w=200, h=200},
}

PrintR.print_r(tree)
print("Done.")
