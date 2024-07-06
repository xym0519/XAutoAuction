XJewCount = CreateFrame("Frame")

local mainFrame = nil
local prLabel = nil
local poLabel = nil
local pyLabel = nil
local pgLabel = nil
local pbLabel = nil
local ppLabel = nil
local brLabel = nil
local boLabel = nil
local byLabel = nil
local bgLabel = nil
local bbLabel = nil
local bpLabel = nil

local function getItemInfo(itemName)
    local bagCount = 0
    local totalCount = 0
    local item = XInfo.getBagItem(itemName)
    if item then
        bagCount = item['count']
        totalCount = item['totalcount']
    end

    if itemName == '赤玉石' or itemName == '血玉石' then
        itemName = string.sub(itemName, 1, 3)
    elseif itemName == '紫黄晶' or itemName == '帝黄晶' then
        itemName = string.sub(itemName, 1, 3)
    elseif itemName == '王者琥珀' or itemName == '秋色石' then
        itemName = string.sub(itemName, 1, 3)
    elseif itemName == '祖尔之眼' or itemName == '森林翡翠' then
        itemName = string.sub(itemName, 1, 3)
    elseif itemName == '巨锆石' or itemName == '天蓝石' then
        itemName = string.sub(itemName, 1, 3)
    elseif itemName == '恐惧石' or itemName == '曙光猫眼石' then
        itemName = string.sub(itemName, 1, 3)
    end

    local bagCountStr = bagCount
    if bagCount >= 40 then
        bagCountStr = '|cFF00FFFF' .. bagCountStr
    elseif bagCount >= 20 then
        bagCountStr = '|cFF00FF00' .. bagCountStr
    elseif bagCount >= 10 then
        bagCountStr = '|cFFFFFF00' .. bagCountStr
    else
        bagCountStr = '|cFFFF0000' .. bagCountStr
    end

    local totalCountStr = totalCount
    if totalCount >= 100 then
        totalCountStr = '|cFF00FFFF' .. totalCountStr
    elseif totalCount >= 60 then
        totalCountStr = '|cFF00FF00' .. totalCountStr
    elseif totalCount >= 40 then
        totalCountStr = '|cFFFFFF00' .. totalCountStr
    else
        totalCountStr = '|cFFFF0000' .. totalCountStr
    end

    return itemName .. '： ' .. bagCountStr .. '|cFFFFFFFF / ' .. totalCountStr
end

XJewCount.refreshUI = function()
    if not mainFrame then return end

    XInfo.reloadBag()

    prLabel:SetText(getItemInfo('赤玉石'))
    poLabel:SetText(getItemInfo('紫黄晶'))
    pyLabel:SetText(getItemInfo('王者琥珀'))
    pgLabel:SetText(getItemInfo('祖尔之眼'))
    pbLabel:SetText(getItemInfo('巨锆石'))
    ppLabel:SetText(getItemInfo('恐惧石'))

    brLabel:SetText(getItemInfo('血玉石'))
    boLabel:SetText(getItemInfo('帝黄晶'))
    byLabel:SetText(getItemInfo('秋色石'))
    bgLabel:SetText(getItemInfo('森林翡翠'))
    bbLabel:SetText(getItemInfo('天蓝石'))
    bpLabel:SetText(getItemInfo('曙光猫眼石'))
end

local function initUI()
    mainFrame = XUI.createFrame("XJewCount", 280, 150)
    mainFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 60)
    mainFrame:Hide()
    XJewCount.mainFrame = mainFrame

    prLabel = XUI.createLabel(mainFrame, 120, '')
    prLabel:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -25)

    poLabel = XUI.createLabel(mainFrame, 120, '')
    poLabel:SetPoint("TOPLEFT", prLabel, "BOTTOMLEFT", 0, 7)

    pyLabel = XUI.createLabel(mainFrame, 120, '')
    pyLabel:SetPoint("TOPLEFT", poLabel, "BOTTOMLEFT", 0, 7)

    pgLabel = XUI.createLabel(mainFrame, 120, '')
    pgLabel:SetPoint("TOPLEFT", pyLabel, "BOTTOMLEFT", 0, 7)

    pbLabel = XUI.createLabel(mainFrame, 120, '')
    pbLabel:SetPoint("TOPLEFT", pgLabel, "BOTTOMLEFT", 0, 7)

    ppLabel = XUI.createLabel(mainFrame, 120, '')
    ppLabel:SetPoint("TOPLEFT", pbLabel, "BOTTOMLEFT", 0, 7)

    brLabel = XUI.createLabel(mainFrame, 120, '')
    brLabel:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 150, -25)

    boLabel = XUI.createLabel(mainFrame, 120, '')
    boLabel:SetPoint("TOPLEFT", brLabel, "BOTTOMLEFT", 0, 7)

    byLabel = XUI.createLabel(mainFrame, 120, '')
    byLabel:SetPoint("TOPLEFT", boLabel, "BOTTOMLEFT", 0, 7)

    bgLabel = XUI.createLabel(mainFrame, 120, '')
    bgLabel:SetPoint("TOPLEFT", byLabel, "BOTTOMLEFT", 0, 7)

    bbLabel = XUI.createLabel(mainFrame, 120, '')
    bbLabel:SetPoint("TOPLEFT", bgLabel, "BOTTOMLEFT", 0, 7)

    bpLabel = XUI.createLabel(mainFrame, 120, '')
    bpLabel:SetPoint("TOPLEFT", bbLabel, "BOTTOMLEFT", 0, 7)

    XJewCount.refreshUI()
end

XAutoAuction.registerEventCallback('XJewCount', 'ADDON_LOADED', function()
    initUI()
    XJewCount.refreshUI()
end)

XAutoAuction.registerEventCallback('XJewCount', 'AUCTION_HOUSE_SHOW', function()
    if mainFrame then mainFrame:Show() end
end)

XAutoAuction.registerEventCallback('XJewCount', 'AUCTION_HOUSE_CLOSED', function()
    if mainFrame then mainFrame:Hide() end
end)

SlashCmdList["XJEWCOUNT"] = function()
    if mainFrame then
        if mainFrame:IsVisible() then
            mainFrame:Hide()
        else
            mainFrame:Show()
        end
    end
end
SLASH_XJEWCOUNT1 = "/xjewcount"
