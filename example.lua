

--local db2 = require("ipdb.reader")
--
--db2 = db2:new("/home/frk/city.free.ipdb")
--
--local loc = db2:find("118.28.1.1")
--
--for k, v in ipairs(loc) do
--
--    print(k, v)
--end
--
--print("\n\n")
--print("=========================\n\n")

function test_reader()

    local reader = require("reader")

    --local db = reader:new("/home/frk/city.free.ipdb")
    local db = reader:new("/home/frk/mydatavipday4.ipdb")

    local loc1 = db:find("118.28.1.1", "EN")

    for k, v in ipairs(loc1) do
        print(k, v)
    end

    local max = 100000
    local min = 0
    while true do
        db:find("118.28.1.1", "EN")
        min = min + 1
        if min >= max then
            break
        end
    end

    print(db.node_count)
end

function test_city()
    local city = require("city")

    local city = city:new("/home/frk/mydatavipday4.ipdb")
    local loc = city:find("118.28.1.1", "EN")

    for k, v in pairs(loc) do
        print(k, v)
    end

    print(loc.country_name)
end


function test_district()
    local dis = require("district")
    local db = dis:new("/home/frk/china_district.ipdb")
    local loc = db:find("111.199.79.160", "CN")
    for k, v in pairs(loc) do
        print(k, v)
    end
    print(loc.district_name)

    print(db:languages())

    local cj = require("cjson");
    print(cj.encode(loc));

    local min = 0
    local max = 100000

    while true do
        min = min + 1
        if min > max then
            break
        end

        db:find("111.199.79.160", "CN")
    end
end

test_district()

function test_base_station()
    local bst = require("base_station")
    local db = bst:new("/home/frk/base_station.ipdb")
    local loc = db:find("111.199.79.160", "CN")
    for k, v in pairs(loc) do
        print(k, v)
    end

    print(loc.country_name)
end