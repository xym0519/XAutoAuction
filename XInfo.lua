XInfo = {}
local moduleName = 'XInfo'

-- Bag items
XInfoBagList = {}
XInfo.emptyBagCount = 0

-- count, bankcount, totalcount, positions(x, y)
XInfo.getBagItem = function(itemName)
    if XInfoBagList and XInfoBagList[itemName] then
        return XInfoBagList[itemName]
    end
    return nil
end

local lastBagUpdateTime = 0
XInfo.reloadBag = function()
    if time() - lastBagUpdateTime < 1 then return end

    local list = {}
    local emptyBagCount = 0

    for i = -1, XAPI.NUM_BAG_SLOTS + XAPI.NUM_BANKBAGSLOTS do
        local slotCount = XAPI.C_Container_GetContainerNumSlots(i)
        local isBag = (i >= 0 and i <= XAPI.NUM_BAG_SLOTS)
        for j = 1, slotCount do
            local itemInfo = XAPI.C_Container_GetContainerItemInfo(i, j)
            if itemInfo then
                local itemName = itemInfo.itemName
                local count = itemInfo.stackCount
                if list[itemName] then
                    list[itemName]['totalcount'] = list[itemName]['totalcount'] + count
                    if isBag then
                        list[itemName]['count'] = list[itemName]['count'] + count
                        table.insert(list[itemName]['positions'], { i, j })
                    else
                        list[itemName]['bankcount'] = list[itemName]['bankcount'] + count
                    end
                else
                    if isBag then
                        list[itemName] = { count = count, bankcount = 0, totalcount = count, positions = { { i, j } } }
                    else
                        list[itemName] = { count = 0, bankcount = count, totalcount = count, positions = {} }
                    end
                end
            else
                if isBag then
                    emptyBagCount = emptyBagCount + 1
                end
            end
        end
    end

    -- 银行未打开，从之前的数据中获取bankcount
    if XAPI.C_Container_GetContainerNumSlots(5) <= 0 then
        for itemName, item in pairs(XInfoBagList) do
            local newItem = list[itemName]
            if not newItem then
                list[itemName] = { count = 0, bankcount = item['bankcount'], totalcount = item['bankcount'], positions = {} }
            else
                newItem['bankcount'] = item['bankcount']
                newItem['totalcount'] = list[itemName]['count'] + item['bankcount']
            end
        end
    end
    XInfoBagList = list
    XInfo.emptyBagCount = emptyBagCount

    lastBagUpdateTime = time()
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
            else
                list[itemName] = {
                    count = stackCount,
                    minprice = buyoutPrice / stackCount,
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

-- Auction statistics info
XInfo.getAuctionInfo = function(itemName)
    if XAuctionInfoList and XAuctionInfoList[itemName] then
        return XAuctionInfoList[itemName]
    end
    return nil
end

XInfo.getAuctionInfoField = function(itemName, fieldName, defaultValue, allHistory)
    itemName = strtrim(itemName)
    local item = XInfo.getAuctionInfo(itemName)
    if not item then return defaultValue end;

    if allHistory == nil then
        allHistory = XInfo.allHistory
    end

    local fields = { 'itemid', 'itemname', 'itemlink', 'quality', 'level', 'icon',
        'vendorprice', 'sort', 'category', 'class', 'group' }
    if not XUtils.inArray(fieldName, fields) then
        if allHistory == 1 then
            fieldName = fieldName .. '10'
        elseif allHistory == 2 then
            fieldName = fieldName .. '30'
        end
    end

    if not item[fieldName] then return defaultValue end

    return item[fieldName]
end

-- Material
XInfo.materialList = { '赤玉石', '紫黄晶', '王者琥珀', '祖尔之眼', '巨锆石', '恐惧石', '血玉石', '帝黄晶', '秋色石', '森林翡翠', '天蓝石', '曙光猫眼石', '天焰钻石',
    '大地侵攻钻石' }
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

-- Character
XInfo.characterList = { '暗影肌', '阿肌' }
XInfo.myName = XAPI.UnitName('player')
XInfo.isMe = function(characterName)
    return XUtils.inArray(characterName, XInfo.characterList)
end

-- Other 0-all 1-10 2-30
XInfo.allHistory = 1

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
SlashCmdList['XINFOALLHISTORY'] = function()
    XInfo.allHistory = (XInfo.allHistory + 1) % 3
    XAutoAuction.refreshUI()
end
SLASH_XINFOALLHISTORY1 = '/xinfo_allhistory'
