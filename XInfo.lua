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

    for i = -1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
        local slotCount = C_Container.GetContainerNumSlots(i)
        local isBag = (i >= 0 and i <= NUM_BAG_SLOTS)
        for j = 1, slotCount do
            local itemInfo = C_Container.GetContainerItemInfo(i, j)
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
    if C_Container.GetContainerNumSlots(5) <= 0 then
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
XInfo.reloadAuction = function()
    if time() - lastAuctionUpdateTime < 1 then return end
    if not AuctionFrame or not AuctionFrame:IsVisible() then return end

    local list = {}
    local numItems = GetNumAuctionItems('owner')
    if numItems <= 0 then
        XInfo.auctionList = {}
        return true
    end
    for i = 1, numItems do
        local itemName, _, itemCount, _, _, _, _, _, _, buyoutPrice = GetAuctionItemInfo('owner', i)
        if list[itemName] then
            local item = list[itemName]
            item['count'] = item['count'] + itemCount
            table.insert(list[itemName]['items'], { index = i, count = itemCount, price = buyoutPrice })
            if item['minprice'] > buyoutPrice then
                item['minprice'] = buyoutPrice
            end
        else
            list[itemName] = { count = itemCount, minprice = buyoutPrice, items = { { index = i, count = itemCount, price = buyoutPrice } } }
        end
    end
    XInfo.auctionList = list

    lastAuctionUpdateTime = time()
end

-- Trade skills
XInfo.tradeSkillList = {}

-- index, skillname
XInfo.getTradeSkillItem = function(itemName)
    if XInfo.tradeSkillList and XInfo.tradeSkillList[itemName] then
        return XInfo.tradeSkillList[itemName]
    end
    return nil
end

local lastTradeSkillUpdateTime = 0
XInfo.reloadTradeSkill = function(type)
    if time() - lastTradeSkillUpdateTime < 1 then return end

    if not type then type = '珠宝加工' end
    if GetTradeSkillLine() ~= type then
        CastSpellByName(type)
        return false
    end

    local list = {}
    for i = 1, GetNumTradeSkills() do
        local itemLink = GetTradeSkillItemLink(i)
        local skillName = GetTradeSkillInfo(i)
        if itemLink and skillName then
            local itemName = GetItemInfo(itemLink)
            list[itemName] = { index = i, skillname = skillName }
        end
    end

    XInfo.tradeSkillList = list

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

    local fields = { 'itemname', 'vendorprice', 'sort', 'category', 'class', 'group' }
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
XInfo.materialList = { '赤玉石', '紫黄晶', '王者琥珀', '祖尔之眼', '巨锆石', '恐惧石', '血玉石', '帝黄晶', '秋色石', '森林翡翠', '天蓝石', '曙光猫眼石' }
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
XInfo.myName = UnitName('player')
XInfo.isMe = function(characterName)
    return XUtils.inArray(characterName, XInfo.characterList)
end

-- Other 0-all 1-10 2-30
XInfo.allHistory = 2

-- Event callback
local lastUpdateTime = 0
local dft_interval = 3
local function onUpdate()
    if not XItemUpdateList then return end
    if time() - lastUpdateTime < dft_interval then return end
    lastUpdateTime = time()

    for itemName, item in pairs(XItemUpdateList) do
        if item.itemid and item.itemid > 0 then
            if item.category and item.category ~= '' then
                -- do nothing
            else
                local tname, itemLink, _, _, _, itemType,
                itemSubType, _, _, _, vendorPrice = GetItemInfo(item.itemid)
                if tname then
                    if tname == itemName then
                        XExternal.updateItemInfo(itemName, item.itemid, itemType, itemSubType, vendorPrice)
                        -- print(XUI.Green .. 'Item updated from onupdate: ' .. itemName)
                    else
                        XExternal.updateItemInfo(tname, item.itemid, itemType, itemSubType, vendorPrice)
                        XItemUpdateList[itemName] = nil
                        -- print(XUI.Green .. 'Item updated from onupdate: ' .. tname)
                        -- print(XUI.Red .. 'Item removed from onupdate: ' .. itemName)
                    end
                else
                    XItemUpdateList[itemName] = nil
                    -- print(XUI.Red .. 'Item removed from onupdate: ' .. itemName)
                end
            end
        else
            local tname, itemLink, _, _, _, itemType,
            itemSubType, _, _, _, vendorPrice = GetItemInfo(itemName)
            local itemId = GetItemInfoInstant(itemLink)
            if tname then
                if itemId then
                    if tname == itemName then
                        XExternal.updateItemInfo(itemName, itemId, itemType, itemSubType, vendorPrice)
                        -- print(XUI.Green .. 'Item updated from onupdate: ' .. itemName)
                    else
                        XExternal.updateItemInfo(tname, itemId, itemType, itemSubType, vendorPrice)
                        XItemUpdateList[itemName] = nil
                        -- print(XUI.Green .. 'Item updated from onupdate: ' .. tname)
                        -- print(XUI.Red .. 'Item removed from onupdate: ' .. itemName)
                    end
                else
                    XItemUpdateList[itemName] = nil
                    -- print(XUI.Red .. 'Item removed from onupdate: ' .. itemName)
                end
            else
                XItemUpdateList[itemName] = nil
                -- print(XUI.Red .. 'Item removed from onupdate: ' .. itemName)
            end
        end
    end
end

local function onItemInfoReceived(self, event, itemID, success)
    local itemName, itemLink, _, _, _, itemType,
    itemSubType, _, _, _, vendorPrice = GetItemInfo(itemID)
    if itemName then
        XExternal.updateItemInfo(itemName, itemID, itemType, itemSubType, vendorPrice)
        -- print(XUI.Green .. 'Item updated from event: ' .. itemName)
    end
end

-- Events
XAutoAuction.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    XInfo.reloadBag()
end)

XAutoAuction.registerEventCallback(moduleName, 'BAG_UPDATE', XInfo.reloadBag)

XAutoAuction.registerEventCallback(moduleName, 'GET_ITEM_INFO_RECEIVED', onItemInfoReceived)

XAutoAuction.registerUpdateCallback(moduleName, onUpdate)

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
