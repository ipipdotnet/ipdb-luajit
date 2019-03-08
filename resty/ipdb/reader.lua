
local bit = require("bit")
local cjson = require("cjson")
local ffi = require("ffi")

local lshift = bit.lshift
local rshift = bit.rshift
local band = bit.band

local pow = math.pow
local str_find = string.find
local str_len = string.len
local str_sub = string.sub
local str_byte = string.byte
local fopen = io.open

ffi.cdef [[
    int inet_pton(int af, const char *src, void *dst);
    static const int AF_INET6=10;
    static const int AF_INET=2;
]]

local function ip6_to_bin(ip6)
    local binip6 = ffi.new('char [16]')
    ffi.C.inet_pton(ffi.C.AF_INET6, ip6, binip6);
    return  binip6
end

local function ip4_to_bin(ip4)
    local binip4 = ffi.new('char [4]')
    ffi.C.inet_pton(ffi.C.AF_INET, ip4, binip4);
    return  binip4
end

local function bytes_to_u32(a,b,c,d)
    local _int = 0
    if a then
        _int = _int +  lshift(a, 24)
    end
    if b then
        _int = _int + lshift(b, 16)
    end
    if c then
        _int = _int + lshift(c, 8)
    end
    if d then
        _int = _int + d
    end
    if _int >= 0 then
        return _int
    else
        return _int + pow(2, 32)
    end
end

local function split(str, separator)
    local start = 1
    local index = 1
    local array = {}
    while true do
        local last = str_find(str, separator, start)
        if not last then
            array[index] = str_sub(str, start, str_len(str))
            break
        end
        array[index] = str_sub(str, start, last - 1)
        start = last + str_len(separator)
        index = index + 1
    end
    return array
end

local function read_node(data, node, idx)
    local off = idx * 4 + node * 8
    return bytes_to_u32(
        str_byte(data, off + 1),
        str_byte(data, off + 2),
        str_byte(data, off + 3),
        str_byte(data, off + 4)
    )
end

local _M = {
    _VERSION = '0.1'
}

local mt = {
    __index = _M
}


function _M.new(self, name)
    local file = fopen(name, "rb")
    assert(file, name.. " db file open failed.")
    local file_size = file:seek("end")
    file:seek("set", 0)
    local data = file:read("*all")
    file:close()

    local meta_len = bytes_to_u32(
        str_byte(data, 1),
        str_byte(data, 2),
        str_byte(data, 3),
        str_byte(data, 4)
    )

    local meta_buf = str_sub(data, 5, meta_len + 4)

    local meta = cjson.decode(meta_buf)

    assert(#meta.fields > 0, "db file content error")

    local dl = 4 + meta_len + meta.total_size

    assert(file_size == dl, "db file content error")

    return setmetatable({
        data = str_sub(data, 5+meta_len, str_len(data)),
        meta = meta,
        node_count = meta["node_count"],
        node_ipv4_start = 0,
    }, mt)
end

function _M.find(self, ips, language)

    assert(self.meta["languages"][language], "language no support")

    local ip_address = ""
    local ip_type = 0

    if str_find(ips, ":") then
        ip_address = ip6_to_bin(ips)
        ip_type = 6

        assert(self:ipv6(), "ipv6 no support")
    else
        ip_address = ip4_to_bin(ips)
        ip_type = 4

        assert(self:ipv4(), "ipv4 no support")
    end

    local node = 0

    if ip_type == 4 then
        if self.node_ipv4_start == 0 then
            for i = 0, 95 do
                if i >= 80 then
                    node = read_node(self.data, node, 1)
                else
                    node = read_node(self.data, node, 0)
                end
            end
            self.node_ipv4_start = node
        else
            node = self.node_ipv4_start
        end
    end

    for i = 0, 128 do
        local val = band(1, rshift(ip_address[rshift(i, 3)], 7 - (i % 8)))
        node = read_node(self.data, node, val)
        if node > self.node_count then
            break
        end
    end

    if node < self.node_count then
        return nil
    end

    local resolved = node - self.node_count + self.node_count * 8
    local size = bytes_to_u32(
            0,0,
            str_byte(self.data, resolved+1),
            str_byte(self.data, resolved+2)
    )
    local temp = str_sub(self.data, resolved+3, resolved+2+size)
    local loc  = split(temp, "\t")

    local lang_off = self.meta["languages"][language]
    if type(lang_off) == "nil" then
        return nil
    end

    local fields = self.meta["fields"]
    local length = #fields
    local ret = {}
    local idx = 1

    for  i = lang_off + 1, (lang_off + length) do
        ret[fields[idx]] = loc[i]
        idx = idx + 1
    end

    return ret
end

function _M.ipv4(self)
    return self.meta.ip_version == 1 or self.meta.ip_version == 3
end

function _M.ipv6(self)
    return self.meta.ip_version == 2 or self.meta.ip_version == 3
end

return _M
