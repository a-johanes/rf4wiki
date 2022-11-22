
local trim = mw.text.trim

function split (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, trim(str))
    end
    return t
end

function join ( separator, ... )
    -- get the extra arguments as a new table
    local args = { ... }
    return table.concat( args, separator)
end

local p = {}

function p.print(frame)
    local args = frame.args
    local arrayStr = args[1] or {}
    local separator = args[2] or ","
    local delimiters = args[3] or " "
    local pattern = args[4] or "@@@@"
    local subject = args[5] or "@@@@"

    if #arrayStr == 0 then
        return
    end

    -- mw.logObject(args, "args")

    local array = split(arrayStr, separator)
    table.sort(array)

    -- mw.logObject(array, "array")

    local substitute = {}
    for _, v in ipairs(array) do 
        -- mw.log("v", v)
        -- mw.log("sub", pattern:gsub( subject, v))
        local sub = pattern:gsub( subject, v)

        sub = '<div style="display: inline-block">' .. frame:expandTemplate{ title = "RF4 Character", args = {sub,placement='inline'}} .. '</div>'
        
        table.insert(substitute, sub)
    end

    -- mw.logObject(substitute, "substitute")

    return table.concat(substitute, delimiters)
    -- return "test log"
end

return p