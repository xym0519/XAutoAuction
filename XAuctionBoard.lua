XAuctionBoard = {}
local moduleName = 'XAuctionBoard'

-- Variable definition
local mainFrame = nil
XAuctionBoard = CreateFrame("Frame")

local displayIndex = 1

-- Function definition
local initUI
local refreshUI
local addItem
local getItem
local getItemCount

-- Function implemention
initUI = function()
    mainFrame = XUI.createFrame(moduleName .. 'Frame', 415, 400)
    mainFrame.title:SetText('拍卖纪录')
    mainFrame:SetPoint('CENTER', UIParent, 'CENTER', -50, 0)
    mainFrame:Hide()
    tinsert(UISpecialFrames, mainFrame:GetName())
    XAuctionBoard.mainFrame = mainFrame

    local cleanButton = XUI.createButton(mainFrame, 50, '清除')
    cleanButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -30)
    cleanButton:SetScript("OnClick", function()
        XUIConfirmDialog.show(moduleName, '确认', '确认清除', function()
            XAuctionBoardList = { { starttime = time(), data = {} } }
            displayIndex = 1
            refreshUI()
        end)
    end)

    local refreshButton = XUI.createButton(mainFrame, 50, '刷新')
    refreshButton:SetPoint("LEFT", cleanButton, "RIGHT", 0, 0)
    refreshButton:SetScript("OnClick", function()
        refreshUI()
    end)

    local draftButton = XUI.createButton(mainFrame, 50, '暂存')
    draftButton:SetPoint("LEFT", refreshButton, "RIGHT", 5, 0)
    draftButton:SetScript("OnClick", function()
        XUIConfirmDialog.show(moduleName, '确认', '确认暂存', function()
            if #XAuctionBoardList > 0 then
                XAuctionBoardList[1]['endtime'] = time()
            end
            table.insert(XAuctionBoardList, 1, { starttime = time(), data = {} })
            refreshUI()
        end)
    end)

    local currentButton = XUI.createButton(mainFrame, 50, '当前')
    currentButton:SetPoint("LEFT", draftButton, "RIGHT", 0, 0)
    currentButton:SetScript("OnClick", function()
        displayIndex = 1
        refreshUI()
    end)

    local preButton = XUI.createButton(mainFrame, 50, '上次')
    preButton:SetPoint("LEFT", currentButton, "RIGHT", 0, 0)
    preButton:SetScript("OnClick", function()
        displayIndex = displayIndex + 1
        if displayIndex > #XAuctionBoardList then displayIndex = #XAuctionBoardList end
        refreshUI()
    end)

    local nextButton = XUI.createButton(mainFrame, 50, '下次')
    nextButton:SetPoint("LEFT", preButton, "RIGHT", 5, 0)
    nextButton:SetScript("OnClick", function()
        displayIndex = displayIndex - 1
        if displayIndex < 1 then displayIndex = 1 end
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

    local buyCountLabel = XUI.createLabel(labelFrame, 40, '购买', 'CENTER')
    buyCountLabel:SetPoint('LEFT', craftCountLabel, 'RIGHT', 5, 0)

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
    local totalBuyCount = 0

    local list = {}
    local item = XAuctionBoardList[displayIndex]
    if item then list = item['data'] end
    for _, dataItem in ipairs(list) do
        totalDealCount = totalDealCount + dataItem['dealcount']
        totalCraftCount = totalCraftCount + dataItem['craftcount']
        totalBuyCount = totalBuyCount + dataItem['buycount']
        local targetName = XInfo.getMaterialName(dataItem['itemname'])
        if targetName == nil then
            targetName = dataItem['itemname']
        end
        local tItem = itemMap[targetName]
        if tItem == nil then
            tItem = {
                itemname = targetName,
                dealcount = dataItem['dealcount'],
                craftcount = dataItem['craftcount'],
                buycount = dataItem['buycount']
            }
            itemMap[targetName] = tItem
            table.insert(itemList, tItem)
        else
            tItem['dealcount'] = tItem['dealcount'] + dataItem['dealcount']
            tItem['craftcount'] = tItem['craftcount'] + dataItem['craftcount']
            tItem['buycount'] = tItem['buycount'] + dataItem['buycount']
        end
    end

    table.sort(itemList, function(a, b)
        if a['dealcount'] == b['dealcount'] then
            return a['craftcount'] > b['craftcount']
        else
            return a['dealcount'] > b['dealcount']
        end
    end)
    table.insert(itemList, { itemname = XUI.Green .. '----------', dealcount = 0, craftcount = 0, buycount = 0 })

    local startTimeStr = '-'
    if item['starttime'] then startTimeStr = XUtils.formatTime(item['starttime']) end
    local endTimeStr = '-'
    if item['endtime'] then endTimeStr = XUtils.formatTime(item['endtime']) end
    mainFrame.title:SetText('拍卖记录(' .. startTimeStr
        .. '~' .. endTimeStr .. ')'
        .. '  卖: ' .. totalDealCount
        .. '  造: ' .. totalCraftCount
        .. '  买: ' .. totalBuyCount)

    for _, dataItem in ipairs(list) do
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

        local dealCountStr = XUI.getColor_DealCount(dataItem['dealcount'] * 3) .. dataItem['dealcount']
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

        local buyCountStr = dataItem['buycount']
        if dataItem['buycount'] > 100 then
            buyCountStr = XUI.Color_Great .. buyCountStr
        elseif dataItem['buycount'] > 60 then
            buyCountStr = XUI.Color_Good .. buyCountStr
        elseif dataItem['buycount'] > 20 then
            buyCountStr = XUI.Color_Fair .. buyCountStr
        else
            buyCountStr = XUI.Color_Normal .. buyCountStr
        end
        local buyCountLabel = XUI.createLabel(frame, 40, buyCountStr, 'CENTER')
        buyCountLabel:SetPoint('LEFT', craftCountLabel, 'RIGHT', 5, 0)
    end
end

-- type: deal / craft / buy
addItem = function(itemName, type, count)
    if count == nil then count = 1 end

    local existed = false

    if #XAuctionBoardList < 1 then
        table.insert(XAuctionBoardList, 1, { starttime = time(), data = {} })
    end

    local list = XAuctionBoardList[1]['data']

    for _, item in ipairs(list) do
        if item['itemname'] == itemName then
            if type == 'deal' then
                item['dealcount'] = item['dealcount'] + count
            elseif type == 'craft' then
                item['craftcount'] = item['craftcount'] + count
            elseif type == 'buy' then
                item['buycount'] = item['buycount'] + count
            end
            existed = true
            break
        end
    end

    if not existed then
        if type == 'deal' then
            table.insert(list, { itemname = itemName, dealcount = count, craftcount = 0, buycount = 0 })
        elseif type == 'craft' then
            table.insert(list, { itemname = itemName, dealcount = 0, craftcount = count, buycount = 0 })
        elseif type == 'buy' then
            table.insert(list, { itemname = itemName, dealcount = 0, craftcount = 0, buycount = count })
        end
    end

    table.sort(list, function(a, b)
        if a['dealcount'] == b['dealcount'] then
            return a['craftcount'] > b['craftcount']
        else
            return a['dealcount'] > b['dealcount']
        end
    end)

    if type == 'deal' then
        local item = XInfo.getItemInfo(itemName)
        if item then
            item['dealcount'] = item['dealcount'] + count
        end
    end
    refreshUI()
end

getItem = function(itemName)
    if #XAuctionBoardList < 1 then
        return nil
    end

    local list = XAuctionBoardList[1]['data']
    for _, item in ipairs(list) do
        if item['itemname'] == itemName then
            return item
        end
    end

    return nil
end

getItemCount = function(itemName, type)
    if type == nil then type = 'dealcount' end
    local item = getItem(itemName)
    if item then
        local count = item[type]
        if not count then count = 0 end
        return count
    end
    return 0
end


-- Events
XJewTool.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initUI()
    refreshUI()
end)

XJewTool.registerEventCallback(moduleName, 'CHAT_MSG_SYSTEM', function(self, event, text, context)
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
XAuctionBoard.getItem = getItem
XAuctionBoard.getItemCount = getItemCount
XAuctionBoard.toggle = function() XUI.toggleVisible(mainFrame) end
