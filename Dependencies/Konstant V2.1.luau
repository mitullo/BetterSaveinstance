-- =============================================
-- Konstant V2.1.luau → Replaced with LuaExpert
-- =============================================

local lua_expert_last = 0

local function decompile(scr)
    local env = getgenv() or _G
    local HttpService = game:GetService("HttpService")

    if not env.getscriptbytecode then
        return "-- exploit does not support getscriptbytecode."
    end

    local ok, bytecode = pcall(env.getscriptbytecode, scr)
    if not ok then
        return "-- failed to read script bytecode\n--[[\n" .. tostring(bytecode) .. "\n--]]"
    end

    -- Rate limit
    local elapsed = os.clock() - lua_expert_last
    if elapsed < 0.15 then
        task.wait(0.15 - elapsed)
    end

    local encoder = (crypt and crypt.base64encode) or (crypt and crypt.base64 and crypt.base64.encode) or base64encode

    if not encoder then
        encoder = function(data) -- fallback base64
            local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
            return ((data:gsub('.', function(x)
                local r,byte = '', x:byte()
                for i=8,1,-1 do r = r .. (byte % 2^i - byte % 2^(i-1) > 0 and '1' or '0') end
                return r
            end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
                if #x < 6 then return '' end
                local c = 0
                for i=1,6 do c = c + (x:sub(i,i) == '1' and 2^(6-i) or 0) end
                return b:sub(c+1,c+1)
            end)..({ '', '==', '=' })[#data % 3 + 1])
        end
    end

    local res = env.request({
        Url = "https://api.lua.expert/decompile",
        Method = "POST",
        Headers = { ["content-type"] = "application/json" },
        Body = HttpService:JSONEncode({ script = encoder(bytecode) })
    })

    lua_expert_last = os.clock()

    if not res or res.StatusCode ~= 200 then
        return "-- LuaExpert API Error\n--[[\n" .. (res and res.Body or "no response") .. "\n--]]"
    end

    return res.Body
end

return { decompile = decompile }
