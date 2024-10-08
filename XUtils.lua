XUtils = {}
local moduleName = 'XUtils'

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
    if char == nil then char = ' ' end
    while (string.len(str) < length) do
        str = str .. char;
    end
    return str;
end

XUtils.padStringLeft = function(str, length, char)
    if char == nil then char = '  ' end
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

XUtils.sendMail = function(itemName, stackCount, fullStack, receiver, money)
    if receiver == nil then receiver = '阿肌' end
    if fullStack == nil then fullStack = true end

    if not XAPI.IsMailBoxOpen() then
        xdebug.error('请先打开邮箱')
        return
    end

    XInfo.reloadBag()
    local bagItem = XInfo.getBagItem(itemName)
    if not bagItem then
        xdebug.error('背包中未找到该物品')
        return
    end

    if #bagItem['positions'] < stackCount then
        xdebug.error(itemName .. '数量不足')
        return
    end

    for idx = 1, 12 do
        XAPI.ClickSendMailItemButton(idx, true)
    end
    local targetPositions = {}
    for idx = 1, #bagItem['positions'] do
        local position = bagItem['positions'][idx];
        if fullStack then
            if XInfo.isItemFullStack(position[1], position[2]) then
                table.insert(targetPositions, position)
            end
        else
            table.insert(targetPositions, position)
        end
        if #targetPositions >= stackCount then
            break
        end
    end
    if #targetPositions < stackCount then
        xdebug.error(itemName .. '数量不足')
        return
    end

    if stackCount > 12 then stackCount = 12 end
    for idx = 1, stackCount do
        local position = targetPositions[idx]
        XAPI.C_Container_PickupContainerItem(position[1], position[2])
        XAPI.ClickSendMailItemButton(idx)
    end

    if money ~= nil then
        if money > 0 then
            XAPI.SetSendMailCOD(money)
        end
    end
    XAPI.SendMail(receiver, 'P-' .. itemName .. '-' .. stackCount)
    xdebug.info(itemName .. '发送成功')
    XInfo.reloadBag()
    XInfo.reloadMail()
end

XUtils.receiveMail = function(itemName, receiveAll, onlyAH)
    if receiveAll == nil then receiveAll = false end
    if onlyAH == nil then onlyAH = false end

    if not XAPI.IsMailBoxOpen() then
        xdebug.error('请先打开邮箱')
        return
    end

    local mailCount = XAPI.GetInboxNumItems()
    if mailCount <= 0 then
        xdebug.error('没有邮件')
        return
    end

    XInfo.reloadBag()

    if XInfo.emptyBagCount <= 0 then
        xdebug.error('包裹已满')
        return
    end

    local stackCount = XInfo.getStackCount(itemName)
    local emptyCount = XInfo.emptyBagCount * stackCount
    local count = 0

    if receiveAll then
        XAutoAuction.registerUIUpdateCallback(moduleName .. '_receiveMail', function()
            if not XAPI.IsMailBoxOpen() then
                XAutoAuction.unRegisterUIUpdateCallback(moduleName .. '_receiveMail')
                return
            end
            local found = false
            for idx = mailCount, 1, -1 do
                local mailInfo = { XAPI.GetInboxHeaderInfo(idx) }
                local subject = mailInfo[4]
                if subject ~= nil then
                    local canReceive = false
                    local mailType = XAPI.Postal_GetMailType(subject)
                    if onlyAH then
                        if mailType == XAPI.Postal_MailType_AHWon
                            or mailType == XAPI.Postal_MailType_AHOutbid
                            or mailType == XAPI.Postal_MailType_AHSuccess
                            or mailType == XAPI.Postal_MailType_AHExpired
                            or mailType == XAPI.Postal_MailType_AHCancelled then
                            canReceive = true
                        end
                    else
                        canReceive = true
                    end
                    if canReceive then
                        for iidx = 1, 12 do
                            local _itemName, _, _, _count = XAPI.GetInboxItem(idx, iidx)
                            if _itemName == itemName then
                                found = true
                                XAPI.TakeInboxItem(idx, iidx)
                                count = count + _count
                                break
                            end
                        end
                        if found then break end
                    end
                end
            end
            if not found or count >= emptyCount then
                XAutoAuction.unRegisterUIUpdateCallback(moduleName .. '_receiveMail')
                xdebug.info('收取' .. itemName .. ' ' .. count)
                XInfo.reloadBag()
                XInfo.reloadMail()
            end
        end, 0.1)
    else
        for idx = 1, mailCount do
            local found = false
            local mailInfo = { XAPI.GetInboxHeaderInfo(idx) }
            local subject = mailInfo[4]
            if subject ~= nil then
                local canReceive = false
                local mailType = XAPI.Postal_GetMailType(subject)
                if onlyAH then
                    if mailType == XAPI.Postal_MailType_AHWon
                        or mailType == XAPI.Postal_MailType_AHOutbid
                        or mailType == XAPI.Postal_MailType_AHSuccess
                        or mailType == XAPI.Postal_MailType_AHExpired
                        or mailType == XAPI.Postal_MailType_AHCancelled then
                        canReceive = true
                    end
                else
                    canReceive = true
                end
                if canReceive then
                    for iidx = 1, 12 do
                        local _itemName, _, _, _count = XAPI.GetInboxItem(idx, iidx)
                        if _itemName == itemName then
                            found = true
                            XAPI.TakeInboxItem(idx, iidx)
                            count = count + _count
                            break
                        end
                    end
                end
            end
            if found then break end
        end
        xdebug.info('收取' .. itemName .. ' ' .. count)
        XInfo.reloadBag()
        XInfo.reloadMail()
    end
end

function MoveToBagBank(itemNames, direcion, stackCount, exceptions, fullStack)
    if not XAPI.IsBankOpen() then
        xdebug.error('请先打开银行')
        return
    end
    XInfo.reloadBag()
    XInfo.reloadBank()

    if itemNames == nil then itemNames = {} end
    if type(itemNames) == "string" then itemNames = { itemNames } end
    if exceptions == nil then exceptions = {} end
    if fullStack == nil then fullStack = true end

    local sourceItems = {}
    if direcion == 'tobank' then
        sourceItems = XInfoBagList
    else
        sourceItems = XInfoBankList
    end
    local sourcePositions = {}

    local targetEmptyCount = 0
    if direcion == 'tobank' then
        targetEmptyCount = XInfo.emptyBankCount
    else
        targetEmptyCount = XInfo.emptyBagCount
    end

    for _itemName, item in pairs(sourceItems) do
        if not XUtils.inArray(_itemName, exceptions) then
            if #itemNames == 0 or XUtils.inArray(_itemName, itemNames) then
                for _, position in ipairs(item['positions']) do
                    if fullStack then
                        if XInfo.isItemFullStack(position[1], position[2]) then
                            table.insert(sourcePositions, position)
                        end
                    else
                        table.insert(sourcePositions, position)
                    end
                end
            end
        end
        if stackCount then
            if #sourcePositions >= stackCount then
                break
            end
        end
        if #sourcePositions >= targetEmptyCount then
            break
        end
    end

    if stackCount then
        if #sourcePositions < stackCount then
            if #itemNames == 1 then
                xdebug.error(itemNames[1] .. '数量不足')
            else
                xdebug.error('物品数量不足')
            end
            return
        end
    end

    local count = stackCount
    if not count then count = #sourcePositions end
    if count > targetEmptyCount then count = targetEmptyCount end
    for i = 1, count do
        local position = sourcePositions[i]
        if position then
            XAPI.C_Container_UseContainerItem(position[1], position[2])
        end
    end
    if #itemNames == 1 then
        xdebug.info(itemNames[1] .. '放入银行成功')
    else
        xdebug.info('物品放入银行成功')
    end
    XInfo.reloadBag()
    XInfo.reloadBank()
end

XUtils.moveToBag = function(itemNames, stackCount, exceptions, fullStack)
    MoveToBagBank(itemNames, 'tobag', stackCount, exceptions, fullStack)
end

XUtils.moveToBank = function(itemNames, stackCount, exceptions, fullStack)
    MoveToBagBank(itemNames, 'tobank', stackCount, exceptions, fullStack)
end
