package.cpath = package.cpath .. ";./build/?.so"
local PrintR = require "lib.print_r"
local Logger = require "lib.logger"
local Export = require "export"
local Def = require "def"
local RU, RD, LU, LD = Def.RU, Def.RD, Def.LU, Def.LD

local mfloor = math.floor
local mmax = math.max
local mmin = math.min
local tinsert = table.insert
local tremove = table.remove

-- 每个节点最多容纳多少个矩形
local NODE_CAPACITY = 2

local logger = Logger.new()

local function is_node_contained(node, x, y, w, h)
    if x >= node.x + node.w then
        return false
    end
    if x + w <= node.x then
        return false
    end
    if y >= node.y + node.h then
        return false
    end
    if y + h <= node.y then
        return false
    end
    return true
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

function mt:_fetch_region(region_idx, x, y, w, h)
    if not(self.children) then
        self.children = {}
    end

    local r = self.children[region_idx]
    if not(r) then
        r = create_region(x, y, w, h)
        r.region_idx = region_idx
        self.children[region_idx] = r
        r.parent = self
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

    Export.dump_tree(self)
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

    if self.list and #self.list > NODE_CAPACITY then
        logger:debug("capacity limited, spliting ...")
        self:split_region()
    end
end

function mt:try_merge(new_rect)
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
    return is_node_contained(self, x, y, w, h)
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

function mt:add_rects(list)
    for k, v in ipairs(list) do
        self:add(v.x, v.y, v.w, v.h, v.id)

        if self.export_debug_img then
            Export.dump_tree(self)
        end
    end
end

function mt:check_collision(x, y, w, h)
    if not self:is_contained(x, y, w, h) then
        return false
    end

    if self.full then
        return true
    end

    if self.list then
        for _, v in ipairs(self.list) do
            if is_node_contained(v, x, y, w, h) then
                return true
            end
        end
    end

    if self.children then
        for _, r in pairs(self.children) do
            if r:check_collision(x, y, w, h) then
                return true
            end
        end
    end
    return false
end

local M = {}

function M.new(width, heigh, options)
    local tree = create_region(0, 0, width, heigh)
    tree.is_root = true

    logger:disable_debug()
    if options then
        if options['-e'] then
            tree.export_debug_img = true
        end
        if options['-d'] then
            logger:enable_debug()
        end
    end
    return tree
end

return M

