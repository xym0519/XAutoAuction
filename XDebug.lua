xdebug = {}

xdebug.LVERROR = 1
xdebug.LVWARN = 2
xdebug.LVDEBUG = 3
xdebug.LVINFO = 4
xdebug.LVVERBOSE = 5

xdebug.level = xdebug.LVINFO

xdebug.printFunction = function(obj, keyword)
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

xdebug.printProperty = function(obj, keyword)
    if keyword == nil then keyword = '' end

    for key, value in pairs(obj) do
        local valueType = type(value)
        local valueStr = ''
        if valueType == 'string' or valueType == 'number' or valueType == 'boolean' then
            valueStr = value .. ''
        end
        if keyword ~= '' then
            if XUtils.stringContains(key, keyword) then
                print(key .. '(' .. valueType .. '): ' .. valueStr)
            end
        else
            print(key .. '(' .. valueType .. '): ' .. valueStr)
        end
    end
end

xdebug.log = function(color, ...)
    if color == nil then
        print(...)
    else
        print(color, ...)
    end
end

xdebug.error = function(...)
    if xdebug.level >= 1 then
        xdebug.log(XUI.Red, ...)
    end
end

xdebug.warn = function(...)
    if xdebug.level >= 2 then
        xdebug.log(XUI.Orange, ...)
    end
end

xdebug.debug = function(...)
    if xdebug.level >= 3 then
        xdebug.log(XUI.Green, ...)
    end
end

xdebug.info = function(...)
    if xdebug.level >= 4 then
        xdebug.log(XUI.Cyan, ...)
    end
end

xdebug.verbose = function(...)
    if xdebug.level >= 5 then
        xdebug.log(XUI.Gray, ...)
    end
end
