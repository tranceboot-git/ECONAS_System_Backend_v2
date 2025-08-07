utf8 = require("lua-utf8")


function decode_value(tag, timestamp, record)
    ---------------------------------------------------------------------------
    -- \x エスケープシーケンスを utf-8 にデコードする
    ---------------------------------------------------------------------------

    -- ロギング開始
    -- local file, err = io.open("/var/log/lua_log.txt", "a")
    -- if not file then
    --     print("Failed to open file: " .. tostring(err))
    --     return 1, timestamp, record
    -- end
    -- file:write("----------" .. "\n")
    -- file:write("decode_value called with tag: " .. tag .. "\n")
    -- file:write("decode_value input record: " .. table_to_string(record) .. "\n")
    -- ロギング終了

    if record["log"] then
        -- \x エスケープシーケンスを utf-8 にデコードする
        record["log"] = decode_utf8(record["log"])
    else
        io.stderr:write("Unable to retrieve log field" .. "\n")
        return -1, timestamp, record
    end

    -- ロギング開始
    -- file:write("decode_value finished processing record: " .. table_to_string(record) .. "\n")
    -- file:write("----------" .. "\n")
    -- file:close()
    -- ロギング終了

    return 1, timestamp, record
end


function decode_utf8(s)
    ---------------------------------------------------------------------------
    -- UTF-8バイト列をデコードする。
    -- "\xe4\xba\xba" のような形式のバイト列を想定しています。
    ---------------------------------------------------------------------------

    local result = ""
    local i, len = 1, #s
    while i <= len do
        if s:sub(i, i) == "\\" and s:sub(i+1, i+1) == "x" then
            -- 16進表記をバイトに変換
            local hex = s:sub(i+2, i+3)
            local byte = string.char(tonumber(hex, 16))
            result = result .. byte
            i = i + 4
        else
            result = result .. s:sub(i, i)
            i = i + 1
        end
    end

    -- バイト列をUTF-8としてデコード
    result = utf8.char(utf8.codepoint(result, 1, #result))
    return result
end


function table_to_string(tbl, indent)
    ---------------------------------------------------------------------------
    -- テーブルの内容を表示する
    ---------------------------------------------------------------------------

    if not indent then indent = 0 end
    local toprint = string.rep(" ", indent) .. "{\r\n"
    indent = indent + 2
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint  .. k ..  "= "
        end
        if (type(v) == "number" or type(v) == "string") then
            toprint = toprint .. v .. ",\r\n"
        elseif (type(v) == "table") then
            toprint = toprint .. table_to_string(v, indent + 2) .. ",\r\n"
        else
            toprint = toprint .. "<" .. type(v) .. ">,\r\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent-2) .. "}"
    return toprint
end
