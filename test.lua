local PrintR = require "lib.print_r"
local Args = require "lib.args"
local Fog = require "fog"
local Def = require "def"
local sformat = string.format

local args = Args.parse(...)
PrintR.print_r("args:", args)

-- 地图大小
local WIDTH = 2000
local HEIGH = 2000

local tree = Fog.new(WIDTH, HEIGH, args)

-- 初始矩形列表
tree:add_rects{
    {id='a', x=100, y=600, w=100, h=100},
    {id='b', x=200, y=100, w=100, h=700},
    {id='c', x=300, y=600, w=100, h=100},
    {id='d', x=300, y=200, w=100, h=300},
    {id='e', x=400, y=300, w=100, h=100},
    {id='f', x=300, y=900, w=200, h=100},
    {id='g', x=600, y=1200, w=200, h=100},
}

-- 合并区域内的矩形
tree:add_rects{
    {id="A", x=1900, y=1900, w=100, h=100}, -- 添加到空白区域
    {id="B", x=1900, y=1800, w=100, h=100}, -- 添加到已有一个元素的区域，可以合并
    {id="C", x=600, y=1300, w=100, h=100},  -- 添加到已有一个元素的区域，不可合并
    {id="D", x=700, y=1300, w=100, h=100},  -- 添加到已有两个元素的区域，可以连锁合并
}

-- 合并满一个区域
tree:add_rects{
    {id="z", x=0, y=0, w=200, h=500},
    {id="y", x=200, y=0, w=50, h=100},
    {id="x", x=400, y=400, w=100, h=100},
    {id="w", x=400, y=250, w=100, h=50},
}

-- 合并并向上合并
tree:add_rects{
    {id="v", x=250, y=0, w=50, h=100},
    {id="u", x=400, y=200, w=100, h=50},
    {id="t", x=300, y=0, w=200, h=200},
}
PrintR.print_r(tree)

-- 测试查找
local exp
if args['-e'] then
    local Export = require "export"
    exp = Export.export(tree, "test_find_")
end

local function test_find_rect(v)
    x = v.x
    y = v.y
    w = v.w
    h = v.h
    id = v.id
    if tree:check_collision(x, y, w, h) then
        print(sformat("<x:%d, y:%d, w:%d, h:%d>", x, y, w, h), "collied")
        id = id .."-1"
    else
        print(sformat("<x:%d, y:%d, w:%d, h:%d>", x, y, w, h), "free")
        id = id .."-0"
    end

    if args['-e'] then
        y = HEIGH-(y+h)
        exp:rect_color(Def.COLOR_YELLOW, x, y, w, h, id)
    end
end

print()
print("===========================================")
print("test finding...")
test_find_rect{id="?", x=1500, y=500, w=80, h=80}
test_find_rect{id="?", x=100, y=100, w=80, h=80}
test_find_rect{id="?", x=280, y=580, w=80, h=80}

print()
if args['-e'] then
    local Export = require "export"
    Export.dump_exp(exp, "test_find_")
end

print("Done.")