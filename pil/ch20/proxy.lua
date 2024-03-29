function make_tracker()
    local mt = {
        __index = function(t,k)
            print("*access to element " .. tostring(k))
            return t.___[k]
        end,

        __newindex = function(t,k,v)
            print("*update of element " .. tostring(k) .. " to " ..tostring(v))
            t.___[k] = v
        end,

        __pairs = function(t)
            return function(_t,k)
                local nextkey, nextvalue = next(_t,k)
                if nextkey ~= nil then
                    print("*traversing element " .. tostring(nextkey))
                end
                return nextkey, nextvalue
            end, t.___
        end,

        __len = function (t) return #t.___ end
    }

    return function(t)
        local proxy = {}
        proxy.___ = t
        setmetatable(proxy, mt)
        return proxy
    end
end

