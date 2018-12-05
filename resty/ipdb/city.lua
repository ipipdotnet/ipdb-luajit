
local _M = {
    _VERSION = '0.1'
}

local mt = {
    __index = _M
}

local reader = require("resty.ipdb.reader")

function _M.new(self, name)
    return setmetatable({
        db = reader:new(name),
    }, mt)
end

function _M.find(self, ips, language)
    return self.db:find(ips, language)
end

function _M.build(self)
    return self.db.meta["build"]
end

function _M.fields(self)
    return table.concat(self.db.meta.fields, ",")
end

function _M.languages(self)
    local lang = {}
    for k, v in pairs(self.db.meta.languages) do
        table.insert(lang, k)
    end
    return table.concat(lang, ",")
end

return _M
