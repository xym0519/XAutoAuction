XInfo = CreateFrame("Frame")

XInfoBagList = {}
XInfo.emptyBagCount = 0

-- count, bankcount, totalcount, positions(x, y)
XInfo.getBagItem = function(itemName)
    if XInfoBagList ~= nil and XInfoBagList[itemName] ~= nil then
        return XInfoBagList[itemName]
    end
    return nil
end

XInfo.reloadBag = function()
    local list = {}
    local emptyBagCount = 0
    for i = -1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
        local slotCount = GetContainerNumSlots(i)
        local isBag = (i >= 0 and i <= NUM_BAG_SLOTS)
        for j = 1, slotCount do
            local _, count, _, _, _, _, link = GetContainerItemInfo(i, j)
            if link ~= nil then
                local itemName = GetItemInfo(link)
                if list[itemName] ~= nil then
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
    if GetContainerNumSlots(5) <= 0 then
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
end

XInfo.auctionList = {}

-- count, minprice, items(index, count, price)
XInfo.getAuctionItem = function(itemName)
    if XInfo.auctionList ~= nil and XInfo.auctionList[itemName] ~= nil then
        return XInfo.auctionList[itemName]
    end
    return nil
end

XInfo.reloadAuction = function()
    local list = {}
    local numItems = GetNumAuctionItems("owner")
    if numItems <= 0 then
        XInfo.auctionList = {}
        return true
    end
    for i = 1, numItems do
        local itemName, _, itemCount, _, _, _, buyoutPrice = GetAuctionItemInfo("owner", i)
        if list[itemName] ~= nil then
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
end

XInfo.tradeSkillList = {}

-- index, skillname
XInfo.getTradeSkillItem = function(itemName)
    if XInfo.tradeSkillList ~= nil and XInfo.tradeSkillList[itemName] ~= nil then
        return XInfo.tradeSkillList[itemName]
    end
    return nil
end

XInfo.reloadTradeSkill = function()
    local type = '珠宝加工'
    if GetTradeSkillLine() ~= type then
        CastSpellByName(type)
        return false
    end

    local list = {}
    for i = 1, GetNumTradeSkills() do
        local itemLink = GetTradeSkillItemLink(i)
        local skillName = GetTradeSkillInfo(i)
        if itemLink ~= nil and skillName ~= nil then
            local itemName = GetItemInfo(itemLink)
            list[itemName] = { index = i, skillname = skillName }
        end
    end

    XInfo.tradeSkillList = list
    return true
end

XInfo.getAuctionInfo = function(itemName)
    if XAuctionInfoList ~= nil and XAuctionInfoList[itemName] ~= nil then
        return XAuctionInfoList[itemName]
    end
    return nil
end

XInfo.getAuctionInfoField = function(itemName, fieldName, defaultValue)
    itemName = strtrim(itemName)
    local item = XInfo.getAuctionInfo(itemName)
    if not item then return defaultValue end;

    local fields = { "succrate", "dealcount", "lowestprice", "costprice", "sellprice", "minsellprice", "maxsellprice" }
    if not XInfo.allHistory and XUtils.inArray(fieldName, fields) then
        fieldName = fieldName .. '10'
    end

    if not item[fieldName] then return defaultValue end

    return item[fieldName]
end

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

XInfo.characterList = { '暗影肌', '默法', 'Miles', 'Bro' }
XInfo.myName = UnitName("player")
XInfo.isMe = function(characterName)
    return XUtils.inArray(characterName, XInfo.characterList)
end

XInfo.allHistory = false


XAutoAuction.registerEventCallback('XInfo', 'ADDON_LOADED', function()
    XInfo.reloadBag()
end)
XAutoAuction.registerEventCallback('XInfo', 'BAG_UPDATE', XInfo.reloadBag)

SlashCmdList["XINFOALLHISTORY"] = function()
    XInfo.allHistory = not XInfo.allHistory
end
SLASH_XINFOALLHISTORY1 = "/xallhistory"
