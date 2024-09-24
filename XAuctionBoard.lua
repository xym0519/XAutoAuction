XAuctionBoard = {}
local moduleName = 'XAuctionBoard'

-- Variable definition
local mainFrame = nil
XAuctionBoard = CreateFrame("Frame")

-- Function definition
local initUI
local refreshUI
local addItem

-- Function implemention
initUI = function()
    mainFrame = XUI.createFrame(moduleName .. 'Frame', 370, 400)
    mainFrame.title:SetText('拍卖纪录')
    mainFrame:SetPoint('CENTER', UIParent, 'CENTER', -50, 0)
    mainFrame:Hide()
    tinsert(UISpecialFrames, mainFrame:GetName())
    XAuctionBoard.mainFrame = mainFrame

    local cleanButton = XUI.createButton(mainFrame, 60, '清除')
    cleanButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -30)
    cleanButton:SetScript("OnClick", function()
        XUIConfirmDialog.show(moduleName, '确认', '确认清除', function()
            XAuctionBoardList = {}
            refreshUI()
        end)
    end)

    local refreshButton = XUI.createButton(mainFrame, 60, '刷新')
    refreshButton:SetPoint("LEFT", cleanButton, "RIGHT", 5, 0)
    refreshButton:SetScript("OnClick", function()
        refreshUI()
    end)

    local labelFrame = XAPI.CreateFrame('Frame', nil, mainFrame)
    labelFrame:SetSize(mainFrame:GetWidth() - 20, 30)
    labelFrame:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 10, -60)

    local indexLabel = XUI.createLabel(labelFrame, 40, '序号', 'CENTER')
    indexLabel:SetPoint('LEFT', labelFrame, 'LEFT', 8, 0)

    local nameLabel = XUI.createLabel(labelFrame, 140, '名称', 'CENTER')
    nameLabel:SetPoint('LEFT', indexLabel, 'RIGHT', 35, 0)

    local dealCountLabel = XUI.createLabel(labelFrame, 40, '交易', 'CENTER')
    dealCountLabel:SetPoint('LEFT', nameLabel, 'RIGHT', 5, 0)

    local craftCountLabel = XUI.createLabel(labelFrame, 40, '制造', 'CENTER')
    craftCountLabel:SetPoint('LEFT', dealCountLabel, 'RIGHT', 5, 0)

    local scrollView = XUI.createScrollView(mainFrame, mainFrame:GetWidth() - 20,
        mainFrame:GetHeight() - labelFrame:GetHeight() - 70)
    scrollView:SetPoint('TOPLEFT', labelFrame, 'BottomLeft', 0, 0)
    mainFrame.scrollView = scrollView
end

refreshUI = function()
    if not mainFrame then return end

    local scrollView = mainFrame.scrollView
    scrollView:ClearContents()

    local itemMap = {};
    local itemList = {}
    local totalDealCount = 0
    local totalCraftCount = 0
    for _, dataItem in ipairs(XAuctionBoardList) do
        totalDealCount = totalDealCount + dataItem['dealcount']
        totalCraftCount = totalCraftCount + dataItem['craftcount']
        local materialName = XInfo.getMaterialName(dataItem['itemname'])
        if materialName ~= nil then
            local tItem = itemMap[materialName]
            if tItem == nil then
                tItem = {
                    itemname = materialName,
                    dealcount = dataItem['dealcount'],
                    craftcount = dataItem['craftcount']
                }
                itemMap[materialName] = tItem
                table.insert(itemList, tItem)
            else
                tItem['dealcount'] = tItem['dealcount'] + dataItem['dealcount']
                tItem['craftcount'] = tItem['craftcount'] + dataItem['craftcount']
            end
        end
    end

    table.sort(itemList, function(a, b)
        if a['dealcount'] == b['dealcount'] then
            return a['craftcount'] > b['craftcount']
        else
            return a['dealcount'] > b['dealcount']
        end
    end)
    table.insert(itemList, { itemname = XUI.Green .. '----------', dealcount = 0, craftcount = 0 })

    mainFrame.title:SetText('拍卖记录'
        .. '    成交: ' .. totalDealCount
        .. '    制造: ' .. totalCraftCount)

    for _, dataItem in ipairs(XAuctionBoardList) do
        table.insert(itemList, dataItem)
    end

    for i, dataItem in ipairs(itemList) do
        local frame = scrollView:CreateFrame(mainFrame:GetWidth() - 20, 30)
        local indexLabel = XUI.createLabel(frame, 40, i, 'CENTER')
        indexLabel:SetPoint('LEFT', frame, 'LEFT', 5, 0)

        local icon = XUI.createItemIcon(frame, 25, 25, dataItem['itemname'])
        icon:SetPoint('LEFT', indexLabel, 'RIGHT', 5, 0)

        local nameLabel = XUI.createLabel(frame, 140, dataItem['itemname'], 'CENTER')
        nameLabel:SetPoint('LEFT', icon, 'RIGHT', 5, 0)
        nameLabel:SetScript("OnEnter", function(self)
            local titemName = self.itemName
            local itemId = XInfo.getItemId(titemName)
            if itemId > 0 then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("item:" .. itemId) -- 显示物品信息
            end
        end)
        nameLabel:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        nameLabel.itemName = dataItem['itemname']

        local dealCountStr = dataItem['dealcount'] .. ''
        if dataItem['dealcount'] >= 40 then
            dealCountStr = XUI.Color_Great .. dealCountStr
        elseif dataItem['dealcount'] >= 20 then
            dealCountStr = XUI.Color_Good .. dealCountStr
        elseif dataItem['dealcount'] >= 0 then
            dealCountStr = XUI.Color_Fair .. dealCountStr
        else
            dealCountStr = XUI.Color_Bad .. dealCountStr
        end
        local dealCountLabel = XUI.createLabel(frame, 40, dealCountStr, 'CENTER')
        dealCountLabel:SetPoint('LEFT', nameLabel, 'RIGHT', 5, 0)

        local craftCountStr = dataItem['craftcount'] .. ''
        if dataItem['craftcount'] >= dataItem['dealcount'] * 3 then
            craftCountStr = XUI.Color_Worst .. craftCountStr
        elseif dataItem['craftcount'] >= dataItem['dealcount'] * 2 then
            craftCountStr = XUI.Color_Bad .. craftCountStr
        elseif dataItem['craftcount'] >= dataItem['dealcount'] * 1.5 then
            craftCountStr = XUI.Color_Good .. craftCountStr
        else
            craftCountStr = XUI.Color_Great .. craftCountStr
        end
        local craftCountLabel = XUI.createLabel(frame, 40, craftCountStr, 'CENTER')
        craftCountLabel:SetPoint('LEFT', dealCountLabel, 'RIGHT', 5, 0)
    end
end

-- type: deal / craft
addItem = function(itemName, type, count)
    if count == nil then count = 1 end

    local existed = false

    for _, item in ipairs(XAuctionBoardList) do
        if item['itemname'] == itemName then
            if type == 'deal' then
                item['dealcount'] = item['dealcount'] + count
            elseif type == 'craft' then
                item['craftcount'] = item['craftcount'] + count
            end
            existed = true
            break
        end
    end

    if not existed then
        if type == 'deal' then
            table.insert(XAuctionBoardList, { itemname = itemName, dealcount = count, craftcount = 0 })
        elseif type == 'craft' then
            table.insert(XAuctionBoardList, { itemname = itemName, dealcount = 0, craftcount = count })
        end
    end

    table.sort(XAuctionBoardList, function(a, b)
        if a['dealcount'] == b['dealcount'] then
            return a['craftcount'] > b['craftcount']
        else
            return a['dealcount'] > b['dealcount']
        end
    end)

    refreshUI()
end

-- Event callback


-- Events
XAutoAuction.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initUI()
    refreshUI()
end)

XAutoAuction.registerEventCallback(moduleName, 'CHAT_MSG_SYSTEM', function(self, event, text, context)
    if XUtils.stringStartsWith(text, '你拍卖的') and XUtils.stringEndsWith(text, '已经售出。') then
        local itemName = string.sub(text, string.len('你拍卖的') + 1, string.len(text) - string.len('已经售出。'))
        addItem(itemName, 'deal')
        refreshUI()
    end
end)

-- Commands
SlashCmdList["XAUCTIONBOARD"] = function()
    XUI.toggleVisible(mainFrame)
end
SLASH_XAUCTIONBOARD1 = "/xauctionboard"

SlashCmdList['XAUCTIONBOARDSHOW'] = function()
    if mainFrame then mainFrame:Show() end
end
SLASH_XAUCTIONBOARDSHOW1 = '/xauctionboard_show'

SlashCmdList['XAUCTIONBOARDHIDE'] = function()
    if mainFrame then mainFrame:Hide() end
end
SLASH_XAUCTIONBOARDHIDE1 = '/xauctionboard_hide'

-- Interface
XAuctionBoard.addItem = addItem
XAuctionBoard.toggle = function() XUI.toggleVisible(mainFrame) end
