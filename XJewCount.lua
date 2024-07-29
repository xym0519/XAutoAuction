XJewCount = {}
local moduleName = 'XJewCount'

-- Variable definition
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

local tyLabel = nil
local ddLabel = nil

-- Function definition
local initUI
local refreshUI
local createLabel
local getItemInfo

-- Function implemention
createLabel = function()
    local label = XUI.createLabel(mainFrame, 120)
    label:SetHeight(18)
    return label
end

initUI = function()
    mainFrame = XUI.createFrame('XJewCountMainFrame', 270, 170)
    mainFrame.title:SetText('原石数量')
    mainFrame:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 60)
    mainFrame:Hide()

    prLabel = createLabel()
    prLabel:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 20, -30)

    poLabel = createLabel()
    poLabel:SetPoint('TOPLEFT', prLabel, 'BOTTOMLEFT', 0, 0)

    pyLabel = createLabel()
    pyLabel:SetPoint('TOPLEFT', poLabel, 'BOTTOMLEFT', 0, 0)

    pgLabel = createLabel()
    pgLabel:SetPoint('TOPLEFT', pyLabel, 'BOTTOMLEFT', 0, 0)

    pbLabel = createLabel()
    pbLabel:SetPoint('TOPLEFT', pgLabel, 'BOTTOMLEFT', 0, 0)

    ppLabel = createLabel()
    ppLabel:SetPoint('TOPLEFT', pbLabel, 'BOTTOMLEFT', 0, 0)

    brLabel = createLabel()
    brLabel:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 140, -30)

    boLabel = createLabel()
    boLabel:SetPoint('TOPLEFT', brLabel, 'BOTTOMLEFT', 0, 0)

    byLabel = createLabel()
    byLabel:SetPoint('TOPLEFT', boLabel, 'BOTTOMLEFT', 0, 0)

    bgLabel = createLabel()
    bgLabel:SetPoint('TOPLEFT', byLabel, 'BOTTOMLEFT', 0, 0)

    bbLabel = createLabel()
    bbLabel:SetPoint('TOPLEFT', bgLabel, 'BOTTOMLEFT', 0, 0)

    bpLabel = createLabel()
    bpLabel:SetPoint('TOPLEFT', bbLabel, 'BOTTOMLEFT', 0, 0)


    tyLabel = createLabel()
    tyLabel:SetPoint('TOPLEFT', ppLabel, 'BOTTOMLEFT', 0, 0)

    ddLabel = createLabel()
    ddLabel:SetPoint('TOPLEFT', bpLabel, 'BOTTOMLEFT', 0, 0)

    refreshUI()
end

refreshUI = function()
    if not mainFrame then return end
    XInfo.reloadBag()

    if not prLabel then return end
    prLabel:SetText(getItemInfo('赤玉石'))
    if not poLabel then return end
    poLabel:SetText(getItemInfo('紫黄晶'))
    if not pyLabel then return end
    pyLabel:SetText(getItemInfo('王者琥珀'))
    if not pgLabel then return end
    pgLabel:SetText(getItemInfo('祖尔之眼'))
    if not pbLabel then return end
    pbLabel:SetText(getItemInfo('巨锆石'))
    if not ppLabel then return end
    ppLabel:SetText(getItemInfo('恐惧石'))

    if not brLabel then return end
    brLabel:SetText(getItemInfo('血玉石'))
    if not boLabel then return end
    boLabel:SetText(getItemInfo('帝黄晶'))
    if not byLabel then return end
    byLabel:SetText(getItemInfo('秋色石'))
    if not bgLabel then return end
    bgLabel:SetText(getItemInfo('森林翡翠'))
    if not bbLabel then return end
    bbLabel:SetText(getItemInfo('天蓝石'))
    if not bpLabel then return end
    bpLabel:SetText(getItemInfo('曙光猫眼石'))
    
    if not tyLabel then return end
    tyLabel:SetText(getItemInfo('天焰钻石'))
    if not ddLabel then return end
    ddLabel:SetText(getItemInfo('大地侵攻钻石'))
end

getItemInfo = function(itemName)
    local bagCount = 0
    local totalCount = 0
    local item = XInfo.getBagItem(itemName)
    if item then
        bagCount = item['count']
        totalCount = item['totalcount']
    end

    itemName = string.sub(itemName, 1, 3)

    local bagCountStr = XUI.getColor_BagCount(bagCount) .. bagCount

    local totalCountStr = XUI.getColor_BagBankCount(totalCount) .. totalCount

    return itemName .. '： ' .. bagCountStr .. XUI.White .. ' / ' .. totalCountStr
end

-- Events
XAutoAuction.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initUI()
    refreshUI()
end)

-- XAutoAuction.registerEventCallback(moduleName, 'AUCTION_HOUSE_SHOW', function()
--     if mainFrame then mainFrame:Show() end
-- end)

XAutoAuction.registerEventCallback(moduleName, 'AUCTION_HOUSE_CLOSED', function()
    if mainFrame then mainFrame:Hide() end
end)

XAutoAuction.registerRefreshCallback(moduleName, refreshUI)

-- Commands
SlashCmdList['XJEWCOUNT'] = function()
    XUI.toggleVisible(mainFrame)
end
SLASH_XJEWCOUNT1 = '/xjewcount'

SlashCmdList['XJEWCOUNTSHOW'] = function()
    if mainFrame then mainFrame:Show() end
end
SLASH_XJEWCOUNTSHOW1 = '/xjewcount_show'

SlashCmdList['XJEWCOUNTCLOSE'] = function()
    if mainFrame then mainFrame:Hide() end
end
SLASH_XJEWCOUNTCLOSE1 = '/xjewcount_close'
