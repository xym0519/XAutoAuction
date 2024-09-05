XJewCount = {}
local moduleName = 'XJewCount'

-- Variable definition
local mainFrame = nil
local labels = {}
local initUI
local refreshUI
local createLabel

-- Function implemention
createLabel = function(itemName)
    local label = XUI.createLabel(mainFrame, 120)
    label.itemName = itemName
    label:SetHeight(18)
    label:SetScript("OnEnter", function(self)
        local titemName = self.itemName
        local itemId = XInfo.getAuctionInfoField(titemName, 'itemid')
        if itemId > 0 then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. itemId) -- 显示物品信息
        end
    end)
    label:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    label.Refresh = function(self)
        local titemName = self.itemName
        local bagCount = XInfo.getBagItemCount(titemName)
        local totalCount = XInfo.getItemTotalCount(titemName)

        titemName = string.sub(titemName, 1, 3)

        local bagCountStr = XUI.getColor_BagCount(bagCount) .. bagCount

        local totalCountStr = XUI.getColor_TotalCount(totalCount) .. totalCount

        local content = titemName .. '： ' .. bagCountStr .. XUI.White .. ' / ' .. totalCountStr
        self:SetText(content)
    end
    return label
end

initUI = function()
    mainFrame = XUI.createFrame('XJewCountMainFrame', 270, 170)
    mainFrame.title:SetText('原石数量')
    mainFrame:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 60)
    mainFrame:Hide()
    tinsert(UISpecialFrames, mainFrame:GetName())

    local fulfilStackButton = XUI.createButton(mainFrame, 25, 'V')
    fulfilStackButton:SetHeight(20)
    fulfilStackButton:SetPoint('TOPRIGHT', mainFrame, 'TOPRIGHT', -30, -1)
    fulfilStackButton:SetScript('OnClick', function()
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
                    local stackCount = 20
                    if XUtils.inArray(itemName, XInfo.materialList) then
                        if count < stackCount then
                            local subCount = stackCount - count
                            for x = -1, XAPI.NUM_BAG_SLOTS + XAPI.NUM_BANKBAGSLOTS do
                                if count < stackCount then
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
                                                    if count >= stackCount then
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
        xdebug.info('补充完成')
    end)

    local prLabel = createLabel('赤玉石')
    prLabel:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 20, -30)
    table.insert(labels, prLabel)

    local poLabel = createLabel('紫黄晶')
    poLabel:SetPoint('TOPLEFT', prLabel, 'BOTTOMLEFT', 0, 0)
    table.insert(labels, poLabel)

    local pyLabel = createLabel('王者琥珀')
    pyLabel:SetPoint('TOPLEFT', poLabel, 'BOTTOMLEFT', 0, 0)
    table.insert(labels, pyLabel)

    local pgLabel = createLabel('祖尔之眼')
    pgLabel:SetPoint('TOPLEFT', pyLabel, 'BOTTOMLEFT', 0, 0)
    table.insert(labels, pgLabel)

    local pbLabel = createLabel('巨锆石')
    pbLabel:SetPoint('TOPLEFT', pgLabel, 'BOTTOMLEFT', 0, 0)
    table.insert(labels, pbLabel)

    local ppLabel = createLabel('恐惧石')
    ppLabel:SetPoint('TOPLEFT', pbLabel, 'BOTTOMLEFT', 0, 0)
    table.insert(labels, ppLabel)

    local brLabel = createLabel('血玉石')
    brLabel:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 140, -30)
    table.insert(labels, brLabel)

    local boLabel = createLabel('帝黄晶')
    boLabel:SetPoint('TOPLEFT', brLabel, 'BOTTOMLEFT', 0, 0)
    table.insert(labels, boLabel)

    local byLabel = createLabel('秋色石')
    byLabel:SetPoint('TOPLEFT', boLabel, 'BOTTOMLEFT', 0, 0)
    table.insert(labels, byLabel)

    local bgLabel = createLabel('森林翡翠')
    bgLabel:SetPoint('TOPLEFT', byLabel, 'BOTTOMLEFT', 0, 0)
    table.insert(labels, bgLabel)

    local bbLabel = createLabel('天蓝石')
    bbLabel:SetPoint('TOPLEFT', bgLabel, 'BOTTOMLEFT', 0, 0)
    table.insert(labels, bbLabel)

    local bpLabel = createLabel('曙光猫眼石')
    bpLabel:SetPoint('TOPLEFT', bbLabel, 'BOTTOMLEFT', 0, 0)
    table.insert(labels, bpLabel)


    local tyLabel = createLabel('天焰钻石')
    tyLabel:SetPoint('TOPLEFT', ppLabel, 'BOTTOMLEFT', 0, 0)
    table.insert(labels, tyLabel)

    local ddLabel = createLabel('大地侵攻钻石')
    ddLabel:SetPoint('TOPLEFT', bpLabel, 'BOTTOMLEFT', 0, 0)
    table.insert(labels, ddLabel)

    refreshUI()
end

refreshUI = function()
    if not mainFrame then return end
    if not mainFrame:IsVisible() then return end

    XInfo.reloadBag()

    for _, label in ipairs(labels) do
        label:Refresh()
    end
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
