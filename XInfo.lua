XInfo = {}
local moduleName = 'XInfo'

-- Bag items
XInfoBagList = {}
XInfoBankList = {}
XInfo.emptyBagCount = 0

XInfo.reloadCount = function()
    XInfo.reloadBag()
    XInfo.reloadBank()
    XInfo.reloadMail()
    XInfo.reloadAuction()
end

XInfo.getItemTotalCount = function(itemName)
    return XInfo.getBagItemCount(itemName)
        + XInfo.getBankItemCount(itemName)
        + XInfo.getMailItemCount(itemName)
        + XInfo.getAuctionItemCount(itemName)
end

-- count, positions(bagId, slotId)
XInfo.getBagItem = function(itemName)
    if XInfoBagList and XInfoBagList[itemName] then
        return XInfoBagList[itemName]
    end
    return nil
end

XInfo.getBagItemCount = function(itemName)
    local item = XInfo.getBagItem(itemName)
    if not item then return 0 end
    return item['count']
end

XInfo.getBankItem = function(itemName)
    if XInfoBankList and XInfoBankList[itemName] then
        return XInfoBankList[itemName]
    end
    return nil
end

XInfo.getBankItemCount = function(itemName)
    local item = XInfo.getBankItem(itemName)
    if not item then return 0 end
    return item['count']
end

local lastBagUpdateTime = 0
local lastBankUpdateTime = 0
function ReloadBagBank(type)
    if type == 'bag' and time() - lastBagUpdateTime < 1 then return end
    if type == 'bank' and time() - lastBankUpdateTime < 1 then return end
    if type == 'bank' then
        if not XAPI.IsBankOpen() then
            return
        end
    end

    local slotIdList = {}
    if type == 'bag' then
        for i = 0, XAPI.NUM_BAG_SLOTS do
            table.insert(slotIdList, i)
        end
    else
        table.insert(slotIdList, -1)
        for i = XAPI.NUM_BAG_SLOTS + 1, XAPI.NUM_BAG_SLOTS + XAPI.NUM_BANKBAGSLOTS do
            table.insert(slotIdList, i)
        end
    end

    local list = {}
    local emptyBagCount = 0

    for _, i in ipairs(slotIdList) do
        local slotCount = XAPI.C_Container_GetContainerNumSlots(i)
        local isBag = (i >= 0 and i <= XAPI.NUM_BAG_SLOTS)
        for j = 1, slotCount do
            local itemInfo = XAPI.C_Container_GetContainerItemInfo(i, j)
            if itemInfo then
                local itemName = itemInfo.itemName
                local count = itemInfo.stackCount
                if list[itemName] then
                    list[itemName]['count'] = list[itemName]['count'] + count
                    table.insert(list[itemName]['positions'], { i, j })
                else
                    list[itemName] = { count = count, positions = { { i, j } } }
                end
            else
                if isBag then
                    emptyBagCount = emptyBagCount + 1
                end
            end
        end
    end

    if type == 'bag' then
        XInfoBagList = list
        XInfo.emptyBagCount = emptyBagCount
        lastBagUpdateTime = time()
    else
        XInfoBankList = list
        lastBankUpdateTime = time()
    end
end

XInfo.reloadBag = function()
    ReloadBagBank('bag')
end

XInfo.reloadBank = function()
    ReloadBagBank('bank')
end

-- Mail Items
XInfoMailList = {}
local lastMailUpdateTime = 0
XInfo.reloadMail = function()
    if time() - lastMailUpdateTime < 1 then return end
    if not XAPI.IsMailBoxOpen() then
        return
    end
    local count = XAPI.GetInboxNumItems();
    local list = {}
    for i = 1, count do
        local mail = { XAPI.GetInboxHeaderInfo(i) }
        local itemCount = mail[8]

        if itemCount then
            if itemCount > 0 then
                for j = 1, 12 do
                    local itemName, _, _, _itemCount = XAPI.GetInboxItem(i, j)
                    if itemName and _itemCount then
                        if list[itemName] then
                            list[itemName]['count'] = list[itemName]['count'] + _itemCount
                        else
                            list[itemName] = { count = _itemCount }
                        end
                    end
                end
            end
        end
    end
    XInfoMailList = list
    lastMailUpdateTime = time()
end

XInfo.getMailItem = function(itemName)
    if XInfoMailList and XInfoMailList[itemName] then
        return XInfoMailList[itemName]
    end
    return nil
end

XInfo.getMailItemCount = function(itemName)
    local item = XInfo.getMailItem(itemName)
    if not item then return 0 end
    return item['count']
end

-- Auction Items
XInfo.auctionList = {}

-- count, minprice, items(index, count, price)
XInfo.getAuctionItem = function(itemName)
    if XInfo.auctionList and XInfo.auctionList[itemName] then
        return XInfo.auctionList[itemName]
    end
    return nil
end

local lastAuctionUpdateTime = 0
XInfo.auctioningCount = 0
XInfo.auctionedCount = 0
XInfo.auctionedMoney = 0
XInfo.reloadAuction = function()
    if time() - lastAuctionUpdateTime < 1 then return end
    if not XAPI.IsAuctionFrameOpen() then return end

    local list = {}
    local numItems = XAPI.GetNumAuctionItems('owner')
    local tAuctioningCount = 0
    local tAuctionedCount = 0
    local tAuctionedMoney = 0
    if numItems <= 0 then
        XInfo.auctionList = {}
        return
    end
    for i = 1, numItems do
        local res = { XAPI.GetAuctionItemInfo('owner', i) }
        local itemName = res[1]
        local stackCount = res[3]
        local buyoutPrice = res[10]
        local saleStatus = res[16]
        if saleStatus ~= 1 then
            local record = { index = i, count = stackCount, price = buyoutPrice / stackCount }
            if list[itemName] then
                local item = list[itemName]
                item['count'] = item['count'] + stackCount
                table.insert(list[itemName]['items'], record)
                if item['minprice'] > buyoutPrice / stackCount then
                    item['minprice'] = buyoutPrice / stackCount
                end
                if item['maxprice'] < buyoutPrice / stackCount then
                    item['maxprice'] = buyoutPrice / stackCount
                end
            else
                list[itemName] = {
                    count = stackCount,
                    minprice = buyoutPrice / stackCount,
                    maxprice = buyoutPrice / stackCount,
                    items = { record }
                }
            end
            tAuctioningCount = tAuctioningCount + 1
        else
            tAuctionedCount = tAuctionedCount + 1
            tAuctionedMoney = tAuctionedMoney + buyoutPrice
        end
    end
    XInfo.auctionList = list
    XInfo.auctioningCount = tAuctioningCount
    XInfo.auctionedCount = tAuctionedCount
    XInfo.auctionedMoney = tAuctionedMoney

    lastAuctionUpdateTime = time()
end

XInfo.getAuctionItemCount = function(itemName)
    local item = XInfo.getAuctionItem(itemName)
    if not item then return 0 end
    return item['count']
end

-- Trade skills
XInfoTradeSkillList = {}

-- index, skillname
XInfo.getTradeSkillItem = function(itemName, type)
    if not type then type = '珠宝加工' end
    if XInfoTradeSkillList and XInfoTradeSkillList[type] and XInfoTradeSkillList[type][itemName] then
        return XInfoTradeSkillList[type][itemName]
    end
    return nil
end

local lastTradeSkillUpdateTime = 0
XInfo.reloadTradeSkill = function(type)
    if time() - lastTradeSkillUpdateTime < 1 then return end

    if not type then type = '珠宝加工' end
    local tradeSkillName = XAPI.GetTradeSkillLine()
    if tradeSkillName ~= type then
        CastSpellByName(type)
        return false
    end

    local list = {}
    local count = XAPI.GetNumTradeSkills()
    for i = 1, count do
        local skillName, skillType = XAPI.GetTradeSkillInfo(i)
        if skillType ~= 'header' and skillType ~= 'subheader' then
            local itemLink = XAPI.GetTradeSkillItemLink(i)
            if itemLink and skillName then
                local itemName = XAPI.GetItemInfo(itemLink)
                list[itemName] = { index = i, skillname = skillName }
            end
        end
    end

    XInfoTradeSkillList[type] = list

    lastTradeSkillUpdateTime = time()
    return true
end

-- Auction Info
XInfo.getAuctionInfo = function(itemName)
    if XAuctionInfoList then
        if XAuctionInfoList[itemName] then
            return XAuctionInfoList[itemName]
        end
    end
    return nil
end

XInfo.getAuctionInfoField = function(itemName, fieldName, defaultValue)
    itemName = strtrim(itemName)
    local item = XInfo.getAuctionInfo(itemName)
    if not item then return defaultValue end;

    -- local fields = { 'itemid', 'itemname', 'itemlink', 'quality', 'level', 'icon',
    --     'vendorprice', 'sort', 'category', 'class', 'group' }
    -- if not XUtils.inArray(fieldName, fields) then
    --     fieldName = fieldName .. '10'
    -- end

    if not item[fieldName] then return defaultValue end

    return item[fieldName]
end

-- Material
XInfo.materialList = { '赤玉石', '紫黄晶', '王者琥珀', '祖尔之眼', '巨锆石', '恐惧石',
    '血玉石', '帝黄晶', '秋色石', '森林翡翠', '天蓝石', '曙光猫眼石',
    '天焰钻石', '大地侵攻钻石' }
XInfo.materialListS = { '血玉石', '帝黄晶', '秋色石', '森林翡翠', '天蓝石', '曙光猫眼石' }
XInfo.materialListB = { '赤玉石', '紫黄晶', '王者琥珀', '祖尔之眼', '巨锆石', '恐惧石' }
XInfo.materialListO = { '天焰钻石', '大地侵攻钻石' }
XInfo.getMaterialName = function(itemName)
    local materialName = nil
    for i = 1, #XInfo.materialList do
        if XUtils.stringContains(itemName, XInfo.materialList[i]) then
            materialName = XInfo.materialList[i]
            break
        end
    end
    return materialName
end

XInfo.getMaterialBagItem = function(itemName)
    local materialName = XInfo.getMaterialName(itemName)
    if materialName then
        return XInfo.getBagItem(materialName)
    else
        return nil
    end
end

XInfo.getMaterialBagCount = function(itemName)
    local materialName = XInfo.getMaterialName(itemName)
    if materialName then
        return XInfo.getBagItemCount(materialName)
    else
        return 0
    end
end

XInfo.getMaterialBankItem = function(itemName)
    local materialName = XInfo.getMaterialName(itemName)
    if materialName then
        return XInfo.getBankItem(materialName)
    else
        return nil
    end
end

XInfo.getMaterialBankCount = function(itemName)
    local materialName = XInfo.getMaterialName(itemName)
    if materialName then
        return XInfo.getBankItemCount(materialName)
    else
        return 0
    end
end

XInfo.getMaterialMailItem = function(itemName)
    local materialName = XInfo.getMaterialName(itemName)
    if materialName then
        return XInfo.getMailItem(materialName)
    else
        return nil
    end
end

XInfo.getMaterialMailCount = function(itemName)
    local materialName = XInfo.getMaterialName(itemName)
    if materialName then
        return XInfo.getMailItemCount(materialName)
    else
        return 0
    end
end

XInfo.getMaterialTotalCount = function(itemName)
    local materialName = XInfo.getMaterialName(itemName)
    if materialName then
        return XInfo.getItemTotalCount(materialName)
    else
        return 0
    end
end

XInfo.getMaterialPrice = function(itemName)
    local price = 0
    local materialName = XInfo.getMaterialName(itemName)
    if materialName then
        local autoBuyItem = XAutoBuy.getItem(materialName)
        if autoBuyItem then price = autoBuyItem['price'] end
    end
    return price
end

-- Character
XInfo.characterList = { '暗影肌', '阿肌' }
XInfo.myName = XAPI.UnitName('player')
XInfo.isMe = function(characterName)
    return XUtils.inArray(characterName, XInfo.characterList)
end

-- print count
XInfo.printBuyHistory = function(itemName, count)
    if not count then count = 30 end
    xdebug.info(itemName, '购买记录')
    local pcount = 0
    for i = #XBuyList, 1, -1 do
        local item = XBuyList[i]
        if item['itemname'] == itemName then
            xdebug.info(XUtils.formatTime(item['time']) ..
            '    ' .. XUtils.priceToMoneyString(item['price']) .. '    ' .. item['count'])
            pcount = pcount + 1
            if pcount > count then return end
        end
    end
end

XInfo.printSellHistory = function(itemName, count)
    if not count then count = 30 end
    xdebug.info(itemName, '购买出售')
    local pcount = 0
    for i = #XSellList, 1, -1 do
        local item = XSellList[i]
        if item['itemname'] == itemName then
            local successStr = '失败'
            if item['issuccess'] then successStr = '成功' end
            xdebug.info(XUtils.formatTime(item['time']) .. '    '
                .. XUtils.priceToMoneyString(item['price']) .. '    '
                .. item['count'] .. '    ' .. successStr)
            pcount = pcount + 1
            if pcount > count then return end
        end
    end
end

-- Event callback
local dft_interval = 3
local function onUpdate()
    if not XItemUpdateList then return end

    for itemName, item in pairs(XItemUpdateList) do
        if item.itemid and item.itemid > 0 then
            if item.category and item.category ~= '' then
                -- do nothing
            else
                local tname, itemLink, quality, level, _, itemType,
                itemSubType, _, _, icon, vendorPrice = XAPI.GetItemInfo(item.itemid)
                if tname then
                    if tname == itemName then
                        XExternal.updateItemInfo(itemName, item.itemid, itemLink, itemType, itemSubType, vendorPrice,
                            quality, level, icon)
                    else
                        XExternal.updateItemInfo(tname, item.itemid, itemLink, itemType, itemSubType, vendorPrice,
                            quality, level, icon)
                        XItemUpdateList[itemName] = nil
                    end
                else
                    XItemUpdateList[itemName] = nil
                end
            end
        else
            local tname, itemLink, quality, level, _, itemType,
            itemSubType, _, _, icon, vendorPrice = XAPI.GetItemInfo(itemName)
            local itemId = XAPI.GetItemInfoInstant(itemLink)
            if tname then
                if itemId then
                    if tname == itemName then
                        XExternal.updateItemInfo(itemName, itemId, itemLink, itemType, itemSubType, vendorPrice, quality,
                            level, icon)
                    else
                        XExternal.updateItemInfo(tname, itemId, itemLink, itemType, itemSubType, vendorPrice, quality,
                            level, icon)
                        XItemUpdateList[itemName] = nil
                    end
                else
                    XItemUpdateList[itemName] = nil
                end
            else
                XItemUpdateList[itemName] = nil
            end
        end
    end
end

local function onItemInfoReceived(...)
    local itemID = select(3, ...)
    local itemName, itemLink, quality, level, _, itemType,
    itemSubType, _, _, icon, vendorPrice = XAPI.GetItemInfo(itemID)
    if itemName then
        XExternal.updateItemInfo(itemName, itemID, itemLink, itemType, itemSubType, vendorPrice, quality, level, icon)
    end
end

-- Events
XAutoAuction.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    XInfo.reloadBag()
end)

XAutoAuction.registerEventCallback(moduleName, 'BAG_UPDATE', XInfo.reloadBag)

XAutoAuction.registerEventCallback(moduleName, 'GET_ITEM_INFO_RECEIVED', onItemInfoReceived)

XAutoAuction.registerUpdateCallback(moduleName, onUpdate, dft_interval)

XAutoAuction.registerRefreshCallback(moduleName, function()
    XInfo.reloadBag()
    XInfo.reloadAuction()
end)

-- Commands
