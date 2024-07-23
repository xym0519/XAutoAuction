XUtils = {}
XUtils.formatTime = function(timestamp)
    local time = math.floor((timestamp % (24 * 3600)) / 60)
    local hour = (math.floor(time / 60) + 8) % 24
    local shour = ''
    if hour < 10 then
        shour = '0' .. hour
    else
        shour = '' .. hour
    end
    local minute = time % 60
    local sminute = ''
    if minute < 10 then
        sminute = '0' .. minute
    else
        sminute = '' .. minute
    end
    return shour .. ':' .. sminute
end

XUtils.formatTimeLeft = function(seconds)
    if seconds < 0 then seconds = 0 end
    return XUtils.padStringLeft(math.floor(seconds / 60), 2, '0') ..
        ':' .. XUtils.padStringLeft(seconds % 60, 2, '0')
end

XUtils.formatCount = function(count, length)
    if length == nil then
        length = 2
    end

    local maxCount = 1
    for i = 1, length do
        maxCount = maxCount * 10
    end
    maxCount = maxCount - 1

    local scount = count .. ''
    if count > maxCount then
        scount = maxCount .. ''
    else
        while (string.len(scount) < length) do
            scount = '0' .. scount;
        end
    end
    return scount
end

XUtils.formatCount2 = function(count)
    local countStr = tostring(count)
    local length = #countStr;
    local result = countStr:sub(1, 1)

    if (length == 1) then
        result = XUI.Red .. result
    elseif (length == 2) then
        result = XUI.Yellow .. result
    elseif (length == 3) then
        result = XUI.Green .. result
    else
        result = XUI.Cyan .. result
    end

    return result
end

XUtils.itemIDfromLink = function(itemLink)
    if (itemLink == nil) then
        return 0, 0, 0;
    end

    local found, _, itemString = string.find(itemLink, '^|c%x+|H(.+)|h%[.*%]')
    local _, itemId, _, _, _, _, _, suffixId, uniqueId = strsplit(':', itemString)

    return tonumber(itemId), tonumber(suffixId), tonumber(uniqueId);
end

XUtils.priceToMoneyString = function(money, noZeroCoppers)
    local goldicon   = '|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:4:0|t'
    local silvericon = '|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:4:0|t'
    local coppericon = '|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:4:0|t'
    local val        = XUtils.round(money);
    local gold       = math.floor(val / 10000);
    val              = val - gold * 10000;
    local silver     = math.floor(val / 100);
    val              = val - silver * 100;
    local copper     = val;

    local st         = '';
    if (gold ~= 0) then
        st = gold .. goldicon .. '  ';
    end

    if (st ~= '') then
        st = st .. format('%02i%s  ', silver, silvericon);
    elseif (silver ~= 0) then
        st = st .. silver .. silvericon .. '  ';
    end

    if (noZeroCoppers and copper == 0) then
        return st;
    end

    if (st ~= '') then
        st = st .. format('%02i%s', copper, coppericon);
    elseif (copper ~= 0) then
        st = st .. copper .. coppericon;
    end

    return st;
end

XUtils.priceToString = function(money)
    local val    = XUtils.round(money);
    local gold   = math.floor(val / 10000);
    val          = val - gold * 10000;
    local silver = math.floor(val / 100);

    return gold .. '.' .. string.format('%02d', silver);
end


XUtils.stringStartsWith = function(s, sub)
    if (s == nil or sub == nil or sub == '') then
        return false;
    end

    local sublen = string.len(sub);

    if (string.len(s) < sublen) then
        return false;
    end

    return (string.lower(string.sub(s, 1, sublen)) == string.lower(sub));
end

XUtils.stringEndsWith = function(s, sub)
    if (sub == nil or sub == '') then
        return false;
    end

    local i = string.len(s) - string.len(sub);

    if (i < 0) then
        return false;
    end

    local sEnd = string.sub(s, i + 1);

    return (string.lower(sEnd) == string.lower(sub));
end

XUtils.stringContains = function(s, sub)
    if (s == nil or s == '' or sub == nil or sub == '') then
        return false;
    end

    local start, stop = string.find(string.lower(s), string.lower(sub), 1, true);

    return (start ~= nil);
end

XUtils.padStringRight = function(str, length, char)
    while (string.len(str) < length) do
        str = str .. char;
    end
    return str;
end

XUtils.padStringLeft = function(str, length, char)
    while (string.len(str) < length) do
        str = char .. str;
    end
    return str;
end

XUtils.inArray = function(value, array)
    for _, v in ipairs(array) do
        if v == value then
            return true
        end
    end
    return false
end

XUtils.round = function(v)
    return math.floor(v + 0.5);
end

XUtils.printFunction = function(obj, keyword)
    -- 获取对象的元表
    local meta = getmetatable(obj)

    -- 检查元表是否存在
    if meta then
        -- 获取元表中的__index表
        local items = meta.__index
        if items then
            for key, value in pairs(items) do
                if type(value) == 'function' then
                    if keyword then
                        if XUtils.stringContains(key, keyword) then
                            print(key)
                        end
                    else
                        print(key)
                    end
                end
            end
        else
            print('No __index table found in the metatable.')
        end
    else
        print('No metatable found.')
    end
end

XUtils.printProperty = function(obj, keyword)
    for key, value in pairs(obj) do
        local valueType = type(value)
        local valueStr = ''
        if valueType == 'string' or valueType == 'number' or valueType == 'boolean' then
            valueStr = value .. ''
        end
        if keyword then
            if XUtils.stringContains(key, keyword) then
                print(key .. ': ' .. valueStr)
            end
        else
            print(key .. '(' .. valueType .. ')' .. ': ' .. valueStr)
        end
    end
end
