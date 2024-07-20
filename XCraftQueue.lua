XCraftQueue = {}
local moduleName = 'XCraftQueue'

-- Variable definition
local mainFrame
local largeStartButton

local craftQueue = {}
local displayPageNo = 0
local displayPageSize = 10
local displayFrameList = {}
local isCrafting = false

-- Function definition
local initUI
local refreshUI
local start
local addItem

-- Function implemention
initUI = function()
    largeStartButton = XUI.createButton(UIParent, 70, '开始')
    largeStartButton:SetHeight(70)
    largeStartButton:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', -15, 30)
    largeStartButton:SetScript('OnClick', function()
        start()
        refreshUI()
    end)
    largeStartButton:Hide()

    mainFrame = XUI.createFrame('XCraftQueueMainFrame', 265, 430)
    mainFrame.title:SetText('制造队列')
    mainFrame:SetPoint('LEFT', UIParent, 'LEFT', 0, 0)
    mainFrame:Hide()

    local startButton = XUI.createButton(mainFrame, 35, '起')
    startButton:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 15, -30)
    startButton:SetScript('OnClick', function()
        start()
        refreshUI()
    end)
    mainFrame.startButton = startButton

    local preButton = XUI.createButton(mainFrame, 35, '上')
    preButton:SetPoint('LEFT', startButton, 'RIGHT', 5, 0)
    preButton:SetScript('OnClick', function()
        if displayPageNo > 0 then
            displayPageNo = displayPageNo - 1
            refreshUI()
        end
    end)

    local nextButton = XUI.createButton(mainFrame, 35, '下')
    nextButton:SetPoint('LEFT', preButton, 'RIGHT', 5, 0)
    nextButton:SetScript('OnClick', function()
        if displayPageNo < math.ceil(#craftQueue / displayPageSize) - 1 then
            displayPageNo = displayPageNo + 1
            refreshUI()
        end
    end)

    local cleanButton = XUI.createButton(mainFrame, 35, '清')
    cleanButton:SetPoint('LEFT', nextButton, 'RIGHT', 5, 0)
    cleanButton:SetScript('OnClick', function()
        XUIConfirmDialog.show(moduleName, '确认', '是否确认清除制造列表', function()
            craftQueue = {}
            isCrafting = false
            refreshUI()
        end)
    end)

    local refreshButton = XUI.createButton(mainFrame, 35, '刷')
    refreshButton:SetPoint('LEFT', cleanButton, 'RIGHT', 5, 0)
    refreshButton:SetScript('OnClick', function()
        XAutoAuction.refreshUI()
    end)

    local lastWidget = startButton
    for i = 1, displayPageSize do
        local frame = CreateFrame('Frame', nil, mainFrame)
        frame:SetSize(mainFrame:GetWidth(), 30)

        if i == 1 then
            frame:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 0, -65)
        else
            frame:SetPoint('TOPLEFT', lastWidget, 'BOTTOMLEFT', 0, -5)
        end

        frame:Hide()

        local nameLabel = XUI.createLabel(frame, 70, '')
        nameLabel:SetPoint('LEFT', frame, 'LEFT', 15, 0)
        frame.nameLabel = nameLabel

        local countLabel = XUI.createLabel(frame, 60, '')
        countLabel:SetPoint('LEFT', nameLabel, 'RIGHT', 5, 0)
        frame.countLabel = countLabel

        local deleteButton = XUI.createButton(frame, 20, 'D')
        deleteButton:SetPoint('LEFT', countLabel, 'RIGHT', 1, 0)
        deleteButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            if idx <= #craftQueue then
                table.remove(craftQueue, idx)
                refreshUI()
            end
        end)

        local subButton = XUI.createButton(frame, 20, '-')
        subButton:SetPoint('LEFT', deleteButton, 'RIGHT', 1, 0)
        subButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            if idx <= #craftQueue then
                local item = craftQueue[idx]
                if item['count'] <= 1 then
                    table.remove(craftQueue, idx)
                else
                    item['count'] = item['count'] - 1
                end
                refreshUI()
            end
        end)

        local addButton = XUI.createButton(frame, 20, '+')
        addButton:SetPoint('LEFT', subButton, 'RIGHT', 1, 0)
        addButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            if idx <= #craftQueue then
                local item = craftQueue[idx]
                item['count'] = item['count'] + 1
                refreshUI()
            end
        end)

        local priceButton = XUI.createButton(frame, 20, 'E')
        priceButton:SetPoint('LEFT', addButton, 'RIGHT', 1, 0)
        priceButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            if idx <= #craftQueue then
                local item = craftQueue[idx]
                local autoAuctionItem = XAuctionCenter.getAuctionItem(item['itemname'])

                if autoAuctionItem then
                    print(item['itemname'] .. ': ' .. XUtils.priceToMoneyString(autoAuctionItem['minprice']))
                end
            end
        end)

        local auctionButton = XUI.createButton(frame, 20, 'A')
        auctionButton:SetPoint('LEFT', priceButton, 'RIGHT', 1, 0)
        auctionButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            if idx <= #craftQueue then
                XAuctionCenter.addQueryTaskByItemName(craftQueue[idx]['itemname'])
            end
        end)

        table.insert(displayFrameList, frame)
        lastWidget = frame
    end
end

refreshUI = function()
    XInfo.reloadBag()

    mainFrame.title:SetText('制造队列  (' .. #craftQueue .. ')');

    if #craftQueue > 0 then
        largeStartButton:Show()
    else
        largeStartButton:Hide()
    end

    if isCrafting then
        mainFrame.startButton:SetText('停')
        largeStartButton:SetText('停止')
    else
        mainFrame.startButton:SetText('起')
        largeStartButton:SetText('开始')
    end

    for i = 1, displayPageSize do
        local frame = displayFrameList[i]
        local idx = displayPageNo * displayPageSize + i;
        if idx <= #craftQueue then
            local item = craftQueue[idx];

            local materialCountNum = 0
            local materialBagItem = XInfo.getMaterialBagItem(item['itemname'])
            if materialBagItem then
                materialCountNum = materialBagItem['totalcount']
            end
            local materialCount = XUI.getColor_BagCount(materialCountNum) .. XUtils.formatCount(materialCountNum, 2)

            local itemBag = XInfo.getBagItem(item['itemname'])
            local bagTotalCount = 0
            if itemBag then
                bagTotalCount = itemBag['totalcount']
            end

            local auctionItem = XInfo.getAuctionItem(item['itemname'])
            local auctionCount = 0
            if auctionItem then auctionCount = auctionItem['count'] end
            local bagAuctionCount = bagTotalCount + auctionCount

            local name1 = string.sub(item['itemname'], 1, 6)
            local name2 = string.sub(string.sub(item['itemname'], -9), 1, 6)
            frame.nameLabel:SetText(name1 .. name2, 1, 12)
            frame.countLabel:SetText(XUtils.formatCount(item['count'], 1) ..
                XUI.White .. '/' .. bagAuctionCount .. XUI.White .. '/' .. materialCount)
            frame:Show()
        else
            frame:Hide()
        end
    end
end

-- type: add, reset, fulfil
addItem = function(itemName, count, type)
    if count == nil then count = 1 end
    if type == nil then type = 'add' end
    local found = false
    for _, item in ipairs(craftQueue) do
        if item['itemname'] == itemName then
            if type == 'add' then
                item['count'] = item['count'] + count
            elseif type == 'reset' then
                item['count'] = count
            elseif type == 'fulfil' then
                if item['count'] < count then item['count'] = count end
            end
            found = true
            break
        end
    end
    if not found then
        if #craftQueue > 1 then
            local autoAuctionItem = XAuctionCenter.getAuctionItem(itemName)
            if autoAuctionItem then
                if autoAuctionItem['enabled'] and autoAuctionItem['star'] then
                    table.insert(craftQueue, 2, { itemname = itemName, count = count })
                else
                    table.insert(craftQueue, { itemname = itemName, count = count })
                end
            else
                table.insert(craftQueue, { itemname = itemName, count = count })
            end
        else
            table.insert(craftQueue, { itemname = itemName, count = count })
        end
    end
    refreshUI()
end

start = function()
    if #craftQueue <= 0 then
        isCrafting = false
        refreshUI()
        return false
    end

    if not XInfo.reloadTradeSkill() then
        isCrafting = false
        refreshUI()
        return false
    end

    local item = craftQueue[1];

    local tradeSkillItem = XInfo.getTradeSkillItem(item['itemname'])
    if not tradeSkillItem then
        table.remove(craftQueue, 1)
        isCrafting = false
        refreshUI()
        return false
    end

    if not isCrafting then
        isCrafting = true
        refreshUI()
    end
    DoTradeSkill(tradeSkillItem['index'], item['count'])
    return true
end

-- Event callback
local function onSuccess(skillName)
    if not isCrafting then return end
    if #craftQueue <= 0 then return end

    local item = craftQueue[1]
    local tradeSkillItem = XInfo.getTradeSkillItem(item['itemname'])
    if not tradeSkillItem then return end
    if skillName ~= tradeSkillItem['skillname'] then return end

    if item['count'] <= 1 then
        table.remove(craftQueue, 1)
        isCrafting = false
    else
        item['count'] = item['count'] - 1
    end
    refreshUI()
end

local function onFailed(skillName)
    if not isCrafting then return end
    if #craftQueue <= 0 then return end
    table.remove(craftQueue, 1)
    isCrafting = false
    refreshUI()
end

-- Events
XAutoAuction.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initUI()
    refreshUI()
end)

XAutoAuction.registerEventCallback(moduleName, 'UNIT_SPELLCAST_SUCCEEDED', function(self, event, text, context)
    onSuccess(context)
end)

XAutoAuction.registerEventCallback(moduleName, 'UNIT_SPELLCAST_FAILED', function(self, event, text, context)
    onFailed(context)
end)

XAutoAuction.registerEventCallback(moduleName, 'UNIT_SPELLCAST_INTERRUPTED', function(self, event, text, context)
    onFailed(context)
end)

XAutoAuction.registerEventCallback(moduleName, 'AUCTION_HOUSE_SHOW', function(self, event, text, context)
    if mainFrame then mainFrame:Show() end
end)

XAutoAuction.registerEventCallback(moduleName, 'AUCTION_HOUSE_CLOSED', function(self, event, text, context)
    if mainFrame then mainFrame:Hide() end
end)

XAutoAuction.registerRefreshCallback(moduleName, refreshUI);

-- Commands
SlashCmdList['XCRAFTQUEUE'] = function()
    XUI.toggleVisible(mainFrame)
end
SLASH_XCRAFTQUEUE1 = '/xcraftqueue'

SlashCmdList['XCRAFTQUEUESHOW'] = function()
    if mainFrame then mainFrame:Show() end
end
SLASH_XCRAFTQUEUESHOW1 = '/xcraftqueue_show'

SlashCmdList['XCRAFTQUEUECLOSE'] = function()
    if mainFrame then mainFrame:Hide() end
end
SLASH_XCRAFTQUEUECLOSE1 = '/xcraftqueue_close'

SlashCmdList['XCRAFTQUEUESTART'] = function()
    start()
end
SLASH_XCRAFTQUEUESTART1 = '/xcraftqueue_start'

-- Interfaces
XCraftQueue.start = start
XCraftQueue.addItem = addItem
