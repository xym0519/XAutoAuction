XAuctionHistory = {}
local moduleName = 'XAuctionHistory'

-- Variable definition
local mainFrame = nil
local dealList = {}
local displayPageNo = 0
local displayFrameList = {}
local displayPageSize = 10

-- Function definition
local initUI
local refreshUI
local addItem

-- Function implemention
initUI = function()
    mainFrame = XUI.createFrame('XAuctionHistoryMainFrame', 320, 430)
    mainFrame.title:SetText('拍卖记录BTMAD')
    mainFrame:SetPoint('RIGHT', UIParent, 'RIGHT', -40, 0)
    mainFrame:Hide()

    local preButton = XUI.createButton(mainFrame, 45, '上')
    preButton:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 15, -30)
    preButton:SetScript('OnClick', function()
        if displayPageNo > 0 then
            displayPageNo = displayPageNo - 1
            refreshUI()
        end
    end)

    local nextButton = XUI.createButton(mainFrame, 45, '下')
    nextButton:SetPoint('LEFT', preButton, 'RIGHT', 5, 0)
    nextButton:SetScript('OnClick', function()
        if displayPageNo < math.ceil(#dealList / displayPageSize) - 1 then
            displayPageNo = displayPageNo + 1
            refreshUI()
        end
    end)

    local cleanButton = XUI.createButton(mainFrame, 45, '清')
    cleanButton:SetPoint('LEFT', nextButton, 'RIGHT', 5, 0)
    cleanButton:SetScript('OnClick', function()
        dealList = {}
        displayPageNo = 0
        refreshUI()
    end)

    local refreshButton = XUI.createButton(mainFrame, 45, '刷')
    refreshButton:SetPoint('LEFT', cleanButton, 'RIGHT', 5, 0)
    refreshButton:SetScript('OnClick', function()
        XAutoAuction.refreshUI()
    end)

    local lastWidget = preButton
    for i = 1, displayPageSize do
        local frame = CreateFrame('Frame', nil, mainFrame)
        frame:SetSize(mainFrame:GetWidth(), 30)

        if i == 1 then
            frame:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 0, -65)
        else
            frame:SetPoint('TOPLEFT', lastWidget, 'BOTTOMLEFT', 0, -5)
        end

        frame:Hide()

        local nameLabel = XUI.createLabel(frame, 105, '')
        nameLabel:SetPoint('LEFT', frame, 'LEFT', 15, 0)
        frame.nameLabel = nameLabel

        local infoButton = XUI.createButton(frame, 95, '')
        infoButton:SetPoint('LEFT', nameLabel, 'RIGHT', 3, 0)
        infoButton:SetScript('OnClick', function()
            refreshUI()

            local idx = displayPageNo * displayPageSize + i
            local item = dealList[idx];
            if not item then return end
            local count = 1
            local autoAuctionItem = XAuctionCenter.getAuctionItem(item['itemname'])
            if autoAuctionItem then
                count = autoAuctionItem['stackcount']
            end

            XUIInputDialog.show('XAuctionBoard_Craft', function(data)
                local itemName = nil
                local count = nil
                for _, item in ipairs(data) do
                    if item.Name == '类型' then itemName = item.Value end
                    if item.Name == '数量' then count = tonumber(item.Value) end
                end
                if itemName and count then
                    XCraftQueue.addItem(itemName, count, 'fulfil')
                end
            end, { { Name = '类型', Value = item['itemname'] }, { Name = '数量', Value = count } }, item['itemname'])
        end)
        frame.infoButton = infoButton

        local printButton = XUI.createButton(frame, 30, 'E')
        printButton:SetPoint('LEFT', infoButton, 'RIGHT', 1, 0)
        printButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            local item = dealList[idx];
            if not item then return end
            local autoAuctionItem = XAuctionCenter.getAuctionItem(item['itemname'])
            if autoAuctionItem then
                xdebug.info(item['itemname'] .. ': ' .. XUtils.priceToMoneyString(autoAuctionItem['minprice']))
            end
        end)

        local deleteButton = XUI.createButton(frame, 30, 'D')
        deleteButton:SetPoint('LEFT', printButton, 'RIGHT', 1, 0)
        deleteButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            if idx <= #dealList then
                table.remove(dealList, idx)
                refreshUI()
            end
        end)

        local auctionButton = XUI.createButton(frame, 30, 'A')
        auctionButton:SetPoint('LEFT', deleteButton, 'RIGHT', 3, 0)
        auctionButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            if idx <= #dealList then
                XAuctionCenter.addQueryTaskByItemName(dealList[idx]['itemname'])
            end
        end)

        table.insert(displayFrameList, frame)
        lastWidget = frame
    end

    refreshUI()
end

refreshUI = function()
    if not mainFrame then return end

    mainFrame.title:SetText('拍卖记录BTMAD (' ..
        (displayPageNo + 1) ..
        '/' .. (math.ceil(#dealList / displayPageSize)) .. ')')

    XInfo.reloadBag()
    XInfo.reloadAuction()

    for i = 1, displayPageSize do
        local frame = displayFrameList[i]
        if displayPageNo * displayPageSize + i <= #dealList then
            local item = dealList[displayPageNo * displayPageSize + i];

            local stackCount = 0
            local autoAuctionItem = XAuctionCenter.getAuctionItem(item['itemname'])
            if autoAuctionItem then
                stackCount = autoAuctionItem['stackcount']
            end
            local bagCount = 0
            local totalCount = 0
            local bagItem = XInfo.getBagItem(item['itemname'])
            if bagItem then
                bagCount = bagItem['count']
                totalCount = bagItem['totalcount']
            end
            local bagCountStr = XUI.getColor_BagStackCount(bagCount, stackCount) .. XUtils.formatCount(bagCount, 1)

            local totalCountStr = XUI.getColor_BagStackCount(totalCount, stackCount) .. XUtils.formatCount(totalCount, 1)

            local materialCount = 0
            local materialBagItem = XInfo.getMaterialBagItem(item['itemname'])
            if materialBagItem then
                materialCount = materialBagItem['totalcount']
            end
            local materialCountStr = XUtils.formatCount2(materialCount)

            local auctionCount = 0;
            local auctionItem = XInfo.getAuctionItem(item['itemname'])
            if auctionItem then
                auctionCount = auctionItem['count']
            end
            local auctionCountStr = XUI.getColor_AuctionStackCount(auctionCount, stackCount) ..
                XUtils.formatCount(auctionCount, 1)

            local dealCountStr = XUI.White .. XUtils.formatCount(item['count'], 1)

            frame.nameLabel:SetText(string.sub(item['itemname'], 1, 18))
            frame.infoButton:SetText(
                bagCountStr ..
                XUI.White .. '/' ..
                totalCountStr ..
                XUI.White .. '/' ..
                materialCountStr ..
                XUI.White .. '/' ..
                auctionCountStr ..
                XUI.White .. '/' ..
                dealCountStr)
            frame:Show()
        else
            frame:Hide()
        end
    end
end

addItem = function(itemName)
    local existed = false

    for _, item in ipairs(dealList) do
        if item['itemname'] == itemName then
            item['count'] = item['count'] + 1
            existed = true
            break
        end
    end

    if not existed then
        dealList[#dealList + 1] = { itemname = itemName, count = 1 }
    end

    refreshUI()
end

-- Event
XAutoAuction.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initUI()
    refreshUI()
end)

XAutoAuction.registerEventCallback(moduleName, 'CHAT_MSG_SYSTEM', function(...)
    -- TODO 111
    local text = select(3, ...)
    if XUtils.stringStartsWith(text, '你拍卖的') and XUtils.stringEndsWith(text, '已经售出。') then
        local str = string.sub(text, string.len('你拍卖的') + 1, string.len(text) - string.len('已经售出。'))
        addItem(str)
        refreshUI()
    end
end)

-- XAutoAuction.registerEventCallback(moduleName, 'AUCTION_HOUSE_SHOW', function(self, event, text, context)
--     if mainFrame then mainFrame:Show() end
-- end)

XAutoAuction.registerEventCallback(moduleName, 'AUCTION_HOUSE_CLOSED', function()
    if mainFrame then mainFrame:Hide() end
end)

XAutoAuction.registerRefreshCallback(moduleName, refreshUI)

-- Command
SlashCmdList['XAUCTIONHISTORY'] = function()
    XUI.toggleVisible(mainFrame)
end
SLASH_XAUCTIONHISTORY1 = '/xauctionhistory'

SlashCmdList['XAUCTIONHISTORYSHOW'] = function()
    if mainFrame then mainFrame:Show() end
end
SLASH_XAUCTIONHISTORYSHOW1 = '/xauctionhistory_show'

SlashCmdList['XAUCTIONHISTORYHIDE'] = function()
    if mainFrame then mainFrame:Hide() end
end
SLASH_XAUCTIONHISTORYHIDE1 = '/xauctionhistory_close'

-- Interface
XAuctionHistory.addItem = addItem
