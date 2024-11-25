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

XUtils.priceToMoneyText = function(money, noZeroCoppers)
    local goldicon   = '金'
    local silvericon = '银'
    local coppericon = '铜'
    local val        = XUtils.round(money);
    local gold       = math.floor(val / 10000);
    val              = val - gold * 10000;
    local silver     = math.floor(val / 100);
    val              = val - silver * 100;
    local copper     = val;

    local st         = '';
    if (gold ~= 0) then
        st = gold .. goldicon;
    end

    if (st ~= '') then
        st = st .. format('%02i%s', silver, silvericon);
    elseif (silver ~= 0) then
        st = st .. silver .. silvericon;
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

XUtils.sendMail = function(itemName, stackCount, fullStack, receiver, money, subject, content)
    if receiver == nil then receiver = XSetting.getMailReceiver(itemName) end
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

    if stackCount <= 0 then
        xdebug.error('发送数量不能小于0')
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
    local itemCount = 0
    for idx = 1, stackCount do
        local position = targetPositions[idx]

        local tItem = XAPI.C_Container_GetContainerItemInfo(position[1], position[2])
        if tItem then
            itemCount = itemCount + tItem['stackCount']
            XAPI.C_Container_PickupContainerItem(position[1], position[2])
            XAPI.ClickSendMailItemButton(idx)
        end
    end

    if money == 'auto' then
        local price = XBuy.getItemField(itemName, 'sellprice', 0)
        if price <= 0 then
            xdebug.error(itemName .. '没有设置单价')
            return
        end
        money = price * itemCount
        local gold = math.floor(money / 10000)
        subject = itemName .. '*' .. itemCount .. ' (' .. gold .. 'G)'
        -- content = XUtils.priceToMoneyText(price, true)
        --     .. ' * ' .. itemCount
        --     .. ' = ' .. XUtils.priceToMoneyText(money, true)
        XAPI.SetSendMailCOD(gold * 10000)
    else
        if type(money) == 'number' then
            XAPI.SetSendMailCOD(money)
        end
        if subject == nil then
            subject = 'P-' .. itemName .. '*' .. stackCount
        end
    end
    XAPI.SendMail(receiver, subject, content)
    xdebug.info(subject)
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

    local count = 0

    if receiveAll then
        XJewTool.registerUIUpdateCallback(moduleName .. '_receiveMail', function()
            if not XAPI.IsMailBoxOpen() then
                XJewTool.unRegisterUIUpdateCallback(moduleName .. '_receiveMail')
                return
            end
            XInfo.reloadBag()
            XInfo.reloadMail()
            if XInfo.emptyBagCount <= 0 then
                XJewTool.unRegisterUIUpdateCallback(moduleName .. '_receiveMail')
                xdebug.error('包裹已满')
                xdebug.info('收取' .. itemName .. ' ' .. count)
                return
            end
            local found = false
            mailCount = XAPI.GetInboxNumItems()
            for idx = 1, mailCount do
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
                                if count >= XInfo.emptyBagCount then break end
                            end
                        end
                        if found then break end
                    end
                end
            end
            if not found then
                XJewTool.unRegisterUIUpdateCallback(moduleName .. '_receiveMail')
                xdebug.info('收取' .. itemName .. ' ' .. count)
                XInfo.reloadBag()
                XInfo.reloadMail()
            end
        end, 0.1)
    else
        local mailIndex = -1
        local itemIndex = -1
        local curCount = 99999
        local attCount = 99999
        for idx = 1, mailCount do
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
                    local tAttCount = 0
                    local tCurCount = 99999
                    local tiidx = -1
                    for iidx = 1, 12 do
                        local _itemName, _, _, _count = XAPI.GetInboxItem(idx, iidx)
                        if _itemName == itemName then
                            tAttCount = tAttCount + 1
                            if _count < tCurCount then
                                tCurCount = _count
                                tiidx = iidx
                            end
                        end
                    end
                    if tAttCount > 0 then
                        if tAttCount < attCount then
                            mailIndex = idx
                            itemIndex = tiidx
                            attCount = tAttCount
                            curCount = tCurCount
                        elseif tAttCount == attCount then
                            if tCurCount < curCount then
                                mailIndex = idx
                                itemIndex = tiidx
                                attCount = tAttCount
                                curCount = tCurCount
                            end
                        end
                    end
                end
            end
        end
        if mailIndex ~= -1 and itemIndex ~= -1 then
            XAPI.TakeInboxItem(mailIndex, itemIndex)
            xdebug.info('收取' .. itemName .. ' ' .. curCount)
            XInfo.reloadBag()
            XInfo.reloadMail()
        end
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
        sourceItems = XInfoBagList[XInfo.myName]
    else
        sourceItems = XInfoBankList[XInfo.myName]
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

XUtils.shrinkBag = function()
    XJewTool.registerUIUpdateCallback(moduleName .. '_shrinkBag', function()
        local notFullList = {}
        local lastItemList = {}

        for i = 0, XAPI.NUM_BAG_SLOTS do
            local bagSlotCount = XAPI.C_Container_GetContainerNumSlots(i)
            for j = 1, bagSlotCount do
                local itemBag = XAPI.C_Container_GetContainerItemInfo(i, j)
                if itemBag then
                    local itemName = itemBag.itemName
                    lastItemList[itemName] = { x = i, y = j }
                    if not XInfo.isItemFullStack(i, j) then
                        if not notFullList[itemName] then
                            notFullList[itemName] = { x = i, y = j }
                        end
                    end
                end
            end
        end
        local found = false
        for itemName, position in pairs(notFullList) do
            local lastPosotion = lastItemList[itemName]
            if position['x'] ~= lastPosotion['x'] or position['y'] ~= lastPosotion['y'] then
                XAPI.C_Container_PickupContainerItem(lastPosotion['x'], lastPosotion['y'])
                XAPI.C_Container_PickupContainerItem(position['x'], position['y'])
                found = true
            end
        end
        if not found then
            XJewTool.unRegisterUIUpdateCallback(moduleName .. '_shrinkBag')
        end
    end, 0.2)
end

XUtils.fulfilBag = function()
    if not XAPI.IsBankOpen() then
        xdebug.error('银行未打开')
        return
    end

    for i = 0, XAPI.NUM_BAG_SLOTS do
        local bagSlotCount = XAPI.C_Container_GetContainerNumSlots(i)
        for j = 1, bagSlotCount do
            local itemBag = XAPI.C_Container_GetContainerItemInfo(i, j)
            if itemBag then
                local itemName = itemBag.itemName
                local count = itemBag.stackCount
                local stackSize = XInfo.getStackSize(itemName)
                if XUtils.inArray(itemName, XInfo.materialList) then
                    if count < stackSize then
                        local subCount = stackSize - count
                        for x = -1, XAPI.NUM_BAG_SLOTS + XAPI.NUM_BANKBAGSLOTS do
                            if count < stackSize then
                                if x < 0 or x > XAPI.NUM_BAG_SLOTS then
                                    local bankSlotCount = XAPI.C_Container_GetContainerNumSlots(x)
                                    for y = 1, bankSlotCount do
                                        local itemBank = XAPI.C_Container_GetContainerItemInfo(x, y)
                                        if itemBank then
                                            local itemName2 = itemBank.itemName
                                            local count2 = itemBank.stackCount
                                            if itemName2 == itemName then
                                                if count2 <= subCount then
                                                    XAPI.C_Container_PickupContainerItem(x, y)
                                                    count = count + count2
                                                else
                                                    XAPI.C_Container_SplitContainerItem(x, y, subCount)
                                                    count = count + subCount
                                                end
                                                XAPI.C_Container_PickupContainerItem(i, j)
                                                if count >= stackSize then
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                            else
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end

XUtils.sortJewsInBag = function(bagIndex)
    -- TODO bagIndex 需要配置
    if bagIndex == nil then bagIndex = XSetting.getNormalBagCount() - 1 end
    local sourceList = {}
    for i = 0, bagIndex do
        local slotCount = XAPI.C_Container_GetContainerNumSlots(i)
        for j = 1, slotCount do
            local itemBag = XAPI.C_Container_GetContainerItemInfo(i, j)
            if itemBag then
                local _, _, _, _, _, itemCategory = XAPI.GetItemInfo(itemBag['itemName'])
                if itemCategory == '珠宝' then
                    table.insert(sourceList, { x = i, y = j })
                end
            end
        end
    end

    local sourceIndex = 1
    for i = XAPI.NUM_BAG_SLOTS, bagIndex + 1, -1 do
        if sourceIndex > #sourceList then
            break
        end
        local bagSlotCount = XAPI.C_Container_GetContainerNumSlots(i)
        for j = 1, bagSlotCount do
            if sourceIndex > #sourceList then
                break
            end
            local itemBag = XAPI.C_Container_GetContainerItemInfo(i, j)
            if not itemBag then
                local tPosition = sourceList[sourceIndex]
                XAPI.C_Container_PickupContainerItem(tPosition['x'], tPosition['y'])
                XAPI.C_Container_PickupContainerItem(i, j)
                sourceIndex = sourceIndex + 1
            end
        end
    end
end

XUtils.sellItems = function(itemNames)
    if itemNames == nil then return end
    if #itemNames < 1 then return end
    if not XAPI.IsMerchantOpen() then
        xdebug.error('请先打开商人')
        return
    end

    XJewTool.registerUIUpdateCallback(moduleName .. '_sellItem', function()
        if not XAPI.IsMerchantOpen() then
            XJewTool.unRegisterUIUpdateCallback(moduleName .. '_sellItem')
            return
        end
        for i = 0, XAPI.NUM_BAG_SLOTS do
            local slotCount = XAPI.C_Container_GetContainerNumSlots(i)
            local found = false
            for j = 1, slotCount do
                local itemBag = XAPI.C_Container_GetContainerItemInfo(i, j)
                if itemBag then
                    if XUtils.inArray(itemBag['itemName'], itemNames) then
                        XAPI.C_Container_UseContainerItem(i, j)
                        found = true
                    end
                end
            end
            if found then return end
        end
        XJewTool.unRegisterUIUpdateCallback(moduleName .. '_sellItem')
    end, 0.5)
end

XJewTool.registerEventCallback(moduleName, 'UI_ERROR_MESSAGE', function(_, _, code, message)
    if code == 3 then
        XJewTool.unRegisterUIUpdateCallback(moduleName .. '_receiveMail')
        xdebug.error('包裹已满')
        XInfo.reloadBag()
        XInfo.reloadMail()
    end
end)
