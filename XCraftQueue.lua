XCraftQueue = {}
local moduleName = 'XCraftQueue'

-- Variable definition
local mainFrame

local dft_smalltime = 5
local dft_largetime = 1.5
local dft_taskInterval = 1
local dft_emptySlotCount = 2
local dft_rubbishList = {
    '致密天蓝石',
    '裂纹森林翡翠'
}

local craftRubbish = false
local craftQueue = {}
local displayPageNo = 0
local displayPageSize = 3
local displayFrameList = {}
local isRunning = false
local curTask = nil
local taskExpires = 0
local lastFailTime = 0
local lastTaskFinishTime = 0

-- Function definition
local initUI
local refreshUI
local addItem
local finishCurTask
local start
local stop
local reset

-- Function implemention
initUI = function()
    mainFrame = XUI.createFrame('XCraftQueueMainFrame', 400, 180)
    mainFrame.title:SetText('制造队列')
    mainFrame:SetPoint('LEFT', UIParent, 'LEFT', 0, 0)
    mainFrame:Hide()
    tinsert(UISpecialFrames, mainFrame:GetName())

    local startButton = XUI.createButton(mainFrame, 35, '起')
    startButton:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 15, -30)
    startButton:SetScript('OnClick', function()
        start()
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

    local craftRubbishButton = XUI.createButton(mainFrame, 35, XUI.Red .. '造')
    craftRubbishButton:SetPoint('LEFT', nextButton, 'RIGHT', 5, 0)
    craftRubbishButton:SetScript('OnClick', function(self)
        craftRubbish = not craftRubbish
        if craftRubbish then
            self:SetText(XUI.Green .. '造')
        else
            self:SetText(XUI.Red .. '造')
        end
        refreshUI()
    end)

    local cleanButton = XUI.createButton(mainFrame, 35, '清')
    cleanButton:SetPoint('LEFT', craftRubbishButton, 'RIGHT', 5, 0)
    cleanButton:SetScript('OnClick', function()
        reset()
        refreshUI()
    end)

    local refreshButton = XUI.createButton(mainFrame, 35, '刷')
    refreshButton:SetPoint('LEFT', cleanButton, 'RIGHT', 5, 0)
    refreshButton:SetScript('OnClick', function()
        XAutoAuction.refreshUI()
    end)

    local rubbishCountLabel = XUI.createLabel(mainFrame, 30)
    rubbishCountLabel:SetPoint('LEFT', refreshButton, 'RIGHT', 10, 0)
    mainFrame.rubbishCountLabel = rubbishCountLabel

    local lastWidget = startButton
    for i = 1, displayPageSize do
        local frame = XAPI.CreateFrame('Frame', nil, mainFrame)
        frame:SetSize(mainFrame:GetWidth(), 30)

        if i == 1 then
            frame:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 0, -65)
        else
            frame:SetPoint('TOPLEFT', lastWidget, 'BOTTOMLEFT', 0, -5)
        end

        frame:Hide()

        local nameFrame = XAPI.CreateFrame('Frame', nil, frame)
        nameFrame:SetSize(70, 30)
        nameFrame:SetPoint('LEFT', frame, 'LEFT', 15, 0)
        nameFrame:SetScript("OnEnter", function(self)
            local idx = displayPageNo * displayPageSize + i
            local item = craftQueue[idx]

            if not item then return end
            local itemid = XInfo.getItemId(item['itemname'])
            if itemid > 0 then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("item:" .. itemid) -- 显示物品信息
            end
        end)
        nameFrame:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        local icon = XUI.createIcon(nameFrame, 25, 25)
        icon:SetPoint('LEFT', nameFrame, 'LEFT', 0, 0)
        frame.icon = icon

        local nameLabel = XUI.createLabel(frame, 40, '')
        nameLabel:SetPoint('LEFT', icon, 'RIGHT', 5, 0)
        frame.nameLabel = nameLabel

        local countLabel = XUI.createLabel(frame, 170, '')
        countLabel:SetPoint('LEFT', nameFrame, 'RIGHT', 5, 0)
        frame.countLabel = countLabel

        local deleteButton = XUI.createButton(frame, 25, 'D')
        deleteButton:SetPoint('LEFT', countLabel, 'RIGHT', 1, 0)
        deleteButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            if idx <= #craftQueue then
                table.remove(craftQueue, idx)
                refreshUI()
            end
        end)

        local subButton = XUI.createButton(frame, 25, '-')
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

        local addButton = XUI.createButton(frame, 25, '+')
        addButton:SetPoint('LEFT', subButton, 'RIGHT', 1, 0)
        addButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            if idx <= #craftQueue then
                local item = craftQueue[idx]
                item['count'] = item['count'] + 1
                refreshUI()
            end
        end)

        local auctionButton = XUI.createButton(frame, 25, 'A')
        auctionButton:SetPoint('LEFT', addButton, 'RIGHT', 1, 0)
        auctionButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            if idx <= #craftQueue then
                XAuctionCenter.addQueryTaskByItemName(craftQueue[idx]['itemname'])
            end
        end)

        local craftButton = XUI.createButton(frame, 25, 'C')
        craftButton:SetPoint('LEFT', auctionButton, 'RIGHT', 1, 0)
        craftButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            if idx <= #craftQueue then
                local item = craftQueue[idx]
                local tradeSkillItem = XInfo.getTradeSkillItem(item['itemname'])
                if not tradeSkillItem then
                    return
                end
                XAPI.DoTradeSkill(tradeSkillItem['index'], item['count'])
            end
        end)

        table.insert(displayFrameList, frame)
        lastWidget = frame
    end
end

refreshUI = function()
    if not mainFrame then return end
    if not mainFrame:IsVisible() then return end

    XInfo.reloadBag()
    XInfo.reloadAuction()

    if curTask then
        mainFrame.title:SetText(curTask['itemname'] .. '/' .. curTask['count'] .. '  (' .. #craftQueue .. ')')
    else
        mainFrame.title:SetText('制造队列  (' .. #craftQueue .. ')');
    end

    if isRunning then
        mainFrame.startButton:SetText('停')
    else
        mainFrame.startButton:SetText('起')
    end

    local rubbishCount = 0
    for _, _itemName in ipairs(dft_rubbishList) do
        rubbishCount = rubbishCount + XInfo.getBagItemCount(_itemName)
    end
    local rubbishCountStr = 'R' .. rubbishCount
    if rubbishCount > 10 then
        rubbishCountStr = XUI.Color_Bad .. rubbishCountStr
    elseif rubbishCount > 5 then
        rubbishCountStr = XUI.Color_Poor .. rubbishCountStr
    elseif rubbishCount > 0 then
        rubbishCountStr = XUI.Color_Fair .. rubbishCountStr
    else
        rubbishCountStr = XUI.Color_Good .. rubbishCountStr
    end
    mainFrame.rubbishCountLabel:SetText(rubbishCountStr)

    for i = 1, displayPageSize do
        local frame = displayFrameList[i]
        local idx = displayPageNo * displayPageSize + i;
        if idx <= #craftQueue then
            local item = craftQueue[idx];

            local materialCountNum = XInfo.getMaterialBagCount(item['itemname'])
            local materialCount = XUI.getColor_MaterialCount(materialCountNum)
                .. 'M' .. materialCountNum

            local itemTotalCount = XInfo.getItemTotalCount(item['itemname'])

            local mailCount = XInfo.getMailItemCount(item['itemname'])
            local mailCountStr = mailCount .. ''
            if mailCount > 0 then
                mailCountStr = XUI.Red .. mailCountStr
            end

            local auctionCount = XInfo.getAuctionItemCount(item['itemname'])

            local name = string.sub(item['itemname'], 1, 6)
            local texture = XAPI.GetItemIcon(XInfo.getItemId(item['itemname']))
            if not texture then texture = XAPI.Texture_QuestionMark end
            frame.icon:SetTexture(texture)
            frame.nameLabel:SetText(name)
            frame.countLabel:SetText(item['count']
                .. XUI.White .. ' / ' .. mailCountStr .. XUI.White .. ' / ' .. 'A' .. auctionCount
                .. ' / ' .. 'T' .. itemTotalCount .. XUI.White .. ' / ' .. materialCount)
            frame:Show()
        else
            frame:Hide()
        end
    end
end

-- type: add, reset, fulfil
addItem = function(itemName, count, type)
    if count == nil then count = 1 end
    count = tonumber(count)
    if type == nil then type = 'add' end
    local found = false
    if curTask ~= nil and curTask['itemname'] == itemName then
        refreshUI()
        return
    end
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
        local index = 0
        local important = XAuctionCenter.checkImportantByName(itemName)
        local deltaPrice = 0
        local tItem = XAuctionCenter.getItem(itemName)
        if tItem then
            local materialName = XInfo.getMaterialName(itemName)
            local materialBuyPrice = XAutoBuy.getItemField(materialName, 'price', 0)
            deltaPrice = tItem['lastpriceother'] - materialBuyPrice
        end

        for idx, item in pairs(craftQueue) do
            if important then
                if (item['important'] and item['deltaprice'] < deltaPrice) or (not item['important']) then
                    index = idx
                    break
                end
            else
                if (not item['important']) and item['deltaprice'] < deltaPrice then
                    index = idx
                    break
                end
            end
        end
        if index == 0 then
            table.insert(craftQueue,
                { itemname = itemName, count = count, deltaprice = deltaPrice, important = important })
        else
            table.insert(craftQueue, index,
                { itemname = itemName, count = count, deltaprice = deltaPrice, important = important })
        end
    end
    refreshUI()
end

finishCurTask = function()
    curTask = nil
    taskExpires = 0
    lastTaskFinishTime = time()
end

start = function()
    if not isRunning then
        if not XInfo.reloadTradeSkill('珠宝加工') then
            refreshUI()
            return
        end
    end
    isRunning = not isRunning
    refreshUI()
end

stop = function()
    isRunning = false
    refreshUI()
end

reset = function()
    isRunning = false
    finishCurTask()
    craftQueue = {}
    refreshUI()
end

-- Event callback
local function onUpdate()
    if not isRunning then return end

    if curTask then
        if time() > taskExpires then
            xdebug.error('XCraftQueue Task Timeout')
            finishCurTask()
            refreshUI()
            return
        else
            local tradeSkillItem = XInfo.getTradeSkillItem(curTask['itemname'])
            if not tradeSkillItem then
                finishCurTask()
                refreshUI()
                return
            end

            XAPI.DoTradeSkill(tradeSkillItem['index'], curTask['count'])
        end
        return
    end

    if time() < lastTaskFinishTime + dft_taskInterval then return end

    XInfo.reloadBag()
    if XInfo.emptyBagCount <= 0 then
        refreshUI()
        return
    end

    if #craftQueue <= 0 then
        if craftRubbish and XInfo.emptyBagCount > dft_emptySlotCount then
            local found = false
            for _, _itemName in ipairs(dft_rubbishList) do
                if XInfo.getMaterialBagCount(_itemName) > 20 then
                    addItem(_itemName)
                    found = true
                    break
                end
            end
            if not found then
                refreshUI()
                return
            end
        else
            refreshUI()
            return
        end
    end

    curTask = craftQueue[1];
    table.remove(craftQueue, 1)

    local materialName = XInfo.getMaterialName(curTask['itemname'])
    local materialCount = XInfo.getBagItemCount(materialName)
    local count = curTask['count']
    if count > materialCount then
        count = materialCount
    end
    if count <= 0 then
        finishCurTask()
        refreshUI()
        return
    end

    taskExpires = time() + dft_smalltime * count + 2
    if XUtils.inArray(materialName, XInfo.materialListB) then
        taskExpires = time() + dft_largetime * count + 2
    end

    local tradeSkillItem = XInfo.getTradeSkillItem(curTask['itemname'])
    if not tradeSkillItem then
        finishCurTask()
        refreshUI()
        return
    end

    XAPI.DoTradeSkill(tradeSkillItem['index'], count)
end

local function onStart(...)
    if not curTask then return end
    local unit, castId = select(3, ...)
    if unit ~= 'player' then return end

    curTask['castid'] = castId
    XAutoAuction.refreshUI()
end

local function onSuccess(...)
    if not curTask then return end
    local unit, castId = select(3, ...)
    if unit ~= 'player' then return end
    if curTask['castid'] ~= castId then return end

    XAuctionBoard.addItem(curTask['itemname'], 'craft')
    if curTask['count'] <= 1 then
        local item = XAuctionCenter.getItem(curTask['itemname'])
        if item then
            if #item['myvalidlist'] < item['stackcount'] then
                XAuctionCenter.addQueryTaskByItemName(curTask['itemname'])
            end
        end
        finishCurTask()
    else
        curTask['count'] = curTask['count'] - 1
    end

    XAutoAuction.refreshUI()
end

local function onFailed(...)
    if not curTask then return end
    if time() - lastFailTime < 1 then return end
    local unit, castId = select(3, ...)
    if unit ~= 'player' then return end
    if curTask['castid'] ~= castId then return end

    lastFailTime = time()
    finishCurTask()
    XAutoAuction.refreshUI()
end

-- Events
XAutoAuction.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initUI()
    refreshUI()
end)

XAutoAuction.registerUpdateCallback(moduleName, onUpdate)

XAutoAuction.registerEventCallback(moduleName, 'UNIT_SPELLCAST_START', onStart)

XAutoAuction.registerEventCallback(moduleName, 'UNIT_SPELLCAST_SUCCEEDED', onSuccess)

XAutoAuction.registerEventCallback(moduleName, 'UNIT_SPELLCAST_FAILED', onFailed)

XAutoAuction.registerEventCallback(moduleName, 'UNIT_SPELLCAST_INTERRUPTED', onFailed)

-- XAutoAuction.registerEventCallback(moduleName, 'AUCTION_HOUSE_SHOW', function(self, event, text, context)
--     if mainFrame then mainFrame:Show() end
-- end)

XAutoAuction.registerEventCallback(moduleName, 'AUCTION_HOUSE_CLOSED', function()
    if mainFrame then mainFrame:Hide() end
end)

XAutoAuction.registerRefreshCallback(moduleName, refreshUI)

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
    isRunning = true
    refreshUI()
end
SLASH_XCRAFTQUEUESTART1 = '/xcraftqueue_start'

SlashCmdList['XCRAFTQUEUESTOP'] = function()
    isRunning = false
    refreshUI()
end
SLASH_XCRAFTQUEUESTOP1 = '/xcraftqueue_stop'

-- Interfaces
XCraftQueue.addItem = addItem
XCraftQueue.start = start
XCraftQueue.stop = stop
XCraftQueue.reset = reset
XCraftQueue.isRunning = function()
    return isRunning
end

XCraftQueue.toggle = function() XUI.toggleVisible(mainFrame) end
XCraftQueue.getItemCount = function()
    return #craftQueue
end
